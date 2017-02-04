function Edge 
{
    <#
        .Description
        This defines an edge between two or more nodes

        .Example
        Graph g {
            Edge FirstNode SecondNode
        }

        Generates this graph syntax:

        digraph g {
            "FirstNode"->"SecondNode" 
        }
        
        .Example
        $folder = Get-ChildItem -Recurse -Directory
        graph g {
            $folder | %{ edge $_.parent $_.name }
        }

        # with parameter names specified
        graph g {
            $folder | %{ edge -From $_.parent -To $_.name }
        } 

        # with scripted properties
        graph g {
            edge $folder -FromScript {$_.parent} -ToScript {$_.name}
        } 

        .Example
        $folder = Get-ChildItem -Recurse -Directory
        

        .Example
        graph g {
            edge (1..3) (5..7)
            edge top bottom @{label="line label"}
            edge (10..13)
            edge one,two,three,four
        }

        .Notes
        If an array is specified for the From property, but not for the To property, then the From list will be procesed in order and will map the array in a chain.

    #>
    [cmdletbinding(DefaultParameterSetName='Node')]
    param(
        # start node or source of edge
        [Parameter(
            Mandatory = $true, 
            Position = 0,
            ParameterSetName='Node'
        )]
        [alias('NodeName','Name','SourceName','LeftHandSide','lhs')]
        [string[]]
        $From,

        # Destination node or target of edge
        [Parameter(
            Mandatory = $false, 
            Position = 1,
            ParameterSetName='Node'
        )]
        [alias('Destination','TargetName','RightHandSide','rhs')]
        [string[]]
        $To,

        # Hashtable that gets translated to an edge modifier
        [Parameter(
            Position = 2,
            ParameterSetName='Node'
        )]
        [Parameter(
            Position = 1,
            ParameterSetName='script'
        )]
        [hashtable]
        $Attributes,

         # a list of nodes to process
        [Parameter(
            Mandatory = $true, 
            Position = 0,
            ValueFromPipeline = $true,
            ParameterSetName='script'
        )]
        [Alias('InputObject')]
        [Object[]]
        $Node,

        # start node script or source of edge
        [Parameter(ParameterSetName='script')]
        [alias('FromScriptBlock','SourceScript')]
        [scriptblock]
        $FromScript = {$_},

        # Destination node script or target of edge
        [Parameter(ParameterSetName='script')]
        [alias('ToScriptBlock','TargetScript')]
        [scriptblock]
        $ToScript = {$null},

        # A string for using native attribute syntax
        [string]
        $LiteralAttribute = $null
    )

    begin
    {
        if( -Not [string]::IsNullOrEmpty($LiteralAttribute))
        {
            $GraphVizAttribute = $LiteralAttribute
        }
    }

    process 
    {
        if($Node -ne $null)
        { # Used when scripted properties are specified
            foreach($item in $Node)
            {            
                $fromValue = (@($item).ForEach($FromScript))
                $toValue = (@($item).ForEach($ToScript))
                $LiteralAttribute = ConvertTo-GraphVizAttribute -Attributes $Attributes -InputObject $item

                edge -From $fromValue -To $toValue -LiteralAttribute $LiteralAttribute
            }
        } 
        else
        {
            if ($Attributes -ne $null -and [string]::IsNullOrEmpty($LiteralAttribute))
            {
                $GraphVizAttribute = ConvertTo-GraphVizAttribute -Attributes $Attributes
            }        
        
            $format = [ordered]@{
                Indent = (Get-Indent)
                From = ''
                To = ''
                Attributes = $GraphVizAttribute
            }

            if ($To -ne $null)
            { # If we have a target array, cross multiply results
                foreach($sNode in $From)
                {                    
                    foreach($tNode in $To)
                    {                        
                        $format.from = (Format-Value $sNode -Edge)
                        $format.to = (Format-Value $tNode -Edge)
                            
                        Write-Output ('{0}{1}->{2} {3}' -f $format.values)
                    }
                }
            }
            else
            { # If we have a single array, connect them sequentially. 
                for($index=0; $index -lt ($From.Count - 1); $index++)
                {
                    $output = @(
                        (Get-Indent)
                        (Format-Value $From[$index] -Edge)
                        (Format-Value $From[$index + 1] -Edge)
                        $GraphVizAttribute
                    )
                    $format.from = (Format-Value $From[$index] -Edge)
                    $format.to = (Format-Value $From[$index + 1] -Edge)
                        
                    Write-Output ('{0}{1}->{2} {3}' -f $format.values)
                }
            }
        }
    }
}

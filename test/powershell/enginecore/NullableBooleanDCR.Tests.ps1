Describe "Nullable Boolean DCR Tests" -Tags "CI" {
    BeforeAll { 
        function ParserTestFunction
        {
            param([bool]$First) $First
        }

        function parsertest-bool2
        {
            [CmdletBinding()]
            param (
            [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)] [bool]$First = $false
            )

            Process {
                return $First
            }
        }

        $scriptName = Join-Path $TestDrive -ChildPath "ParserTestScript.ps1"

        'param([bool]$First) $First' > $scriptName

        $scripts = "parsertest-bool2", "$scriptName", "ParserTestFunction"
    }
    
    It "Test that a boolean parameter accepts positional values" {
        foreach ($cmd in $scripts)
        {
            $result1 = & $cmd $true
            $result2 = & $cmd 1
            $result3 = & $cmd 1.28
            $result4 = & $cmd (-2.32) 
            $result1 | Should Be $true
            $result2 | Should Be $true
            $result3 | Should Be $true
            $result4 | Should Be $true

            $result5 = & $cmd $false
            $result6 = & $cmd 0
            $result7 = & $cmd 0.00
            $result8 = & $cmd (1 - 1)

            $result5 | Should Be $false
            $result6 | Should Be $false
            $result7 | Should Be $false
            $result8 | Should Be $false
        }
    }

    It "Test that a boolean parameter accepts values specified with a colon" {
        foreach ($cmd in $scripts)
        {
            $result1 = & $cmd -First:$true
            $result2 = & $cmd -First:1
            $result3 = & $cmd -First:1.28
            $result4 = & $cmd -First:(-2.32) 
            $result1 | Should Be $true
            $result2 | Should Be $true
            $result3 | Should Be $true
            $result4 | Should Be $true

            $result5 = & $cmd -First:$false
            $result6 = & $cmd -First:0
            $result7 = & $cmd -First:0.00
            $result8 = & $cmd -First:(1 - 1)

            $result5 | Should Be $false
            $result6 | Should Be $false
            $result7 | Should Be $false
            $result8 | Should Be $false
        }   
    }

    It "Test that the boolean parameter works properly" {
        foreach ($cmd in $scripts)
        {
            $result1 = & $cmd -First $true
            $result2 = & $cmd -First 1
            $result3 = & $cmd -First 1.28
            $result4 = & $cmd -First (-2.32) 
            $result1 | Should Be $true
            $result2 | Should Be $true
            $result3 | Should Be $true
            $result4 | Should Be $true

            $result5 = & $cmd -First $false
            $result6 = & $cmd -First 0
            $result7 = & $cmd -First 0.00
            $result8 = & $cmd -First (1 - 1)

            $result5 | Should Be $false
            $result6 | Should Be $false
            $result7 | Should Be $false
            $result8 | Should Be $false
        }  
    }
}

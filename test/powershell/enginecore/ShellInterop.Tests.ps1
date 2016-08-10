Describe "ShellInterop Tests" -tags "CI" {
    BeforeAll {
        
    }
	BeforeEach {
	}
	AfterEach {
	    $Error.Clear()
	}
	
    It "Verify Parsing Error Output Format Single Shell should throw exception" {
        try 
        {
	        if($IsLinux -Or $IsOSX)
			{
                powershell -outp blah -comm { $input }
			}
			else
			{
			    powershell.exe -outp blah -comm { $input }
			}
            Throw "Execution OK"
        }
        catch
        {
            $_.FullyQualifiedErrorId | Should Be "IncorrectValueForFormatParameter"
        }
	}
    
    It "Verify Simple Interop Scenario Child Single Shell" {
	    $a = 1,2,3
		if($IsLinux -Or $IsOSX)
		{
            $b = $a | powershell  -noprofile -command { $input }
		}
		else
		{
			$b = $a | powershell.exe  -noprofile -command { $input }
		}
        $val  = $b
        $val.Count | Should Be 3
		$val[0] | Should Be 1
		$val[1] | Should Be 2
		$val[2] | Should Be 3
    }
	
	It "Verify Validate Dollar Error Populated should throw exception" {
	    $ErrorActionPreference = "Stop"
        try 
        {
		    $a = 1,2,3
	        if($IsLinux -Or $IsOSX)
			{
                $a | powershell -noprofile -command { wgwg-wrwrhqwrhrh35h3h3}
			}
			else
			{
			    $a | powershell.exe -noprofile -command { wgwg-wrwrhqwrhrh35h3h3}
			}
            Throw "Execution OK"
        }
        catch
        {
		    $_.ToString() | Should Match "wgwg-wrwrhqwrhrh35h3h3"
            $_.FullyQualifiedErrorId | Should Be "CommandNotFoundException"
        }
		$ErrorActionPreference = "SilentlyContinue"
	}
	
	It "Verify Validate Output Format As Text Explicitly Child Single Shell should works" {
        {
		    $a="blahblah"
	        if($IsLinux -Or $IsOSX)
			{
                $a | powershell -noprofile -out text -com { $input }
			}
			else
			{
			    $a | powershell.exe -noprofile -out text -com { $input }
			}
        } | Should Not Throw
	}
}

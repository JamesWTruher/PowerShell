function new-symboliclink
{
    param ( $target, $path )
    new-item -target "${TESTDRIVE}/$targetFile" -path "${TestDrive}/${symLinkName}" -ItemType SymbolicLink -Force
}
if ( $IsWindows )
{
    $linkmode = "-----l"
}
else
{
    $linkmode = "-----l"
}
Describe "New-Item works correctly" -Tags DRT {
    BeforeAll {
        $targetFile = "targetfile"
        $targetDirectory = 'TargetDirectory'
        $targetSubFile = "${targetDirectory}/TargetSubFile.txt"
        $targetJunction = "${targetDirecory}/TargetJunction"
        $targetfileForHardLink = "targetFileForHardLink.txt" 
        Setup -file -path $targetFile -Content "SymbolicLink Test Data"
        Setup -Dir -Path $targetDirectory
        Setup -file -path $targetSubFile -Content "TargetSubFile Data"
        Setup -Dir -path $targetJunction
        Setup -File -Path $targetfileForHardLink "Hardlink test data"
    }
    Context "Create a symbolic link correctly using '-path'" {
        BeforeAll {
            $symLinkName = "SymbolicLink.txt"
            $symbolicLink = new-symboliclink -target "${TESTDRIVE}/$targetFile" -path "${TestDrive}/${symLinkName}"
            }
        AfterAll {
            Remove-Item -Force (join-path $TESTDRIVE $symlinkname)
        }
        It "The symlink should be create" {
            "${TESTDRIVE}/${symLinkName}" | should exist
        }
        It "The symlink should be the correct type" {
            $symbolicLink.LinkType | Should be "SymbolicLink"
        }
        It "The Target should point to the correct file" {
            $symbolicLink.Target | Should be (join-path ${TestDRIVE} $targetfile)
        }
        It "The mode should be represented correctly" {
            $symbolicLink.Mode | should be $linkmode
        }
    }
    Context "Create a symbolic link correctly using '-name'" {
        BeforeAll {
            $symLinkName = "SymbolicLink.txt"
            $symbolicLink = New-Item -ItemType SymbolicLink -Target "${TESTDRIVE}/$targetFile" -path "${TestDrive}" -name ${symLinkName} -Force
            }
        AfterAll {
            Remove-Item -Force (join-path $TESTDRIVE $symlinkname)
        }
        It "The symlink should be create" {
            "${TESTDRIVE}/${symLinkName}" | should exist
        }
        It "The symlink should be the correct type" {
            $symbolicLink.LinkType | Should be "SymbolicLink"
        }
        It "The Target should point to the correct file" {
            $symbolicLink.Target | Should be (join-path ${TestDRIVE} $targetfile)
        }
        It "The mode should be represented correctly" {
            $symbolicLink.Mode | should be $linkmode
        }
    }

    Context "Create a hard link correctly" {
        BeforeAll {
            $hardLinkName = "Hardlink.txt"
            $hardLink = New-Item -ItemType HardLink -Target "${TESTDRIVE}/$targetFile" -path "${TestDrive}" -name ${hardLinkName} -Force
            }
        AfterAll {
            Remove-Item -Force (join-path $TESTDRIVE $hardlinkname)
        }
        It "The hardlink should exist" {
            "${TESTDRIVE}/${hardLinkName}" | should exist
        }
        It "The hardlink should be the correct type" {
            $hardLink.LinkType | Should be "Hardlink"
        }
        It "The Target should point to the correct file" {
            $hardLink.Target | Should be (join-path ${TestDRIVE} $targetfile)
        }
        It "The mode should be represented correctly" {
            # hmmm, the lite tests indicate that the link should look like "-a----"
            $hardLink.Mode | should be $linkmode
        }
    }

    Context "Create a junction correctly" {
        BeforeAll {
            $junctionName = "Junction"
            $junction = New-Item -ItemType Junction -Path (Join-Path $TESTDRIVE $junctionName) -Target (Join-Path ${TESTDRIVE} $targetJunction) -Force
            }
        AfterAll {
            Remove-Item -Force (join-path $TESTDRIVE $junctionName)
        }
        It "The junction should exist" {
            "${TESTDRIVE}/${JunctionName}" | should exist
        }
        It "The junction should be the correct type" {
            $junction.LinkType | Should be "Junction"
        }
        It "The Target should point to the correct file" {
            $junction.Target | Should be (join-path ${TestDRIVE} $targetJunction)
        }
        It "The mode should be represented correctly" {
            $junction.Mode | should be "d----l"
        }
    }
}

Describe "Miscellaneous New-Item tests" -Tags P1 {
    BeforeAll {
        $targetFile = "targetfile"
        $targetDirectory = 'TargetDirectory'
        $targetSubFile = "${targetDirectory}/TargetSubFile.txt"
        $targetJunction = "${targetDirecory}/TargetJunction"
        $targetfileForHardLink = "targetFileForHardLink.txt" 
        Setup -file -path $targetFile -Content "SymbolicLink Test Data"
        Setup -Dir -Path $targetDirectory
        Setup -file -path $targetSubFile -Content "TargetSubFile Data"
        Setup -Dir -path $targetJunction
        Setup -File -Path $targetfileForHardLink "Hardlink test data"
    }
    It "Creating a file without ItemType being specified results in a file" {
        $filePath = join-path ${TESTDRIVE} "foo.txt"
        $file = New-Item -Path $filePath -Force
        $filepath | Should Exist
        Test-Path $filepath -pathtype Leaf | Should be $true
    }
    It "moving a symbolic link does not alter its contents" {
        $symLink = join-path $TestDrive "SymbolicLink.txt"
        $movedLink = join-path $TestDrive "SymbolicLinkMoved.txt"
        $targetPath = join-path $TESTDRIVE $targetFile
        $symbolicFile = New-Item -Path $symLink -Target $targetpath -Force -ItemType SymbolicLink
        $symbolicFile | Should Not BeNullOrEmpty

        ##Move the symbolic link and rename it.
        Move-Item $symbolicFile $movedLink -Force

        $targetContent = Get-Content $targetpath
        $movedLinkContent = Get-Content $movedLink
        
        ([string]$targetContent) |should be ([string]$movedLinkContent)
    }

    It "The last element in a chain of symbolic links has the same content as the first" {
        $secondSymFilePath = join-path $TESTDRIVE "SymbolicLink2.txt"
        $targetPath = join-path $TESTDRIVE $targetfile
        $path = join-path $TESTDRIVE "SymbolicLink.txt"
            
        $symbolicFile = New-Item -Path $path -Target $targetPath -Force -ItemType SymbolicLink
        $symbolicFile | Should Not BeNullOrEmpty

        $secondSymFile = New-Item -Path $secondSymFilePath -Target $symbolicFile -Force -ItemType SymbolicLink
        $secondSymFile | Should not BeNullOrEmpty

        [string]$targetContent = Get-Content $targetPath
        [string]$secondSymFileContent = Get-Content $secondSymFile
        $targetContent |Should Be $secondSymFileContent
    }

    Context "Relative Path Symbolic Link Creation" {
        BeforeAll { Push-Location ${TESTDRIVE} }
        AfterAll { Pop-Location }
        It "A symbolic link created with a relative path is correct" {
            Setup -File -Path RelativePath.txt -Content "Relative Path Data"
            $origin = Get-Item RelativePath.txt
            $Link = New-Item -ItemType SymbolicLink -Target RelativePath.txt -Path RelativeLink.txt
            $myLink = Get-Item RelativeLink.txt
            $Link | Should Not BeNullOrEmpty
            $myLink.Target | should be $origin.FullName
        }
    }

}

function initialize-GeneratedValuesForParameters
{
    $returnObject = @() 

    $targetValues = @("", $null, (Join-Path TESTDRIVE "targetfile"), "C:\NonExistentFile.txt", "HKLM:\Software")
    $pathValues = @("", $null, (Join-Path TESTDRIVE "ValidDestination.txt"), "Env:\APPDATA")
    $itemTypes = @("SymbolicLink", "Junction", "HardLink")



    foreach($target in $targetValues)
    {
        foreach($path in $pathValues)
        {
            foreach($type in $itemTypes)
            {
                if($path -eq $null)
                {
                    $returnObject += @{ Path = $path ; 
                        Target = $target;
                        ItemType = $type;
                        ExpectedError = "ParameterArgumentValidationErrorNullNotAllowed,Microsoft.PowerShell.Commands.NewItemCommand" }
                }
                elseif(($path -eq ""))
                {
                    $returnObject += @{ Path = $path ; 
                        Target = $target;
                        ItemType = $type;
                        ExpectedError = "ParameterArgumentValidationErrorEmptyStringNotAllowed,Microsoft.PowerShell.Commands.NewItemCommand" }
                }
                elseif($target -eq $null)
                {
                    $returnObject += @{ Path = $path ; 
                        Target = $target;
                        ItemType = $type;
                        ExpectedError = "ArgumentNull,Microsoft.PowerShell.Commands.NewItemCommand" }
                }
                elseif(($target -eq ""))
                {
                    $returnObject += @{ Path = $path ; 
                        Target = $target;
                        ItemType = $type;
                        ExpectedError = "ArgumentNull,Microsoft.PowerShell.Commands.NewItemCommand" }
                }
                elseif(($path -eq "C:\NonExistentFile.txt") -and ($Target -eq $(Join-Path $global:testDestinationRoot "ValidDestination.txt")))
                {
                    $returnObject += @{ Path = $path ; 
                        Target = $target; 
                        ItemType = $type;
                        ExpectedError = "System.IO.FileNotFoundException,Microsoft.PowerShell.Commands.NewItemCommand" }
                }
                elseif($target -eq "HKLM:\Software")
                {
                    $returnObject += @{ Path = $path ; 
                        Target = $target; 
                        ItemType = $type;
                        ExpectedError = "NotSupported,Microsoft.PowerShell.Commands.NewItemCommand" }
                }
            }
        }
    }
    $returnObject 
}


Describe "Parameter tests against bad parameters" {
    BeforeAll {
        $testCases = initialize-GeneratedValuesForParameters
    }
    it "Test parameter variation - error should be <ExpectedError>" -TestCases $testCases {
        param ( $ItemType, $path, $Target, $ExpectedError )
        try {
            new-item -ItemType $ItemType -path $path -target $Target -ea Stop
            throw "OK"
        }
        catch {
            $_.fullyqualifiederrorid | Should be $ExpectedError
        }
    }
}
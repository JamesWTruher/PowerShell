<##################################################################################### 
 # File: ModuleVersioningTests.ps1
 # Tests for PowerShell Module multi version support
 #
 # Copyright (c) Microsoft Corporation, 2014
 #####################################################################################>
 
<# 
   Name: PowerShell.Engine.Modules.ModuleVersioningTests
   Description: Tests for Module multi version support
#>
Suite @args -Name PowerShell.Engine.Modules.ModuleVersioningTests -definition {

    Include -fileName Asserts.psm1
    Include -fileName ModuleVersioningUtils.psm1

    SuiteSetup {
        $script:ProgramFilesModulesPath = Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell\Modules"
        $script:MyDocumentsModulesPath = Join-Path -Path ([Environment]::GetFolderPath("MyDocuments")) -ChildPath "WindowsPowerShell\Modules"
        
        $script:ModuleNamePrefix="TestModVer_$(Get-Random)_"
        $script:TestModule1 = "$script:ModuleNamePrefix" +"1"
        $script:TestModule2 = "$script:ModuleNamePrefix" +"2"
        $script:TestModule3 = "$script:ModuleNamePrefix" +"3"
        $script:TestModule4 = "$script:ModuleNamePrefix" +"4"
        $script:TestModule5 = "$script:ModuleNamePrefix" +"5"

        # Create and Install test modules
        Install-MultiVersionedModule -ModuleName $script:TestModule1 -Versions "1.0","2.0","3.0","4.0","5.0"
        Install-MultiVersionedModule -ModuleName $script:TestModule2 -Versions "1.0","2.0","10.0","20.0","20.2" -ModulePath $script:MyDocumentsModulesPath
        Install-MultiVersionedModule -ModuleName $script:TestModule3 -Versions "4.0","5.0"
        Install-MultiVersionedModule -ModuleName $script:TestModule4 -Versions "4.0","5.0" -ModulePath $script:MyDocumentsModulesPath

        $script:TestModule5_Guid = [Guid]::NewGuid()
        Install-MultiVersionedModule -ModuleName $script:TestModule5 -ModuleGuid $script:TestModule5_Guid -Versions "1.0","2.0","3.0","4.0","5.0" -InvalidVersions "6.0","7.0"
    }

    SuiteCleanup {
        Get-Module "$script:ModuleNamePrefix*" | Remove-Module -Force
        Uninstall-Module -Name $script:TestModule1,$script:TestModule2,$script:TestModule3,$script:TestModule4,$script:TestModule5
        RemoveItem "$script:ProgramFilesModulesPath\$script:ModuleNamePrefix*"
        RemoveItem "$script:MyDocumentsModulesPath\$script:ModuleNamePrefix*"
        RemoveItem "$script:ProgramFilesModulesPath\Exported_*"
        RemoveItem "$script:MyDocumentsModulesPath\Exported_*"
        Unregister-PSSessionConfiguration -Name $script:ModuleNamePrefix* -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    }

    TestCaseCleanup {
        Get-Module $script:TestModule1 | Remove-Module -Force
        Get-Module $script:TestModule5 | Remove-Module -Force
        Get-Module "$script:ModuleNamePrefix*" | Remove-Module -Force
    }

    # Purpose: Test the FullyQualifiedName parameter of Get-Module with a module with the RequiredVersion filter
    #
    # Action: Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;requiredversion=$version}
    #   
    # Expected Result: should list the module "$script:TestModule5" with version "$version"
    #   
    TestCase GetModuleWithRequiredVersionInFullyQualifiedName -tags @("BVT") {
        $version = "2.0"
        $res = Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;requiredversion=$version}
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version $version "Version is not as expected"
    }

    # Purpose: Test the Get-Module functionality with RequiredVersion and Guid filters in FullyQualifiedName parameter
    #
    # Action: Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;requiredversion=$version;Guid=$script:TestModule5_Guid}
    #   
    # Expected Result: should list the $script:TestModule5 module with version $version
    #   
    TestCase GetModuleWithRequiredVersionAndGuidInFQN -tags @("BVT") {
        $version = "2.0"
        $res = Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;requiredversion=$version;Guid=$script:TestModule5_Guid}
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version $version "Version is not as expected"
        AssertEquals $res.Guid $script:TestModule5_Guid "Guid is not expected"
    }

    # Purpose: Test the Get-Module functionality with RequiredVersion in FullyQualifiedName
    #
    # Action: Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;requiredversion=$version}
    #   
    # Expected Result: should list the $script:TestModule5 module with version $version
    #   
    TestCase GetModuleWithRequiredVersionInFullyQualifiedName2 -tags @("P1") {
        $version = "4.0"
        $res = Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$version}
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version $version "Version is not as expected"
    }

    # Purpose: Test the Get-Module functionality with different version as RequiredVersion in FullyQualifiedName
    #
    # Action: Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;requiredversion=$version}
    #   
    # Expected Result: should list the $script:TestModule5 module with version $version
    #   
    TestCase GetModuleWithRequiredVersionInFullyQualifiedName3 -tags @("P1") {
        $version = "5.0"
        $res = Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;requiredversion=$version}
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version $version "Version is not as expected"
    }

    # Purpose: Test the Get-Module functionality with non-available version as RequiredVersion in FullyQualifiedName
    #
    # Action: Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;requiredversion="5.0.0.2"}
    #   
    # Expected Result: should not return any
    #   
    TestCase GetModuleWithNonAvailableRequiredVersionInFullyQualifiedName -tags @("P1") {
        $version = "5.0.0.2"
        $res = Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;requiredversion=$version}
        AssertEquals $null $res "Get-Module -List should not return any results when not available version is specified as the RequiredVersion filter, $res"
    }

    # Purpose: Test the Get-Module functionality with multi-versioned module name
    #
    # Action: get-module -ListAvailable $script:TestModule5
    #   
    # Expected Result: should return 5 valid versions of $script:TestModule5
    #  
    TestCase GetModuleListAvailableShouldListAllValidVersions -tags @("BVT") {
        $res = Get-Module -ListAvailable $script:TestModule5
        AssertEquals $res.Count 5 "Get-Module -List should return 5 valid versions of $script:TestModule5, $res"
    }

    # Purpose: Test the Get-Module functionality with WildCard in multi-versioned module name
    #
    # Action: get-module -ListAvailable "$script:ModuleNamePrefix*"
    #   
    # Expected Result: Get-Module -List should return valid versions of $script:ModuleNamePrefix* modules
    #  
    TestCase GetModuleListAvailableWithWildCard -tags @("BVT") {
        # In SuiteSetup, 5 modules with "$script:ModuleNamePrefix" and different versions are installed, whose total count it 19.
        $res = get-module -ListAvailable "$script:ModuleNamePrefix*"
        AssertEquals $res.Count 19 "Get-Module -List should return valid versions of $script:ModuleNamePrefix* modules, $res"
    }

    # Purpose: Test the Get-Module functionality with ModuleVersion filter in FullyQualifiedName
    #
    # Action: Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;ModuleVersion=$version}
    #   
    # Expected Result: should return all valid versions greater/equal to the specified version
    #  
    TestCase GetModuleListFQNWithModuleVersion -tags @("BVT") {
        $version = "1.0"
        $res = Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;ModuleVersion=$version}
        AssertEquals $res.Count 5 "Get-Module -List with ModuleVersion in FQN should return 5 valid versions of $script:TestModule5, $res"
    }

    # Purpose: Test the Get-Module functionality with MaximumVersion filter in FullyQualifiedName
    #
    # Action: Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;MaximumVersion=$version}
    #   
    # Expected Result: should return all valid versions smaller/equal to the specified version
    #  
    TestCase GetModuleListFQNWithMaximumVersion -tags @("BVT") {
        $version = "8.0"
        $res = Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;MaximumVersion=$version}
        AssertEquals $res.Count 5 "Get-Module -List with MaximumVersion in FQN should return 5 valid versions of $script:TestModule5, $res"
    }

    # Purpose: Test the Get-Module functionality with MaximumVersion star filter in FullyQualifiedName
    #
    # Action: Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;MaximumVersion=$version}
    #   
    # Expected Result: should return all valid versions smaller/equal to the specified version
    #  
    TestCase GetModuleListFQNWithMaximumVersionAndStar -tags @("BVT") {
        $version = "3.*"
        $res = Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;MaximumVersion=$version}
        AssertEquals $res.Count 3 "Get-Module -List with MaximumVersion in FQN should return 3 valid versions of $script:TestModule5, $res"
    }

    # Purpose: Test the Get-Module functionality with both ModuleVersion and MaximumVersion filter in FullyQualifiedName
    #
    # Action: Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;MaximumVersion=$maxVersion; ModuleVersion=$minVersion}
    #   
    # Expected Result: should return all valid versions smaller/equal to the specified version
    #  
    TestCase GetModuleListFQNWithMaximumVersionAndModuleVersion -tags @("BVT") {
        $maxVersion = "8.0"
        $minVersion = "2.0"
        $res = Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;MaximumVersion=$maxVersion; ModuleVersion=$minVersion}
        AssertEquals $res.Count 4 "Get-Module -List with MaximumVersion in FQN should return 4 valid versions of $script:TestModule5, $res"
    }

    # Purpose: Test the Get-Module functionality with different version as ModuleVersion filter in FullyQualifiedName
    #
    # Action: Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;ModuleVersion=$version}
    #   
    # Expected Result: should return all valid versions greater/equal to the specified version
    #  
    TestCase GetModuleListFQNWithModuleVersion2 -tags @("BVT") {
        $version = "5.0"
        $res = Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;ModuleVersion=$version}
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version $version "Version is not as expected"
    }

    # Purpose: Test the Get-Module functionality with different version as MaximumVersion filter in FullyQualifiedName
    #
    # Action: Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;ModuleVersion=$version}
    #   
    # Expected Result: should return all valid versions lesser/equal to the specified version
    #  
    TestCase GetModuleListFQNWithMaximumVersion2 -tags @("BVT") {
        $version = "1.0"
        $res = Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;MaximumVersion=$version}
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version $version "Version is not as expected"
    }


    # Purpose: Test the Get-Module functionality with different version as ModuleVersion filter in FullyQualifiedName
    #
    # Action: Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;ModuleVersion=$version}
    #   
    # Expected Result: should return all valid versions greater/equal to the specified version
    #  
    TestCase GetModuleListFQNWithModuleVersion3 -tags @("P1") {
        $version = "3.0"
        $res = Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;ModuleVersion=$version}
        AssertEquals $res.Count 3 "Get-Module -List with ModuleVersion in FQN should return valid version of $script:TestModule5, $res"
    }


    # Purpose: Test the Get-Module functionality with MaximumVersion and Guid filters in FullyQualifiedName
    #
    # Action: Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;MaximumVersion="7.0";Guid=$script:TestModule5_Guid}
    #   
    # Expected Result: should return all valid versions lesser/equal to the specified version
    #   
    TestCase GetModuleWithMaximumVersionAndGuidInFQN -tags @("BVT") {
        $version = "3.0"
        $res = Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;MaximumVersion=$version;Guid=$script:TestModule5_Guid}
        AssertEquals $res.Count 3 "Get-Module -List with MaximumVersion in FQN should return 3 valid versions of $script:TestModule5, $res"
    }

    # Purpose: Test the Get-Module functionality with ModuleVersion and Guid filters in FullyQualifiedName
    #
    # Action: Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;ModuleVersion="1.0";Guid=$script:TestModule5_Guid}
    #   
    # Expected Result: should return all valid versions greater/equal to the specified version
    #   
    TestCase GetModuleWithModuleVersionAndGuidInFQN -tags @("BVT") {
        $version = "1.0"
        $res = Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;ModuleVersion=$version;Guid=$script:TestModule5_Guid}
        AssertEquals $res.Count 5 "Get-Module -List with ModuleVersion in FQN should return 5 valid versions of $script:TestModule5, $res"
    }

    # Purpose: Test the Get-Module functionality with multiple ModuleSpecifications to FullyQualifiedName
    #
    # Action: Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion="1.0";},@{ModuleName=$script:TestModule1;RequiredVersion="1.0";}
    #   
    # Expected Result: should return two modules
    #   
    TestCase GetModuleWithMultiValuesInFQN -tags @("BVT") {
        $version = "1.0"
        $res = Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$version;},@{ModuleName=$script:TestModule1;RequiredVersion=$version;}
        AssertEquals $res.Count 2 "Get-Module -List with Multiple module specs should return two modules, $res"
    }

    # Purpose: Test the Get-Module functionality for already imported modules with ModuleVersion filter in FullyQualifiedName
    #
    # Action: Load few versions of a module and get-module with ModuleVersion in FullyQualifiedName
    #   
    # Expected Result: should return all imported versions greater/equal to the specified version
    #   
    TestCase GetLoadedModulesWithModuleVersionInFQN -tags @("BVT") {
        $version = "1.0"
        Import-Module $script:TestModule5 -RequiredVersion "1.0"
        Import-Module $script:TestModule5 -RequiredVersion "2.0"
        Import-Module $script:TestModule5 -RequiredVersion "3.0"
        Import-Module $script:TestModule5 -RequiredVersion "4.0"
        Import-Module $script:TestModule5 -RequiredVersion "5.0"
        $res = Get-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;ModuleVersion=$version;Guid=$script:TestModule5_Guid}
        AssertEquals $res.Count 5 "Get-Module with ModuleVersion in FQN should return 5 loaded versions of $script:TestModule5, $res"
    }

    # Purpose: Test the Get-Module functionality for already imported modules with MaximumVersion filter in FullyQualifiedName
    #
    # Action: Load few versions of a module and get-module with MaximumVersion in FullyQualifiedName
    #   
    # Expected Result: should return all imported versions lesser/equal to the specified version
    #   
    TestCase GetLoadedModulesWithMaximumVersionInFQN -tags @("BVT") {
        $version = "3.*"
        Import-Module $script:TestModule5 -RequiredVersion "1.0"
        Import-Module $script:TestModule5 -RequiredVersion "2.0"
        Import-Module $script:TestModule5 -RequiredVersion "3.0"
        Import-Module $script:TestModule5 -RequiredVersion "4.0"
        Import-Module $script:TestModule5 -RequiredVersion "5.0"
        $res = Get-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;MaximumVersion=$version;Guid=$script:TestModule5_Guid}
        AssertEquals $res.Count 3 "Get-Module with ModuleVersion in FQN should return 3 loaded versions of $script:TestModule5, $res"
    }

    # Purpose: Test the Get-Module functionality for already imported modules with RequiredVersion filter in FullyQualifiedName
    #
    # Action: Load few versions of a module and get-module with RequiredVersion in FullyQualifiedName
    #   
    # Expected Result: should return the exact version
    #   
    TestCase GetLoadedModulesWithRequiredVersionInFQN -tags @("BVT") {
        $version = "3.0"
        Import-Module $script:TestModule5 -RequiredVersion "1.0"
        Import-Module $script:TestModule5 -RequiredVersion "2.0"
        Import-Module $script:TestModule5 -RequiredVersion "3.0"
        Import-Module $script:TestModule5 -RequiredVersion "4.0"
        Import-Module $script:TestModule5 -RequiredVersion "5.0"
        $res = Get-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$version;Guid=$script:TestModule5_Guid}
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version $version "Version is not as expected"
    }

    # Purpose: Test the New-ModuleManifest functionality with ModuleSpecification as RequiredModules
    #
    # Action: Create a module manifest with required version in required modules, import it
    #   
    # Expected Result: Required modules with required version should be imported
    #   
    TestCase ModuleSpecWithRequiredVersionInNewModuleManifest -tags @("BVT") {
        $manifestPath = "$env:Test\temp_$(Get-Random).psd1"
        $Version="2.0"

        Write-Verbose -Message "Creating the module manifest with module specification"
        New-ModuleManifest $manifestPath -RequiredModules @{ModuleName=$script:TestModule5;Requiredversion=$Version}
        $importedModule = Import-Module $manifestPath -PassThru
        $res = Get-Module $script:TestModule5
                
        $importedModule | Remove-Module -Force
        RemoveItem $manifestPath
        AssertNotNull $importedModule "Import-Module failed to import a manifest with required version in module specification"
        
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version $version "Version is not as expected"
    }

    # Purpose: Test the Import-Module functionality without version parameters
    #
    # Action: Import-Module $script:TestModule5
    #   
    # Expected Result: Latest version should be imported
    #   
    TestCase ImportModuleWithoutVersionParams -tags @("BVT") {        
        $res = Import-Module $script:TestModule5 -PassThru

        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version "5.0" "Version is not as expected"
    }


    # Purpose: Test the Import-Module functionality with MinimumVersion parameter
    #
    # Action: Import-Module $script:TestModule5 -MinimumVersion $Version
    #   
    # Expected Result: Latest version should be imported
    #   
    TestCase ImportModuleWithMinVersion -tags @("BVT") {
        $Version="2.0"
        $res = Import-Module $script:TestModule5 -MinimumVersion $Version -PassThru
        
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version "5.0" "Version is not as expected"
    }

    # Purpose: Test the Import-Module functionality with MaximumVersion parameter
    #
    # Action: Import-Module $script:TestModule5 -MaximumVersion $Version
    #   
    # Expected Result: Latest version should be imported
    #   
    TestCase ImportModuleWithMaxVersion -tags @("BVT") {
        $Version="3.0"
        $res = Import-Module $script:TestModule5 -MaximumVersion $Version -PassThru
        
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version "3.0" "Version is not as expected"
    }

    # Purpose: Test the Import-Module functionality with MaximumVersion parameter contains star
    #
    # Action: Import-Module $script:TestModule5 -MaximumVersion $Version
    #   
    # Expected Result: Latest version should be imported
    #   
    TestCase ImportModuleWithMaxVersionStar -tags @("BVT") {
        $Version="5.0.0.*"
        $res = Import-Module $script:TestModule5 -MaximumVersion $Version -PassThru
        
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version "5.0" "Version is not as expected"
    }

    # Purpose: Test the Import-Module negative case with MaximumVersion parameter contains more than 1 stars
    #
    # Action: Import-Module $script:TestModule5 -MaximumVersion $Version
    #   
    # Expected Result: Latest version should be imported
    #   
    TestCase ImportModuleWithMaxVersionStarNegative -tags @("BVT") {
        $Version="5.0.*.*"
        $error.Clear()
        try
        {
            $res = Import-Module $script:TestModule5 -MaximumVersion $Version -PassThru -errorAction SilentlyContinue
        }
        catch
        {
            AssertEquals $_.FullyQualifiedErrorId "ParameterBindingFailed,Microsoft.PowerShell.Commands.ImportModuleCommand"
        }
        
    }

    # Purpose: Test the Import-Module negative case with MaximumVersion parameter contains more than 1 stars
    #
    # Action: Import-Module $script:TestModule5 -MaximumVersion $Version
    #   
    # Expected Result: Latest version should be imported
    #   
    TestCase ImportModuleWithMinVersionGreaterThanMaxVersionNegative -tags @("BVT") {
        $MaxVersion="1.0"
        $MinVersion="2.0"
        $error.Clear()
        try
        {
            $res = Import-Module $script:TestModule5 -MaximumVersion $MaxVersion -MinimumVersion $MinVersion -PassThru -errorAction SilentlyContinue
        }
        catch
        {
            AssertEquals $_.FullyQualifiedErrorId "ArgumentOutOfRange,Microsoft.PowerShell.Commands.ImportModuleCommand"
        }
        
    }

    # Purpose: Test the Import-Module negative case with MaximumVersion parameter contains stars not at the end
    #
    # Action: Import-Module $script:TestModule5 -MaximumVersion $Version
    #   
    # Expected Result: Latest version should be imported
    #   
    TestCase ImportModuleWithMaxVersionStarNegative2 -tags @("BVT") {
        $Version="5.0.*.0"
        $error.Clear()
        try
        {
            $res = Import-Module $script:TestModule5 -MaximumVersion $Version -PassThru -errorAction SilentlyContinue
        }
        catch
        {
            AssertEquals $_.FullyQualifiedErrorId "ParameterBindingFailed,Microsoft.PowerShell.Commands.ImportModuleCommand"
        }
        
    }

    # Purpose: Test the Import-Module functionality with MaximumVersion and MinimumVersion parameter
    #
    # Action: Import-Module $script:TestModule5 -MaximumVersion $MaxVersion -Version $MinVersion
    #   
    # Expected Result: Expected version should be imported
    #   
    TestCase ImportModuleWithMaxVersionMinVersion -tags @("BVT") {
        $MaxVersion="4.0.0.*"
        $MinVersion="4.0"
        $res = Import-Module $script:TestModule5 -MaximumVersion $MaxVersion -Version $MinVersion -PassThru
        
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version "4.0" "Version is not as expected"
    }

    # Purpose: Test the Import-Module functionality with the same MaximumVersion and MinimumVersion parameter
    #
    # Action: Import-Module $script:TestModule5 -MaximumVersion $Version -Version $Version
    #   
    # Expected Result: Expected version should be imported
    #   
    TestCase ImportModuleWithMaxVersionEqualMinVersion -tags @("BVT") {
        $Version="4.0"
        $res = Import-Module $script:TestModule5 -MaximumVersion $Version -Version $Version -PassThru
        
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version "4.0" "Version is not as expected"
    }


    # Purpose: Test the Import-Module functionality with ModuleVersion filter in FullyQualifiedName
    #
    # Action: Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;ModuleVersion=$Version}
    #   
    # Expected Result: Latest version should be imported
    #   
    TestCase ImportModuleWithModuleVersionInFQN -tags @("BVT") {
        $Version="2.0"
        $res = Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;ModuleVersion=$Version} -PassThru
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version "5.0" "Version is not as expected"
    }

    # Purpose: Test the Import-Module functionality with MaximumVersion filter in FullyQualifiedName
    #
    # Action: Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;MaximumVersion=$Version}
    #   
    # Expected Result: Latest version should be imported
    #   
    TestCase ImportModuleWithMaximumInFQN -tags @("BVT") {
        $Version="3.0"
        $res = Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;MaximumVersion=$Version} -PassThru
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version "3.0" "Version is not as expected"
    }

    # Purpose: Test the Import-Module functionality with different version as ModuleVersion filter in FullyQualifiedName
    #
    # Action: Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;ModuleVersion=$Version}
    #   
    # Expected Result: Latest version should be imported
    #   
    TestCase ImportModuleWithModuleVersionInFQN2 -tags @("P1") {
        $Version="4.0"
        $res = Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;ModuleVersion=$Version} -PassThru
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version "5.0" "Version is not as expected"
    }

    # Purpose: Test the Import-Module functionality with different version as ModuleVersion filter in FullyQualifiedName
    #
    # Action: Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;ModuleVersion=$Version}
    #   
    # Expected Result: Latest version should be imported
    #   
    TestCase ImportModuleWithModuleVersionInFQN3 -tags @("P1") {
        $Version="5.0"
        $res = Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;ModuleVersion=$Version} -PassThru
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version $Version "Version is not as expected"
    }

    # Purpose: Test the Import-Module functionality with RequiredVersion filter in FullyQualifiedName
    #
    # Action: Import-Module $script:TestModule5 -RequiredVersion $Version
    #   
    # Expected Result: Exact version should be imported
    #   
    TestCase ImportModuleWithReqVersion -tags @("BVT") {
        $Version="2.0"
        $res = Import-Module $script:TestModule5 -RequiredVersion $Version -PassThru
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version $Version "Version is not as expected"
    }

    # Purpose: Test the Import-Module functionality with RequiredVersion filter
    #
    # Action: Import a test module with required version filter
    #   
    # Expected Result: Exact version should be imported and no other versions are internally loaded to check the exact version
    #   
    TestCase ImportModuleWithReqVersionShouldNotLoadOtherVersionsInternally -tags @("P1") {
        $Version="2.0"        
        $job = Start-Job -ScriptBlock { param($name,$version) Import-Module $name -RequiredVersion $version -PassThru} -ArgumentList $script:TestModule5,$version
        Wait-Job $job
        $res = $job.ChildJobs[0].Output[0]
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version $Version "Version is not as expected"
        Assert ($job.ChildJobs[0].Verbose -notcontains "3.0") "Verbose messages should not contain message with higher version module, $($job.ChildJobs[0].Verbose)"
        Assert ($job.ChildJobs[0].Verbose -notcontains "4.0") "Verbose messages should not contain message with higher version module, $($job.ChildJobs[0].Verbose)"
        Assert ($job.ChildJobs[0].Verbose -notcontains "5.0") "Verbose messages should not contain message with higher version module, $($job.ChildJobs[0].Verbose)"
        Assert ($job.ChildJobs[0].Verbose -notcontains "1.0") "Verbose messages should not contain message with lower version module, $($job.ChildJobs[0].Verbose)"
    }

    # Purpose: Test the Import-Module functionality with MinimumVersion filter
    #
    # Action: Import a test module with not available version as MinimumVersion filter
    #   
    # Expected Result: Should fail and verbose messages should not contain any loading lower version module details
    #   
    TestCase ImportModuleWithMinVersionShouldNotLoadLowerVersionsInternally -tags @("P1") {
        $Version="8.0"
        $job = Start-Job -ScriptBlock { param($name,$version) Import-Module $name -MinimumVersion $version -PassThru} -ArgumentList $script:TestModule5,$version
        Wait-Job $job
        Assert ($job.ChildJobs[0].Verbose -notcontains "1.0") "Verbose messages should not contain message with lower version module, $($job.ChildJobs[0].Verbose)"
        Assert ($job.ChildJobs[0].Verbose -notcontains "2.0") "Verbose messages should not contain message with lower version module, $($job.ChildJobs[0].Verbose)"
        Assert ($job.ChildJobs[0].Verbose -notcontains "3.0") "Verbose messages should not contain message with lower version module, $($job.ChildJobs[0].Verbose)"
        Assert ($job.ChildJobs[0].Verbose -notcontains "4.0") "Verbose messages should not contain message with lower version module, $($job.ChildJobs[0].Verbose)"
        Assert ($job.ChildJobs[0].Verbose -notcontains "5.0") "Verbose messages should not contain message with lower version module, $($job.ChildJobs[0].Verbose)"
        AssertEquals $job.ChildJobs[0].Error[0].FullyQualifiedErrorId "Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand" "Import a test module with not available version as MinimumVersion filter should fail"
    }

    # Purpose: Test the Import-Module functionality with MaximumVersion filter
    #
    # Action: Import a test module with not available version as MaximumVersion filter
    #   
    # Expected Result: Should fail and verbose messages should not contain any loading lower version module details
    #   
    TestCase ImportModuleWithMaxVersionShouldNotLoadLowerVersionsInternally -tags @("P1") {
        $Version="0.*"
        $job = Start-Job -ScriptBlock { param($name,$version) Import-Module $name -MaximumVersion $version -PassThru} -ArgumentList $script:TestModule5,$version
        Wait-Job $job
        Assert ($job.ChildJobs[0].Verbose -notcontains "1.0") "Verbose messages should not contain message with lower version module, $($job.ChildJobs[0].Verbose)"
        Assert ($job.ChildJobs[0].Verbose -notcontains "2.0") "Verbose messages should not contain message with lower version module, $($job.ChildJobs[0].Verbose)"
        Assert ($job.ChildJobs[0].Verbose -notcontains "3.0") "Verbose messages should not contain message with lower version module, $($job.ChildJobs[0].Verbose)"
        Assert ($job.ChildJobs[0].Verbose -notcontains "4.0") "Verbose messages should not contain message with lower version module, $($job.ChildJobs[0].Verbose)"
        Assert ($job.ChildJobs[0].Verbose -notcontains "5.0") "Verbose messages should not contain message with lower version module, $($job.ChildJobs[0].Verbose)"
        AssertEquals $job.ChildJobs[0].Error[0].FullyQualifiedErrorId "Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand" "Import a test module with not available version as MaximumVersion filter should fail"
    }

    # Purpose: Test the Import-Module functionality with RequiredVersion and Guid filters in FullyQualifiedName
    #
    # Action: Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version;Guid=$script:TestModule5_Guid}
    #   
    # Expected Result: Exact version with exact guid should be imported
    #   
    TestCase ImportModuleWithGuidInFQN -tags @("BVT") {
        $Version="2.0"
        $res = Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version;Guid=$script:TestModule5_Guid} -PassThru
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version $Version "Version is not as expected"
        AssertEquals $res.Guid $script:TestModule5_Guid "Guid is not as expected"
    }


    # Purpose: Test the Import-Module functionality with RequiredVersion filter in FullyQualifiedName
    #
    # Action: Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version}
    #   
    # Expected Result: Exact version should be imported
    #   
    TestCase ImportModuleWithRequiredVersionInFQN -tags @("BVT") {
        $Version="2.0"
        $res = Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version} -PassThru
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version $Version "Version is not as expected"
    }


    # Purpose: Test the Import-Module functionality with different version as RequiredVersion filter in FullyQualifiedName
    #
    # Action: Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version}
    #   
    # Expected Result: Exact version should be imported
    #   
    TestCase ImportModuleWithRequiredVersionInFQN_2 -tags @("P1") {
        $Version="1.0"
        $res = Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version} -PassThru
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version $Version "Version is not as expected"
    }

    # Purpose: Test the Import-Module functionality with latest version as RequiredVersion filter in FullyQualifiedName
    #
    # Action: Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version}
    #   
    # Expected Result: Exact version should be imported
    #   
    TestCase ImportModuleWithRequiredVersionInFQN_3 -tags @("P1") {
        $Version="5.0"
        $res = Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version} -PassThru
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version $Version "Version is not as expected"
    }

    # Purpose: Test the Import-Module functionality with multiple ModuleSpecifications filters in FullyQualifiedName
    #
    # Action: Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version},@{ModuleName=$script:TestModule1;RequiredVersion=$Version} 
    #   
    # Expected Result: Should import two modules
    #   
    TestCase ImportModuleWithMultipleFQNs -tags @("P1") {
        $Version="2.0"
        Get-Module $script:TestModule5,$script:TestModule1 | Remove-Module -Force
        $res = Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version},@{ModuleName=$script:TestModule1;RequiredVersion=$Version} -PassThru
        AssertEquals $res.Count 2 "Import-Module with multiple FullyQualifiedNames should import them, $res"
    }

    # Purpose: Test the Import-Module functionality with multi-versioned module name
    #
    # Action: Import-Module $script:TestModule5
    #   
    # Expected Result: Should import latest valid version under the module base
    #   
    TestCase ImportModuleWithName -tags @("BVT") {
        $Version="5.0"
        $res = Import-Module $script:TestModule5 -PassThru
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version $Version "Version is not as expected"
    }

    # Purpose: Test the Import-Module functionality with multi-versioned module path
    #
    # Action: Import-Module "$script:ProgramFilesModulesPath\$script:TestModule5"
    #   
    # Expected Result: Should import latest valid version under the path
    #   
    TestCase ImportModuleWithPath -tags @("BVT") {
        $Version="5.0"
        $res = Import-Module "$script:ProgramFilesModulesPath\$script:TestModule5" -PassThru
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version $Version "Version is not as expected"
    }

    # Purpose: Test the Import-Module functionality to import a sub module qualified with multi-version module name
    #
    # Action: Import-Module "$script:TestModule5\$script:TestModule5"
    #   
    # Expected Result: Should import local version under the module base
    #   
    TestCase ImportModuleModuleQualifiedSubModule -tags @("BVT") {
        $Version="1.0"
        $res = Import-Module "$script:TestModule5\$script:TestModule5" -PassThru
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version $Version "Version is not as expected"
    }


    # Purpose: Test the Import-Module functionality with path ending with version folder
    #
    # Action: Import-Module "$script:ProgramFilesModulesPath\$script:TestModule5\$Version"
    #   
    # Expected Result: Should fail
    #   
    TestCase ImportModuleWithPathEndingWithVersion -tags @("BVT") {
        $Version="5.0"
        AssertFullyQualifiedErrorIdEquals -scriptblock {Import-Module "$script:ProgramFilesModulesPath\$script:TestModule5\$Version"} `
                                          -expectedFullyQualifiedErrorId "Modules_ModuleNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand"
    }

    # Purpose: Test the Import-Module functionality with full path to the module manifest file under a different version folder
    #
    # Action: Import-Module "$script:ProgramFilesModulesPath\$script:TestModule5\$Version\$script:TestModule5.psd1"
    #   
    # Expected Result: Should fail to import the module
    #   
    TestCase ImportModuleWithManifestFilePath -tags @("P1") {
        $Version="7.0"
        AssertFullyQualifiedErrorIdEquals -scriptblock {Import-Module "$script:ProgramFilesModulesPath\$script:TestModule5\$Version\$script:TestModule5.psd1"} `
                                          -expectedFullyQualifiedErrorId "Modules_InvalidModuleManifestVersion,Microsoft.PowerShell.Commands.ImportModuleCommand"
    }

    # Purpose: Test the Remove-Module functionality with RequiredVersion filter in FullyQualifiedName
    #
    # Action: import two versions of a module and remove one exact version
    #   
    # Expected Result: Exact version should be removed and other version should not be removed.
    #   
    TestCase RemoveModuleWithFQN -tags @("BVT") {
        $Version1 = "3.0"
        $Version2 = "5.0"
        Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version1},@{ModuleName=$script:TestModule5;RequiredVersion=$Version2}
        Remove-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version2}
        $res = Get-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version2}
        $res2 = Get-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version1}
        AssertEquals $res $null "Remove-Module with FullyQualifiedName should remove the exact specified version, $res"
        AssertEquals $res2.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res2.Version $Version1 "Version is not as expected"
    }

    # Purpose: Test the Remove-Module functionality with RequiredVersion filter in FullyQualifiedName
    #
    # Action: import two versions of a module and remove one exact version
    #   
    # Expected Result: Exact version should be removed and other version should not be removed.
    #   
    TestCase RemoveModuleWithFQN2 -tags @("P1") {
        $Version1 = "3.0"
        $Version2 = "4.0"
        
        Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version1},@{ModuleName=$script:TestModule5;RequiredVersion=$Version2}
        Remove-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version2}
        
        $res = Get-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version2}
        $res2 = Get-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version1}

        AssertEquals $res $null "Remove-Module with FullyQualifiedName should remove the exact specified version, $res"
        AssertEquals $res2.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res2.Version $Version1 "Version is not as expected"
    }


    # Purpose: Test the Remove-Module functionality with ModuleVersion filter in FullyQualifiedName
    #
    # Action: import two versions of a module and remove module with lower version as ModuleVersion in ModuleSpec
    #   
    # Expected Result: Should remove all the versions >= specified ModuleVersion
    #   
    TestCase RemoveModuleWithModuleVersionInFQN -tags @("BVT") {
        $Version1 = "3.0"
        $Version2 = "5.0"
        Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version1}
        Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version2}
        Remove-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;ModuleVersion=$Version1}
        $res = Get-Module $script:TestModule5
        AssertEquals $res $null "Remove-Module with ModuleVersion in FullyQualifiedName should remove all the versions of a module which satisfies the min version criteria, $res"
    }

    # Purpose: Test the Remove-Module functionality with RequiredVersion and Guid filters in FullyQualifiedName
    #
    # Action: import two versions of a module and remove one exact version with module guid
    #   
    # Expected Result: Exact version with specified Guid should be removed and other version should not be removed.
    #   
    TestCase RemoveModuleWithGuidInFQN -tags @("BVT") {
        $Version1 = "3.0"
        $Version2 = "5.0"
        Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version1}
        Import-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version2}
        Remove-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version2;Guid=$script:TestModule5_Guid}
        $res = Get-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version2}
        $res2 = Get-Module -FullyQualifiedName @{ModuleName=$script:TestModule5;RequiredVersion=$Version1}
        AssertEquals $null $res "Remove-Module with FullyQualifiedName should remove the exact specified version and exact Guid, $res"
        AssertEquals $res2.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res2.Version $Version1 "Version is not as expected"
    }


    # Purpose: Validate the Test-ModuleManifest functionality with valid version folder
    #
    # Action: Test-ModuleManifest "$script:ProgramFilesModulesPath\$script:TestModule5\4.0\$script:TestModule5.psd1"
    #   
    # Expected Result: Validation should not fail
    #   
    TestCase TestModuleManifestWithValidVersion -tags @("BVT") {
        $res = Test-ModuleManifest "$script:ProgramFilesModulesPath\$script:TestModule5\4.0\$script:TestModule5.psd1"
        AssertEquals $res.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res.Version "4.0" "Version is not as expected"
    }

    # Purpose: Validate the Test-ModuleManifest functionality with invalid version folder
    #
    # Action: Test-ModuleManifest "$script:ProgramFilesModulesPath\$script:TestModule5\7.0\$script:TestModule5.psd1"
    #   
    # Expected Result: Validation should fail
    #   
    TestCase TestModuleManifestWithInvalidVersion -tags @("BVT") {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Test-ModuleManifest "$script:ProgramFilesModulesPath\$script:TestModule5\7.0\$script:TestModule5.psd1"} `
                                          -expectedFullyQualifiedErrorId "Modules_InvalidModuleManifestVersion,Microsoft.PowerShell.Commands.TestModuleManifestCommand"
    }

    # Purpose: Test the module autoloading functionality with mult-version module
    #
    # Action: Run one cmdlet from the multi-versioned module without importing
    #   
    # Expected Result: latest version should be imported
    #   
    TestCase ModuleAutoloadingWithMultipleVersions -tags @("BVT") {
        $Version = "5.0"
        $cmdName = "Get-$script:TestModule5"
        $res = & $cmdName
        $res2 = Get-Module $script:TestModule5
        AssertEquals $res "$script:TestModule5 $Version" "Command discovery should import the latest version from under the module base, $res"
        AssertEquals $res2.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res2.Version $Version "Version is not as expected"
    }

    # Purpose: Test the module autoloading functionality for module qualified command with mult-version module    
    #
    # Action: Run module qualified command from the multi-versioned module without importing
    #   
    # Expected Result: latest version should be imported
    #   
    TestCase ModuleAutoloading_ModuleQualifiedCommandWithMultipleVersions -tags @("BVT") {
        $Version = "5.0"
        $cmdName = "$script:TestModule5\Get-$script:TestModule5"
        $res = & $cmdName
        $res2 = Get-Module $script:TestModule5
        AssertEquals $res "$script:TestModule5 $Version" "module qualified command should import the latest version from under the module base, $res"
        AssertEquals $res2.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res2.Version $Version "Version is not as expected"
    }
    
           
    # Purpose: Test the Get-Command functionality with module qualified command name with multi-version module
    #
    # Action: Get-Command modulename\command
    #   
    # Expected Result: should get the command from the latest version
    #   
    TestCase GetCommandModuleQualifiedNameWithMultipleVersions -tags @("BVT") {
        $Version = "5.0"
        $cmdName = "$script:TestModule5\Get-$script:TestModule5"
        $res = Get-Command $cmdName
        $res2 = Get-Module $script:TestModule5
        AssertEquals $res.Name "Get-$script:TestModule5" "Command name is not as expected"
        AssertEquals $res.Module.Name $script:TestModule5 "Command module name is not as expected"
        AssertEquals $res2.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res2.Version $Version "Version is not as expected"
    }

    # Purpose: Test the Get-Command functionality for a command from multi-version module
    #
    # Action: Get-Command $cmdName
    #   
    # Expected Result: should get the command from the latest version
    #   
    TestCase GetCommandWithMultipleVersions -tags @("BVT") {
        $Version = "5.0"
        $cmdName = "Get-$script:TestModule5"
        $res = Get-Command $cmdName                
        $res2 = Get-Module $script:TestModule5
        AssertEquals $res.Name "Get-$script:TestModule5" "Command name is not as expected"        
        AssertEquals $res2.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res2.Version $Version "Version is not as expected"
    }

    # Purpose: Test the Get-Command functionality with ModuleVersion filter in FullyQualifiedModule for a command from multi-version module
    #
    # Action: Get-Command $cmdName -FullyQualifiedModule @{ModuleName=$script:TestModule5;ModuleVersion="1.0"}
    #   
    # Expected Result: should get the command from the latest version
    #   
    TestCase GetCommandWithMultipleVersions_FQN -tags @("BVT") {
        $Version = "5.0"
        $cmdName = "Get-$script:TestModule5"
        $res = Get-Command $cmdName -FullyQualifiedModule @{ModuleName=$script:TestModule5;ModuleVersion="1.0"}
        $res2 = Get-Module $script:TestModule5
        AssertEquals $res.Name "Get-$script:TestModule5" "Command name is not as expected"
        AssertEquals $res2.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res2.Version $Version "Version is not as expected"
    }

    # Purpose: Test the Get-Command functionality with MaximumVersion filter in FullyQualifiedModule for a command from multi-version module
    #
    # Action: Get-Command $cmdName -FullyQualifiedModule @{ModuleName=$script:TestModule5;MaximumVersion="3.0"}
    #   
    # Expected Result: should get the command from the latest version
    #   
    TestCase GetCommandWithMultipleVersionsMaximumVersion_FQN -tags @("BVT") {
        $Version = "5.0"
        $cmdName = "Get-$script:TestModule5"
        $res = Get-Command $cmdName -FullyQualifiedModule @{ModuleName=$script:TestModule5;MaximumVersion="5.0"}
        $res2 = Get-Module $script:TestModule5
        AssertEquals $res.Name "Get-$script:TestModule5" "Command name is not as expected"
        AssertEquals $res2.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res2.Version $Version "Version is not as expected"
    }

    # Purpose: Test the Get-Command functionality with ModuleVersion filter in FullyQualifiedModule
    #
    # Action: Get-Command -FullyQualifiedModule @{ModuleName=$script:TestModule5;ModuleVersion="1.0"}
    #   
    # Expected Result: Get-Command should find the commands from 5 versions
    #   
    TestCase GetCommandWithFQNandWithoutName -tags @("BVT") {
        $res = Get-Command -FullyQualifiedModule @{ModuleName=$script:TestModule5;ModuleVersion="1.0"}
        AssertEquals $res.Count 5 "Get-Command should find the commands from 5 versions, $res"
    }

    # Purpose: Test the Get-Command functionality with MaximumVersion filter in FullyQualifiedModule
    #
    # Action: Get-Command -FullyQualifiedModule @{ModuleName=$script:TestModule5;MaximumVersion="3.0"}
    #   
    # Expected Result: Get-Command should find the commands from 5 versions
    #   
    TestCase GetCommandWithFQNandWithoutNameMaximumVersion -tags @("BVT") {
        $res = Get-Command -FullyQualifiedModule @{ModuleName=$script:TestModule5;MaximumVersion="3.0"}
        AssertEquals $res.Count 3 "Get-Command should find the commands from 3 versions, $res"
    }

    # Purpose: Test the Get-Command functionality with wildcard command name and FullyQualifiedModule
    #
    # Action: Get-Command * -FullyQualifiedModule @{ModuleName=$script:TestModule5;ModuleVersion="4.0"}
    #   
    # Expected Result: should find all cmds from 5 versions
    #   
    TestCase GetCommandWildcardAndFQN -tags @("BVT") {
        $res = Get-Command * -FullyQualifiedModule @{ModuleName=$script:TestModule5;ModuleVersion="1.0"}
        AssertEquals $res.Count 5 "Get-Command should find the cmds from 5 versions, $res"
    }

    # Purpose: Test the Get-Command functionality with wildcard command name and FullyQualifiedModule
    #
    # Action: Get-Command * -FullyQualifiedModule @{ModuleName=$script:TestModule5;MaximumVersion="3.0"}
    #   
    # Expected Result: should find all cmds from 5 versions
    #   
    TestCase GetCommandWildcardAndFQNMaximumVersion -tags @("BVT") {
        $res = Get-Command * -FullyQualifiedModule @{ModuleName=$script:TestModule5;MaximumVersion="3.0"}
        AssertEquals $res.Count 3 "Get-Command should find the cmds from 3 versions, $res"
    }

    # Purpose: Test the Get-Command functionality with FullyQualifiedModule for a single versioned module
    #
    # Action: Get-Command -FullyQualifiedModule @{ModuleName="PSWorkflow";ModuleVersion="1.0"}
    #   
    # Expected Result: should find the cmds from PSWorkflow
    #   
    TestCase GetCommandFQNWithoutName_SingleVersion -tags @("P1") {
        $res = Get-Command -FullyQualifiedModule @{ModuleName="PSWorkflow";ModuleVersion="1.0"}
        AssertEquals $res.Count 2 "Get-Command should find 2 cmds from PSWorkflow module, $res"
    }

    # Purpose: Test the Get-Command functionality with FullyQualifiedModule for a single versioned module
    #
    # Action: Get-Command -FullyQualifiedModule @{ModuleName="PSWorkflow";MaximumVersion="1.0"}
    #   
    # Expected Result: should find the cmds from PSWorkflow
    #   
    TestCase GetCommandFQNWithoutName_SingleVersionMaximumVersion -tags @("P1") {
        $res = Get-Command -FullyQualifiedModule @{ModuleName="PSWorkflow";MaximumVersion="7.0"}
        AssertEquals $res.Count 2 "Get-Command should find 2 cmds from PSWorkflow module, $res"
    }

    # Purpose: Test the Get-Command functionality with RequiredVersion filter in FullyQualifiedModule
    #
    # Action: Get-Command -FullyQualifiedModule @{ModuleName=$script:TestModule5;RequiredVersion=$Version}
    #   
    # Expected Result: should find the cmds from exact version
    #   
    TestCase GetCommandReqVersionFQNWithoutName -tags @("P1") {
        $Version = "4.0"
        $res = Get-Command -FullyQualifiedModule @{ModuleName=$script:TestModule5; RequiredVersion=$Version}
        AssertEquals $res.Name "Get-$script:TestModule5" "Command name is not as expected"
        AssertEquals $res.Version $Version "Command version is not as expected"
    }

    # Purpose: Test the Get-Command functionality with wildcard name and RequiredVersion filter in FullyQualifiedModule for a single versioned module
    #
    # Action: Get-Command * -FullyQualifiedModule @{ModuleName="PSWorkflow";RequiredVersion="2.0.0.0"}
    #   
    # Expected Result: should find all cmds from psworkflow module
    #   
    TestCase GetCommandWildcardAndFQN_SingleVersion -tags @("P1") {
        $Version = "2.0.0.0"
        $modName = "PSWorkflow"
        Get-Module $modName | Remove-Module -Force
        $res = Get-Command * -FullyQualifiedModule @{ModuleName=$modName;ModuleVersion=$Version}
        AssertEquals $res.Count 3 "Get-Command should find the cmd from $modName, $res"
    }

    # Purpose: Test the Get-Command functionality with Module parameter for a multi-version module
    #
    # Action: Get-Command -Module $script:TestModule5
    #   
    # Expected Result: should find the cmds from the latest version
    #   
    TestCase GetCommandWithModuleAndWithoutName -tags @("BVT") {
        $Version = "5.0"
        $res = Get-Command -Module $script:TestModule5
        $res2 = Get-Module $script:TestModule5
        AssertEquals $res.Name "Get-$script:TestModule5" "Command name is not as expected"
        AssertEquals $res.Version $Version "Command version is not as expected"
        AssertEquals $res2.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res2.Version $Version "Version is not as expected"
    }

    # Purpose: Test the Get-Command functionality with wildcard name and module parameter for a multi-version module
    #
    # Action: Get-Command * -Module $script:TestModule5
    #   
    # Expected Result: should find all cmds from the module
    #   
    TestCase GetCommandWildcardNameAndModuleName -tags @("P1") {
        $Version = "5.0"
        $res = Get-Command * -Module $script:TestModule5
        $res2 = Get-Module $script:TestModule5
        AssertEquals $res.Name "Get-$script:TestModule5" "Command name is not as expected"
        AssertEquals $res.Version $Version "Command version is not as expected"
        AssertEquals $res2.Name $script:TestModule5 "Name is not as expected"
        AssertEquals $res2.Version $Version "Version is not as expected"
    }

    # Purpose: Validate Import-Module with PSSession and FullyQualifiedName with ModuleVersion
    #
    # Action: Import-Module -FullyQualifiedName @{ModuleName=$ModuleName;ModuleVersion=$Version} -PSSession $session -PassThru
    #   
    # Expected Result: Should import the module
    #   
    TestCase ImportModuleInPSSessionWithModuleVersionInFQN -tags @("P1") {
        $Version = "1.0"
        $ModuleName = $script:TestModule5

        $session = New-PSSession
        Invoke-Command -Session $session {param($moduleName, $moduleVersion) Import-Module -FullyQualifiedName @{ModuleName=$moduleName;ModuleVersion=$moduleVersion}} -ArgumentList $ModuleName,$Version

        try
        {
            $res = Import-Module -FullyQualifiedName @{ModuleName=$ModuleName;ModuleVersion=$Version;MaximumVersion=$Version} -PSSession $session -PassThru
            AssertEquals $res.Name $ModuleName "Import-Module with PSSession and FullyQualifiedName with ModuleVersion is not working, $res"
            $commandOutput = & "Get-$ModuleName"
            $output = $commandOutput -split ' '
            AssertEquals $output[0] $ModuleName "Imported module should import the specified version from the session"
            Assert ([Version]$output[1] -ge $Version) "Imported module should import the specified version from the session"
        }
        finally
        {
            Remove-PSSession -Session $session
        }
    }

    # Purpose: Validate Import-Module with PSSession and FullyQualifiedName with MaximumVersion
    #
    # Action: Import-Module -FullyQualifiedName @{ModuleName=$ModuleName;MaximumVersion=$Version} -PSSession $session -PassThru
    #   
    # Expected Result: Should import the module
    #   
    TestCase ImportModuleInPSSessionWithMaximumVersionInFQN -tags @("P1") {
        $Version = "1.0"
        $ModuleName = $script:TestModule5

        $session = New-PSSession
        Invoke-Command -Session $session {param($moduleName, $moduleVersion) Import-Module -FullyQualifiedName @{ModuleName=$moduleName;MaximumVersion=$moduleVersion}} -ArgumentList $ModuleName,$Version

        try
        {
            $res = Import-Module -FullyQualifiedName @{ModuleName=$ModuleName;MaximumVersion=$Version} -PSSession $session -PassThru
            AssertEquals $res.Name $ModuleName "Import-Module with PSSession and FullyQualifiedName with ModuleVersion is not working, $res"
            $commandOutput = & "Get-$ModuleName"
            $output = $commandOutput -split ' '
            AssertEquals $output[0] $ModuleName "Imported module should import the specified version from the session"
            Assert ([Version]$output[1] -ge $Version) "Imported module should import the specified version from the session"
        }
        finally
        {
            Remove-PSSession -Session $session
        }
    }

    # Purpose: Validate Import-Module with PSSession and FullyQualifiedName with ModuleVersion and Guid 
    #
    # Action: Import-Module -FullyQualifiedName @{ModuleName=$ModuleName;ModuleVersion=$Version;Guid=$ModuleGuid} -PSSession $session -PassThru
    #   
    # Expected Result: Should import the module
    #   
    TestCase ImportModuleInPSSessionWithModuleVersionAndGuidInFQN -tags @("P1") {
        $Version = "3.0"
        $ModuleName = $script:TestModule5
        $ModuleGuid = $script:TestModule5_Guid
        $session = New-PSSession
        Invoke-Command -Session $session {param($moduleName, $moduleVersion) Import-Module -FullyQualifiedName @{ModuleName=$moduleName;ModuleVersion=$moduleVersion}} -ArgumentList $ModuleName,$Version

        try
        {
            $res = Import-Module -FullyQualifiedName @{ModuleName=$ModuleName;ModuleVersion=$Version;Guid=$ModuleGuid;MaximumVersion=$Version} -PSSession $session -PassThru
            AssertEquals $res.Name $ModuleName "Import-Module with PSSession and FullyQualifiedName with ModuleVersion and Guid is not working, $res"
            $commandOutput = & "Get-$ModuleName"
            $output = $commandOutput -split ' '
            AssertEquals $output[0] $ModuleName "Imported module should import the specified version from the session"
            Assert ([Version]$output[1] -ge $Version) "Imported module should import the specified version from the session"
        }
        finally
        {
            Remove-PSSession -Session $session
        }
    }

    # Purpose: Validate Import-Module with PSSession and FullyQualifiedName with RequiredVersion
    #
    # Action: Import-Module -FullyQualifiedName @{ModuleName=$ModuleName;RequiredVersion=$Version} -PSSession $session -PassThru
    #   
    # Expected Result: Should import the module
    #   
    TestCase ImportModuleInPSSessionWithRequiredVersionInFQN -tags @("P1") {
        $Version = "2.0"
        $ModuleName = $script:TestModule5

        $session = New-PSSession
        Invoke-Command -Session $session {param($moduleName, $moduleVersion) Import-Module -FullyQualifiedName @{ModuleName=$moduleName;RequiredVersion=$moduleVersion}} -ArgumentList $ModuleName,$Version

        try
        {
            $res = Import-Module -FullyQualifiedName @{ModuleName=$ModuleName;RequiredVersion=$Version} -PSSession $session -PassThru
            AssertEquals $res.Name $ModuleName "Import-Module with PSSession and FullyQualifiedName with RequiredVersion is not working, $res"
            $commandOutput = & "Get-$ModuleName"
            $output = $commandOutput -split ' '
            AssertEquals $output[0] $ModuleName "Imported module should import the specified version from the session"
            Assert ([Version]$output[1] -eq $Version) "Imported module should import the specified version from the session"
        }
        finally
        {
            Remove-PSSession -Session $session
        }
    }

    # Purpose: Validate Import-Module with PSSession and FullyQualifiedName with RequiredVersion and Guid
    #
    # Action: Import-Module -FullyQualifiedName @{ModuleName=$ModuleName;RequiredVersion=$Version;Guid=$ModuleGuid} -PSSession $session -PassThru
    #   
    # Expected Result: Should import the module
    #   
    TestCase ImportModuleInPSSessionWithRequiredVersionAndGuidInFQN -tags @("P1") {
        $Version = "5.0"
        $ModuleName = $script:TestModule5
        $ModuleGuid = $script:TestModule5_Guid

        $session = New-PSSession
        Invoke-Command -Session $session {param($moduleName, $moduleVersion) Import-Module -FullyQualifiedName @{ModuleName=$moduleName;RequiredVersion=$moduleVersion}} -ArgumentList $ModuleName,$Version

        try
        {        
            $res = Import-Module -FullyQualifiedName @{ModuleName=$ModuleName;RequiredVersion=$Version;Guid=$ModuleGuid} -PSSession $session -PassThru
            AssertEquals $res.Name $ModuleName "Import-Module with PSSession and FullyQualifiedName with RequiredVersion and Guid is not working, $res"
            $commandOutput = & "Get-$ModuleName"
            $output = $commandOutput -split ' '
            AssertEquals $output[0] $ModuleName "Imported module should import the specified version from the session"
            Assert ([Version]$output[1] -eq $Version) "Imported module should import the specified version from the session"
        }
        finally
        {
            Remove-PSSession -Session $session
        }
    }

    # Purpose: Validate Export-PSSession with ModuleName and FullyQualifiedModule
    #
    # Action: Export-PSSession -FullyQualifiedModule @{ModuleName=$modName;ModuleVersion=$Version} -Module $script:TestModule5 -Session $session -OutputModule $exportedModule
    #   
    # Expected Result: should fail
    #   
    TestCase ExportPSSessionWithModuleNameAndFullyQualifiedModule -tags @("P1") {
        $Version = "5.0"
        $exportedModule = "Exported_$(Get-Random)_$script:TestModule5"
        $session = New-PSSession
        try
        {
            AssertFullyQualifiedErrorIdEquals -scriptblock {Export-PSSession -FullyQualifiedModule @{ModuleName=$script:TestModule5;ModuleVersion=$Version} -Module $script:TestModule5 -Session $session -OutputModule $exportedModule} `
                                              -expectedFullyQualifiedErrorId "ModuleAndFullyQualifiedModuleCannotBeSpecifiedTogether,Microsoft.PowerShell.Commands.ExportPSSessionCommand"
        }
        finally
        {
            Remove-PSSession $session
        }
    }
    

    # Purpose: Validate Export-PSSession with ModuleVersion in FullyQualifiedModule
    #
    # Action: Export-PSSession -FullyQualifiedModule @{ModuleName=$script:TestModule5;ModuleVersion=$Version} -Session $session -OutputModule $exportedModule
    #   
    # Expected Result: Export the module from the session
    #   
    TestCase ExportPSSessionWithFullyQualifiedModule -tags @("BVT") {
        $Version = "2.0"
        $exportedModule = "Exported_$(Get-Random)_$script:TestModule5"
        $session = New-PSSession
        Invoke-Command -Session $session {param($moduleName, $moduleVersion) Import-Module -FullyQualifiedName @{ModuleName=$moduleName;ModuleVersion=$moduleVersion}} -ArgumentList $script:TestModule5,$Version
        try
        {
            $res = Export-PSSession -FullyQualifiedModule @{ModuleName=$script:TestModule5;ModuleVersion=$Version;MaximumVersion="7.0"} -Session $session -OutputModule $exportedModule
            AssertNotNull $res "Export-PSSession should export the module from the session"

            $res2 = Get-Module $exportedModule -ListAvailable
            AssertEquals $res2.Name $exportedModule "Export-PSSession should export the module from the session, $res2"
        }
        finally
        {
            Remove-PSSession $session
            Uninstall-Module $exportedModule
            Get-Module $exportedModule | Remove-Module -Force
        }
    }


    # Purpose: Validate Export-PSSession with RequiredVersion in FullyQualifiedModule
    #
    # Action: Export-PSSession -FullyQualifiedModule @{ModuleName=$script:TestModule5;RequiredVersion=$Version} -Session $session -OutputModule $exportedModule
    #   
    # Expected Result: Export the module from the session
    #   
    TestCase ExportPSSessionWithReqVersionFullyQualifiedModule -tags @("BVT") {
        $Version = "2.0"
        $exportedModule = "Exported_$(Get-Random)_$script:TestModule5"
        $session = New-PSSession
        Invoke-Command -Session $session {param($moduleName, $moduleVersion) Import-Module -FullyQualifiedName @{ModuleName=$moduleName;RequiredVersion=$moduleVersion}} -ArgumentList $script:TestModule5,$Version
        try
        {
            $res = Export-PSSession -FullyQualifiedModule @{ModuleName=$script:TestModule5;RequiredVersion=$Version} -Session $session -Force -OutputModule $exportedModule
            AssertNotNull $res "Export-PSSession should export the module from the session"
        }
        finally
        {
            Remove-PSSession $session
            Uninstall-Module $exportedModule
            Get-Module $exportedModule | Remove-Module -Force
        }
    }


    # Purpose: Validate Import-PSSession with ModuleName and FullyQualifiedModule
    #
    # Action: Import-PSSession -FullyQualifiedModule @{ModuleName=$modName;ModuleVersion=$Version} -Module $script:TestModule5 -Session $session
    #   
    # Expected Result: should fail
    #   
    TestCase ImportPSSessionWithModuleNameandFullyQualifiedModule -tags @("P1") {
        $Version = "3.0"        
        $session = New-PSSession
        try
        {
            AssertFullyQualifiedErrorIdEquals -scriptblock {Import-PSSession -FullyQualifiedModule @{ModuleName=$script:TestModule5;ModuleVersion=$Version} -Module $script:TestModule5 -Session $session} `
                                              -expectedFullyQualifiedErrorId "ModuleAndFullyQualifiedModuleCannotBeSpecifiedTogether,Microsoft.PowerShell.Commands.ImportPSSessionCommand"
        }
        finally
        {
            Remove-PSSession $session
        }
    }

    
    # Purpose: Validate Import-PSSession with ModuleName
    #
    # Action: Import-PSSession -Module $script:TestModule5 -Session $session
    #   
    # Expected Result: Import the module from the session
    #   
    TestCase ImportPSSessionWithModuleName -tags @("P1") {
        $session = New-PSSession
        try
        {
            $res = Import-PSSession -Module $script:TestModule5 -Session $session
            $res | Remove-Module -Force
            RemoveItem $res.ModuleBase
            AssertNotNull $res "Import-PSSession should Import the module from the session"
        }
        finally
        {
            Remove-PSSession $session
        }
    }

    # Purpose: Validate Import-PSSession with ModuleVersion in FullyQualifiedModule
    #
    # Action: Import-PSSession -FullyQualifiedModule @{ModuleName=$script:TestModule5;ModuleVersion=$Version} -Session $session
    #   
    # Expected Result: Import the module from the session
    #   
    TestCase ImportPSSessionWithFullyQualifiedModule -tags @("BVT") {
        $Version = "2.0"
        $session = New-PSSession
        Invoke-Command -Session $session {param($moduleName, $moduleVersion) Import-Module -FullyQualifiedName @{ModuleName=$moduleName;ModuleVersion=$moduleVersion}} -ArgumentList $script:TestModule5,$Version
        try
        {
            $res = Import-PSSession -FullyQualifiedModule @{ModuleName=$script:TestModule5;ModuleVersion=$Version;MaximumVersion="7.0"} -Session $session
            
            if($res)
            {
                $res | Remove-Module -Force
                RemoveItem $res.ModuleBase
            }
            AssertNotNull $res "Import-PSSession should Import the module from the session"
        }
        finally
        {
            Remove-PSSession $session
        }
    }

    # Purpose: Validate Import-PSSession with RequiredVersion in FullyQualifiedModule
    #
    # Action: Import-PSSession -FullyQualifiedModule @{ModuleName=$script:TestModule5;RequiredVersion=$Version} -Session $session
    #   
    # Expected Result: Import the module from the session
    #   
    TestCase ImportPSSessionWithReqVersionInFullyQualifiedModule -tags @("BVT") {
        $Version = "2.0"
        $session = New-PSSession
        Invoke-Command -Session $session {param($moduleName, $moduleVersion) Import-Module -FullyQualifiedName @{ModuleName=$moduleName;RequiredVersion=$moduleVersion}} -ArgumentList $script:TestModule5,$Version
        try
        {
            $res = Import-PSSession -FullyQualifiedModule @{ModuleName=$script:TestModule5;RequiredVersion=$Version} -Session $session
            
            if($res)
            {
                $res | Remove-Module -Force
                RemoveItem $res.ModuleBase
            }
            AssertNotNull $res "Import-PSSession should Import the module from the session"
        }
        finally
        {
            Remove-PSSession $session
        }
    }

    # Purpose: Validate New-PSSessionConfigurationFile with ModuleVersion in ModuleSpecification
    #
    # Action: register a session configuration with PSSessionConfiguration file where modulestoimport is specified as ModuleSpecification
    #   
    # Expected Result: The specified module in ModulesToImport should be imported in the session
    #   
    TestCase NewPSSessionConfigurationFileWithModuleSpec -tags @("P1") {
        $version = "2.0"
        $sessionConfigName = "SessionConfig_$(Get-Random)"
        $SessionConfigPath = Join-Path $env:Temp "$sessionConfigName.pssc"
        $session = $null
        try
        {
            New-PSSessionConfigurationFile -Path $SessionConfigPath -ModulesToImport @{modulename=$script:TestModule5;ModuleVersion=$version}
            Register-PSSessionConfiguration -Path $SessionConfigPath -Name $sessionConfigName -Force
            $session = New-PSSession -ConfigurationName $sessionConfigName

            $res = Invoke-Command $session {Get-Module $using:TestModule5}
            AssertEquals $res.Name $script:TestModule5 "ModulesToImport in session config file is not working, $res"
            AssertEquals $res.Version "5.0" "ModulesToImport in session config is not working, $res"
        }
        finally
        {
            if($session)
            {
                Remove-PSSession $session -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }

            Get-PSSessionConfiguration -Name $sessionConfigName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | 
                Unregister-PSSessionConfiguration -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

            RemoveItem $SessionConfigPath
        }
    }

    # Purpose: Validate New-PSSessionConfigurationFile with RequiredVersion in ModuleSpecification
    #
    # Action: register a session configuration with PSSessionConfiguration file where modulestoimport is specified as ModuleSpecification
    #   
    # Expected Result: The specified module in ModulesToImport should be imported in the session
    #   
    TestCase NewPSSessionConfigurationFileWithReqVersionInModuleSpec -tags @("P1") {
        $version = "2.0"
        $sessionConfigName = "SessionConfig_$(Get-Random)"
        $SessionConfigPath = Join-Path $env:Temp "$sessionConfigName.pssc"
        $session = $null

        try
        {
            New-PSSessionConfigurationFile -Path $SessionConfigPath -ModulesToImport @{modulename=$script:TestModule5;RequiredVersion=$version}
            Register-PSSessionConfiguration -Path $SessionConfigPath -Name $sessionConfigName -Force

            $session = New-PSSession -ConfigurationName $sessionConfigName

            $res = Invoke-Command $session {Get-Module $using:TestModule5}
            AssertEquals $res.Name $script:TestModule5 "ModulesToImport in session config file is not working, $res"
            AssertEquals $res.Version $version "ModulesToImport in session config file is not working, $res"
        }
        finally
        {
            if($session)
            {
                Remove-PSSession $session -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }

            Get-PSSessionConfiguration -Name $sessionConfigName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | 
                Unregister-PSSessionConfiguration -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

            RemoveItem $SessionConfigPath
        }
    }

    # Purpose: Validate Register-PSSessionConfiguration cmdlet with ModuleVersion in ModuleSpecification specified as ModulesToImport
    #
    # Action: register a session configuration with Modulestoimport is specified as ModuleSpecification
    #   
    # Expected Result: The specified module in ModulesToImport should be imported in the session
    #   
    TestCase RegisterPSSessionConfigurationWithModuleVersionInModuleSpec -tags @("P1") {
        $version = "3.0"
        $sessionConfigName = "SessionConfig_$(Get-Random)"
        $session = $null

        try
        {
            Register-PSSessionConfiguration -Name $sessionConfigName -Force -ModulesToImport @{modulename=$script:TestModule5;ModuleVersion=$version}

            $session = New-PSSession -ConfigurationName $sessionConfigName

            $res = Invoke-Command $session {Get-Module $using:TestModule5}
            AssertEquals $res.Name $script:TestModule5 "ModulesToImport in session config is not working, $res"
            AssertEquals $res.Version "5.0" "ModulesToImport in session config is not working, $res"
        }
        finally
        {
            if($session)
            {
                Remove-PSSession $session -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }

            Get-PSSessionConfiguration -Name $sessionConfigName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | 
                Unregister-PSSessionConfiguration -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
    }

    # Purpose: Validate Register-PSSessionConfiguration cmdlet with maximumVersion in ModuleSpecification specified as ModulesToImport
    #
    # Action: register a session configuration with Modulestoimport is specified as ModuleSpecification
    #   
    # Expected Result: The specified module in ModulesToImport should be imported in the session
    #   
    TestCase RegisterPSSessionConfigurationWithMaximumVersionInModuleSpec -tags @("P1") {
        $version = "5.0"
        $sessionConfigName = "SessionConfig_$(Get-Random)"
        $session = $null

        try
        {
            Register-PSSessionConfiguration -Name $sessionConfigName -Force -ModulesToImport @{modulename=$script:TestModule5;maximumVersion=$version}

            $session = New-PSSession -ConfigurationName $sessionConfigName

            $res = Invoke-Command $session {Get-Module $using:TestModule5}
            AssertEquals $res.Name $script:TestModule5 "ModulesToImport in session config is not working, $res"
            AssertEquals $res.Version "5.0" "ModulesToImport in session config is not working, $res"
        }
        finally
        {
            if($session)
            {
                Remove-PSSession $session -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }

            Get-PSSessionConfiguration -Name $sessionConfigName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | 
                Unregister-PSSessionConfiguration -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
    }

    # Purpose: Validate Register-PSSessionConfiguration cmdlet with MinimumVersion and MaximumVersion equals to each other in ModuleSpecification specified as ModulesToImport
    #
    # Action: register a session configuration with Modulestoimport is specified as ModuleSpecification
    #   
    # Expected Result: The specified module in ModulesToImport should be imported in the session
    #   
    TestCase RegisterPSSessionConfigurationWithMinimumVersionEqualstoMaximumVersionInModuleSpec -tags @("P1") {
        $version = "5.0"
        $sessionConfigName = "SessionConfig_$(Get-Random)"
        $session = $null

        try
        {
            Register-PSSessionConfiguration -Name $sessionConfigName -Force -ModulesToImport @{modulename=$script:TestModule5; ModuleVersion=$version}

            $session = New-PSSession -ConfigurationName $sessionConfigName

            $res = Invoke-Command $session {Get-Module $using:TestModule5}
            AssertEquals $res.Name $script:TestModule5 "ModulesToImport in session config is not working, $res"
            AssertEquals $res.Version $version "ModulesToImport in session config is not working, $res"
        }
        finally
        {
            if($session)
            {
                Remove-PSSession $session -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }

            Get-PSSessionConfiguration -Name $sessionConfigName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | 
                Unregister-PSSessionConfiguration -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
    }

    # Purpose: Validate Register-PSSessionConfiguration cmdlet with RequiredVersion in ModuleSpecification specified as ModulesToImport
    #
    # Action: register a session configuration with Modulestoimport is specified as ModuleSpecification
    #   
    # Expected Result: The specified module in ModulesToImport should be imported in the session
    #   
    TestCase RegisterPSSessionConfigurationWithRequiredVersionInModuleSpec -tags @("P1") {
        $version = "3.0"
        $sessionConfigName = "SessionConfig_$(Get-Random)"
        $session = $null

        try
        {
            Register-PSSessionConfiguration -Name $sessionConfigName -Force -ModulesToImport @{modulename=$script:TestModule5;RequiredVersion=$version}

            $session = New-PSSession -ConfigurationName $sessionConfigName

            $res = Invoke-Command $session {Get-Module $using:TestModule5}
            AssertEquals $res.Name $script:TestModule5 "ModulesToImport in session config is not working, $res"
            AssertEquals $res.Version $version "ModulesToImport in session config is not working, $res"
        }
        finally
        {
            if($session)
            {
                Remove-PSSession $session -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }

            Get-PSSessionConfiguration -Name $sessionConfigName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | 
                Unregister-PSSessionConfiguration -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
    }

    # Purpose: Validate Register-PSSessionConfiguration cmdlet with path to a module is specified as ModulesToImport
    #
    # Action: register a session configuration with Modulestoimport is specified with Module folder path
    #   
    # Expected Result: The specified module in ModulesToImport should be imported in the session
    #   
    TestCase RegisterPSSessionConfigurationWithModuleFolderPathInModulesToImport -tags @("P1") {
        $version = "5.0"
        $sessionConfigName = "SessionConfig_$(Get-Random)"
        $session = $null

        try
        {
            Register-PSSessionConfiguration -Name $sessionConfigName -Force -ModulesToImport "$script:ProgramFilesModulesPath\$script:TestModule5"

            $session = New-PSSession -ConfigurationName $sessionConfigName

            $res = Invoke-Command $session {Get-Module $using:TestModule5}
            AssertEquals $res.Name $script:TestModule5 "ModulesToImport in session config is not working, $res"
            AssertEquals $res.Version $version "ModulesToImport in session config is not working, $res"
        }
        finally
        {
            if($session)
            {
                Remove-PSSession $session -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }

            Get-PSSessionConfiguration -Name $sessionConfigName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | 
                Unregister-PSSessionConfiguration -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
    }

    # Purpose: Validate Register-PSSessionConfiguration cmdlet with path to a module manifest is specified as ModulesToImport
    #
    # Action: register a session configuration with Modulestoimport is specified with Module manifest full path
    #   
    # Expected Result: The specified module in ModulesToImport should be imported in the session
    #   
    TestCase RegisterPSSessionConfigurationWithModuleFilePathInModulesToImport -tags @("P1") {
        $version = "1.0"
        $sessionConfigName = "SessionConfig_$(Get-Random)"
        $session = $null

        try
        {
            Register-PSSessionConfiguration -Name $sessionConfigName -Force -ModulesToImport "$script:ProgramFilesModulesPath\$script:TestModule5\$script:TestModule5.psd1"

            $session = New-PSSession -ConfigurationName $sessionConfigName

            $res = Invoke-Command $session {Get-Module $using:TestModule5}
            AssertEquals $res.Name $script:TestModule5 "ModulesToImport in session config is not working, $res"
            AssertEquals $res.Version $version "ModulesToImport in session config is not working, $res"
        }
        finally
        {
            if($session)
            {
                Remove-PSSession $session -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }

            Get-PSSessionConfiguration -Name $sessionConfigName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | 
                Unregister-PSSessionConfiguration -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
    }


    # Purpose: Validate Register-PSSessionConfiguration cmdlet with module name specified as ModulesToImport
    #
    # Action: register a session configuration with Modulestoimport is specified with just module name
    #   
    # Expected Result: The specified module in ModulesToImport should be imported in the session
    #   
    TestCase RegisterPSSessionConfigurationWithModuleNameInModulesToImport -tags @("P1") {
        $version = "5.0"
        $sessionConfigName = "SessionConfig_$(Get-Random)"
        $session = $null

        try
        {
            Register-PSSessionConfiguration -Name $sessionConfigName -Force -ModulesToImport $script:TestModule5
        
            $session = New-PSSession -ConfigurationName $sessionConfigName

            $res = Invoke-Command $session {Get-Module $using:TestModule5}
            AssertEquals $res.Name $script:TestModule5 "ModulesToImport in session config is not working, $res"
            AssertEquals $res.Version $version "ModulesToImport in session config is not working, $res"
        }
        finally
        {
            if($session)
            {
                Remove-PSSession $session -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }

            Get-PSSessionConfiguration -Name $sessionConfigName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | 
                Unregister-PSSessionConfiguration -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
    }


    # Purpose: Validate Register-PSSessionConfiguration cmdlet with multiple objects in ModulesToImport
    #
    # Action: register a session configuration with multiple objects in ModulesToImport
    #   
    # Expected Result: The specified modules in ModulesToImport should be imported in the session
    #   
    TestCase RegisterPSSessionConfigurationWithMultipleModulesInModulesToImport -tags @("P1") {
        $version = "3.0"
        $sessionConfigName = "SessionConfig_$(Get-Random)"
        $session = $null

        try
        {
            Register-PSSessionConfiguration -Name $sessionConfigName -Force -ModulesToImport @{modulename=$script:TestModule1;RequiredVersion=$version},"$script:ProgramFilesModulesPath\$script:TestModule5",$script:TestModule4,"$script:MyDocumentsModulesPath\$script:TestModule2\$script:TestModule2.psd1"

            $session = New-PSSession -ConfigurationName $sessionConfigName

            $res = Invoke-Command $session {Get-Module}
            Assert ($res.Count -ge 3) "ModulesToImport in session config is not working with multiple modules, $res"
        }
        finally
        {
            if($session)
            {
                Remove-PSSession $session -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }

            Get-PSSessionConfiguration -Name $sessionConfigName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | 
                Unregister-PSSessionConfiguration -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
    }

    # Purpose: Validate Set-PSSessionConfiguration cmdlet with ModuleVersion in ModuleSpecification specified as ModulesToImport
    #
    # Action: set a session configuration with Modulestoimport is specified as ModuleSpecification
    #   
    # Expected Result: The specified module in ModulesToImport should be imported in the session
    #   
    TestCase SetPSSessionConfigurationWithModuleVersionInModuleSpec -tags @("P1") {
        $version = "3.0"
        $sessionConfigName = "SessionConfig_$(Get-Random)"
        $session = $null

        try
        {
            Register-PSSessionConfiguration -Name $sessionConfigName -Force
            Set-PSSessionConfiguration -Name $sessionConfigName -Force -ModulesToImport @{modulename=$script:TestModule5;ModuleVersion=$version}
            $session = New-PSSession -ConfigurationName $sessionConfigName

            $res = Invoke-Command $session {Get-Module $using:TestModule5}
            AssertEquals $res.Name $script:TestModule5 "ModulesToImport in session config is not working, $res"
            AssertEquals $res.Version "5.0" "ModulesToImport in session config is not working, $res"
        }
        finally
        {
            if($session)
            {
                Remove-PSSession $session -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }

            Get-PSSessionConfiguration -Name $sessionConfigName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | 
                Unregister-PSSessionConfiguration -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
    }

    # Purpose: Validate Set-PSSessionConfiguration cmdlet with RequiredVersion in ModuleSpecification specified as ModulesToImport
    #
    # Action: Set a session configuration with Modulestoimport is specified as ModuleSpecification
    #   
    # Expected Result: The specified module in ModulesToImport should be imported in the session
    #   
    TestCase SetPSSessionConfigurationWithRequiredVersionInModuleSpec -tags @("P1") {
        $version = "3.0"
        $sessionConfigName = "SessionConfig_$(Get-Random)"
        $session = $null

        try
        {
            Register-PSSessionConfiguration -Name $sessionConfigName -Force
            Set-PSSessionConfiguration -Name $sessionConfigName -Force -ModulesToImport @{modulename=$script:TestModule5;RequiredVersion=$version}
            $session = New-PSSession -ConfigurationName $sessionConfigName

            $res = Invoke-Command $session {Get-Module $using:TestModule5}
            AssertEquals $res.Name $script:TestModule5 "ModulesToImport in session config is not working, $res"
            AssertEquals $res.Version $version "ModulesToImport in session config is not working, $res"
        }
        finally
        {
            if($session)
            {
                Remove-PSSession $session -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }

            Get-PSSessionConfiguration -Name $sessionConfigName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | 
                Unregister-PSSessionConfiguration -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
    }

    # Purpose: Validate Set-PSSessionConfiguration cmdlet with path to a module is specified as ModulesToImport updates the old value
    #
    # Action: set a session configuration with Modulestoimport is specified with Module folder path
    #   
    # Expected Result: The specified module in ModulesToImport should be imported in the session
    #   
    TestCase SetPSSessionConfigurationWithModuleFolderPathInModulesToImport -tags @("P1") {
        $version = "5.0"
        $sessionConfigName = "SessionConfig_$(Get-Random)"
        $session = $null

        try
        {
            Register-PSSessionConfiguration -Name $sessionConfigName -Force -ModulesToImport "$script:ProgramFilesModulesPath\$script:TestModule5"
            Set-PSSessionConfiguration -Name $sessionConfigName -Force -ModulesToImport "$script:ProgramFilesModulesPath\$script:TestModule1"
            $session = New-PSSession -ConfigurationName $sessionConfigName

            $res = Invoke-Command $session {Get-Module $using:TestModule1}
            AssertEquals $res.Name $script:TestModule1 "ModulesToImport in session config is not working, $res"
            AssertEquals $res.Version $version "ModulesToImport in session config is not working, $res"
        }
        finally
        {
            if($session)
            {
                Remove-PSSession $session -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }

            Get-PSSessionConfiguration -Name $sessionConfigName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | 
                Unregister-PSSessionConfiguration -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
    }

    # Purpose: Validate Set-PSSessionConfiguration cmdlet with path to a module manifest is specified as ModulesToImport
    #
    # Action: register and set a session configuration with Modulestoimport is specified with Module manifest full path
    #   
    # Expected Result: The specified module in ModulesToImport should be imported in the session
    #   
    TestCase SetPSSessionConfigurationWithModuleFilePathInModulesToImport -tags @("P1") {
        $version = "1.0"
        $sessionConfigName = "SessionConfig_$(Get-Random)"
        $session = $null

        try
        {
            Register-PSSessionConfiguration -Name $sessionConfigName -Force
            Set-PSSessionConfiguration -Name $sessionConfigName -Force -ModulesToImport "$script:ProgramFilesModulesPath\$script:TestModule5\$script:TestModule5.psd1"
            $session = New-PSSession -ConfigurationName $sessionConfigName

            $res = Invoke-Command $session {Get-Module $using:TestModule5}
            AssertEquals $res.Name $script:TestModule5 "ModulesToImport in session config is not working, $res"
            AssertEquals $res.Version $version "ModulesToImport in session config is not working, $res"
        }
        finally
        {
            if($session)
            {
                Remove-PSSession $session -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }

            Get-PSSessionConfiguration -Name $sessionConfigName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | 
                Unregister-PSSessionConfiguration -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
    }


    # Purpose: Validate Set-PSSessionConfiguration cmdlet with module name specified as ModulesToImport
    #
    # Action: register and set a session configuration with Modulestoimport is specified with just module name
    #   
    # Expected Result: The specified module in ModulesToImport should be imported in the session
    #   
    TestCase SetPSSessionConfigurationWithModuleNameInModulesToImport -tags @("P1") {
        $version = "5.0"
        $sessionConfigName = "SessionConfig_$(Get-Random)"
        $session = $null

        try
        {
            Register-PSSessionConfiguration -Name $sessionConfigName -Force
            Set-PSSessionConfiguration -Name $sessionConfigName -Force -ModulesToImport $script:TestModule5
            $session = New-PSSession -ConfigurationName $sessionConfigName

            $res = Invoke-Command $session {Get-Module $using:TestModule5}
            AssertEquals $res.Name $script:TestModule5 "ModulesToImport in session config is not working, $res"
            AssertEquals $res.Version $version "ModulesToImport in session config is not working, $res"
        }
        finally
        {
            if($session)
            {
                Remove-PSSession $session -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }

            Get-PSSessionConfiguration -Name $sessionConfigName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | 
                Unregister-PSSessionConfiguration -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
    }


    # Purpose: Validate Set-PSSessionConfiguration cmdlet with multiple objects in ModulesToImport
    #
    # Action: register and set a session configuration with multiple objects in ModulesToImport
    #   
    # Expected Result: The specified modules in ModulesToImport should be imported in the session
    #   
    TestCase SetPSSessionConfigurationWithMultipleModulesInModulesToImport -tags @("P1") {
        $version = "4.0"
        $sessionConfigName = "SessionConfig_$(Get-Random)"
        $session = $null

        try
        {
            Register-PSSessionConfiguration -Name $sessionConfigName -Force -ModulesToImport @{modulename=$script:TestModule1;RequiredVersion="3.0"},"$script:ProgramFilesModulesPath\$script:TestModule5",$script:TestModule4,"$script:MyDocumentsModulesPath\$script:TestModule2\$script:TestModule2.psd1"
            Set-PSSessionConfiguration -Name $sessionConfigName -Force -ModulesToImport @{modulename=$script:TestModule1;RequiredVersion=$version},"$script:ProgramFilesModulesPath\$script:TestModule5",$script:TestModule4,"$script:MyDocumentsModulesPath\$script:TestModule2\$script:TestModule2.psd1"
            $session = New-PSSession -ConfigurationName $sessionConfigName

            $res = Invoke-Command $session {Get-Module}
            $res2 = Invoke-Command $session {Get-Module $using:TestModule1}

            Assert ($res.Count -ge 3) "ModulesToImport in session config is not working with multiple modules, $res"

            AssertEquals $res2.Name $script:TestModule1 "ModulesToImport in session config is not working, $res2"
            AssertEquals $res2.Version $version "ModulesToImport in session config is not working, $res2"
        }
        finally
        {
            if($session)
            {
                Remove-PSSession $session -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }

            Get-PSSessionConfiguration -Name $sessionConfigName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | 
                Unregister-PSSessionConfiguration -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
    }
}

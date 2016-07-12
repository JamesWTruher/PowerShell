# This is a LITE3 test suite to validate module enhancements.
#
# Copyright (c) Microsoft Corporation, 2014
#

Suite @args Engine.Modules.Enhancements -Definition {

    Include Asserts.psm1

    SuiteSetup {
        $modulesDir = $env:TEMP -split ';' | select -first 1

        $script:tempdir = join-path $modulesDir (Get-Random)
        mkdir $tempdir | Out-Null
                
        $script:moduleManifestPath = Join-Path $script:tempdir "TempModuleManifest_$(Get-Random).psd1"
    }

    SuiteCleanUp{
        Remove-Item $script:tempdir -recurse -force -ea silentlycontinue
    }
    
    <#
    Purpose:
        Validate PowerShellGet related parameters on New-ModuleManifest cmdlet
        
    Action:
        Specify the valid values for Tags, LicenseUri, ProjectUri, IconUri, ReleaseNotes
        
    Expected Result: 
        PSModuleInfo object should have the specified values for Tags, LicenseUri, ProjectUri, IconUri, ReleaseNotes
    #>
    TestCase ValidateNewModuleManifestWithPSGetRelatedParams -Tag @("DRT") {
        $Tags = @('A','B','C')
        $ReleaseNotes = "contoso module release notes"
        $ProjectUri = "http://www.contoso.com/ContosoProject"
        $IconUri = "http://www.contoso.com/ContosoIcon"
        $LicenseUri = "http://www.contoso.com/ContosoLicense"

        New-ModuleManifest -Path $Script:moduleManifestPath `
                           -ReleaseNotes $ReleaseNotes `
                           -Tags $Tags `
                           -ProjectUri $ProjectUri `
                           -IconUri $IconUri `
                           -LicenseUri $LicenseUri

        $psModuleInfo = Test-ModuleManifest -Path $Script:moduleManifestPath

        AssertEquals ($psModuleInfo.Tags -join ' ') ($Tags -join ' ') "Tags value is not expected on PSModuleInfo"
        AssertEquals $psModuleInfo.ReleaseNotes $ReleaseNotes "ReleaseNotes value is not expected on PSModuleInfo"
        AssertEquals $psModuleInfo.ProjectUri $ProjectUri "ProjectUri value is not expected on PSModuleInfo"
        AssertEquals $psModuleInfo.LicenseUri $LicenseUri "LicenseUri value is not expected on PSModuleInfo"
        AssertEquals $psModuleInfo.IconUri $IconUri "IconUri value is not expected on PSModuleInfo"
    }

   <#
    Purpose:
        Validate PowerShellGet related parameters on New-ModuleManifest cmdlet with Uri objects
        
    Action:
        Specify the valid values for Tags, LicenseUri, ProjectUri, IconUri, ReleaseNotes
        
    Expected Result: 
        PSModuleInfo object should have the specified values for Tags, LicenseUri, ProjectUri, IconUri, ReleaseNotes
    #>
    TestCase ValidateNewModuleManifestWithPSGetRelatedParamsWithUriObjects -Tag @("DRT") {
        $Tags = 'A'
        $ReleaseNotes = "contoso module release notes"
        $ProjectUri = New-Object System.Uri "http://www.contoso.com/ContosoProject"
        $IconUri = New-Object System.Uri "http://www.contoso.com/ContosoIcon"
        $LicenseUri = New-Object System.Uri "http://www.contoso.com/ContosoLicense"

        New-ModuleManifest -Path $Script:moduleManifestPath `
                           -ReleaseNotes $ReleaseNotes `
                           -Tags $Tags `
                           -ProjectUri $ProjectUri `
                           -IconUri $IconUri `
                           -LicenseUri $LicenseUri

        $psModuleInfo = Test-ModuleManifest -Path $Script:moduleManifestPath

        AssertEquals ($psModuleInfo.Tags -join ' ') ($Tags -join ' ') "Tags value is not expected on PSModuleInfo"
        AssertEquals $psModuleInfo.ReleaseNotes $ReleaseNotes "ReleaseNotes value is not expected on PSModuleInfo"
        AssertEquals $psModuleInfo.ProjectUri $ProjectUri "ProjectUri value is not expected on PSModuleInfo"
        AssertEquals $psModuleInfo.LicenseUri $LicenseUri "LicenseUri value is not expected on PSModuleInfo"
        AssertEquals $psModuleInfo.IconUri $IconUri "IconUri value is not expected on PSModuleInfo"
    }






    <#
    Purpose:
        Validate ModuleSpecification.TryParse() Public API with valid and invalid values.
        
    Action:
        Specify a ModuleSpecification hashtable valid and invalid strings to the TryParse API.
        
    Expected Result: 
        True for valid input
        False for invalid input
    #>
    TestCase ValidateModuleSpecificationTryParseAPI -Tag @("P1") {
	$moduleSpec1 = $null
	$status1 = [Microsoft.PowerShell.Commands.ModuleSpecification]::TryParse("@{ModuleName='Foo';ModuleVersion='1.0'}", [ref]$moduleSpec1)

	$moduleSpec2 = $null
	$status2 = [Microsoft.PowerShell.Commands.ModuleSpecification]::TryParse("@{ModuleName=calc;ModuleVersion='1.0'}", [ref]$moduleSpec2)
	
	Assert $status1 "ModuleSpecification.TryParse() failed to parse the valid module specification hashtable"
	AssertNotNull $moduleSpec1 "ModuleSpecification.TryParse() failed to parse the valid module specification hashtable"

	Assert (-not $status2) "ModuleSpecification.TryParse() should return false for the invalid module specification hashtable"
	AssertNull $moduleSpec2 "ModuleSpecification.TryParse() should return false for the invalid module specification hashtable"
    }
}

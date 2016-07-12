# This is a LITE3 test suite to validate bug fixes in Modules. 
#
# Copyright (c) Microsoft Corporation, 2014
#

Suite @args Engine.Module.BugFixTests -Definition {

    Include Asserts.psm1
    
    SuiteSetup {
        $modulesDir = $env:TEMP -split ';' | select -first 1

        $script:tempdir = join-path $modulesDir ([IO.Path]::GetRandomFileName())
        mkdir $script:tempdir | Out-Null      
        
    }

    SuiteCleanUp{
    remove-item $script:tempdir -recurse -force -ea silentlycontinue    
    }
    
    ShouldRun {
        return $true
    }   

    <#
    Purpose:
        Validate that module qualified names for functions work when the root module is a binary module
        
    Action:
        Create a module manifest with root module as a binary module and add a function in one of the nested modules. Then, look for the function in the nested module
        
    Expected Result: 
        The function should be returned via Command Discovery
    #>
    TestCase -Name ValidateModuleQualifiedFunctionNamesAreDiscovered -Tag @("P1") {
        
        # Create binary module 
        $content = @"
using System;
using System.Management.Automation;
namespace TestModuleBug623871
{
    [Cmdlet("Test","ModuleBug623871")]
    public class TestModuleBug623871Command : PSCmdlet
    {
        [Parameter]
        public int a { 
            get;
            set;
        }
        protected override void ProcessRecord()
        {
            String s = "Value is :" + a;
            WriteObject(s);
        }
    }
}
"@

        # Create binary module
        $moduleName = "TestModuleBug623871"

        mkdir  $script:tempdir\$moduleName -force > $null

        $outputAssembly = " $script:tempdir\$moduleName\$moduleName.dll"

        add-type -TypeDefinition $content -OutputAssembly $outputAssembly -OutputType Library  

        # Create script module
        '
        function Get-TestModule
        {
            [CmdletBinding()]
            Param ()
        }
        ' | Set-Content (Join-Path $script:tempdir\$moduleName "$moduleName.psm1")

        ## Create the manifest
        New-ModuleManifest -Path (Join-Path  $script:tempdir\$moduleName "$moduleName.psd1") `
                           -RootModule "TestModuleBug623871.dll" `
                           -ModuleVersion "1.0.0.0" `
                           -NestedModules "TestModuleBug623871.psm1"

        $oldPsModulePath = $env:PSModulePath
        $env:PSModulePath = "$oldPsModulePath;$script:tempdir"
        
        try
        {
            $result = Get-Command TestModuleBug623871\Get-TestModule
            AssertEquals $result.Name Get-TestModule "Get-Command should return the function Get-TestModule"
        }
        finally
        {
            $env:PSModulePath = $oldPsModulePath
        }
    } -cleanup {
        Get-Module TestModuleBug623871 | Remove-Module > $null
        Remove-Item $script:tempdir\TestModuleBug623871 -Recurse -Force -ErrorAction SilentlyContinue  
    } -ShouldRun {
        if ($env:PROCESSOR_ARCHITECTURE -eq "arm")
        {
            write-host "skipping test for arm machine"
            return $false
        }
    }


    <#
    Purpose:
        Validate that Get-Module lists the modules available under custom modules paths from a Cim Session
        
    Action:
        Create modules under two different module paths and add these two paths to PSModulePath environment variable 
        Create a Cim Session and use it in listing the modules with Get-Module cmdlet
        
    Expected Result: 
        The specified module should be returned from the Cim Session
    #>
    TestCase -Name ValidateGetModuleListAvailableWithCimSessionAndCustomModulePaths -Tag @("P1") {
        # Save the original user PSModulePath
        $OriginalUserPSModulePath = [environment]::GetEnvironmentVariable('PSModulePath', 'User')
  
        # Create two modules
        $TempModulesPath1 = "$script:tempdir\TempModulePath1_$(Get-Random)"
        $TempModulesPath2 = "$script:tempdir\TempModulePath2_$(Get-Random)"

        $null = New-Item $TempModulesPath1 -Force -ItemType Directory
        $null = New-Item $TempModulesPath2 -Force -ItemType Directory
        
        $ModuleName1 = "Module1_$(Get-Random)"
        $ModuleName2 = "Module2_$(Get-Random)"
    
        New-Item "$TempModulesPath1\$ModuleName1" -Force -ItemType Directory
        New-ModuleManifest -Path "$TempModulesPath1\$ModuleName1\$ModuleName1.psd1"

        New-Item "$TempModulesPath2\$ModuleName2" -Force -ItemType Directory
        New-ModuleManifest -Path "$TempModulesPath1\$ModuleName1\$ModuleName2.psd1"

        # Set the user PSModulePath to the new module paths, ";;;;" is also added to test empty paths in PSModulePath
        [environment]::SetEnvironmentVariable('PSModulePath', "$TempModulesPath1;$TempModulesPath2;;;;", 'User')

        $cimSession = New-CimSession
        $modules1 = Get-Module -ListAvailable -CimSession $cimSession -Name $ModuleName1
        $modules2 = Get-Module -ListAvailable -CimSession $cimSession -Name $ModuleName2

        # Restore the User PSModulePath
        [environment]::SetEnvironmentVariable('PSModulePath', $OriginalUserPSModulePath, 'User');

        Remove-CimSession $cimSession
        Remove-Item -Path $TempModulesPath1 -Recurse -Force
        Remove-Item -Path $TempModulesPath2 -Recurse -Force

        AssertEquals $modules1.Count 1 "Get-Module should list single module from Cim Session when custom module path is added to PSModulePath"
        AssertEquals $modules1[0].Name $ModuleName1 "Get-Module should list the $ModuleName1 module from Cim Session when custom module path is added to PSModulePath"

        AssertEquals $modules2.Count 1 "Get-Module should list single module from Cim Session when custom module path is added to PSModulePath"
        AssertEquals $modules2[0].Name $ModuleName2 "Get-Module should list the $ModuleName2 module from Cim Session when custom module path is added to PSModulePath"
    }

    <#
    Purpose:
        Validate that Get-Module lists the available modules from the older version of PowerShell
        
    Action:
        Register a configuration with PSVersion as 2.0
        Create a PSSession to this configuration
        Run Get-Module -List with the session
        
    Expected Result: 
        The modules should be returned from the PSSession
    #>
    TestCase -Name ValidateGetModuleListAvailableWithPS20Session -Tag @("P1") {
        $ConfigName = "SessionConfigForGetModuleList"
        $null = Register-PSSessionConfiguration -Name $ConfigName -PSVersion 2.0 -Force
        $session = New-PSSession -ConfigurationName $ConfigName

        $availableModules = $null
        $exception = $null

        try
        {
            $availableModules = Get-Module -ListAvailable -PSSession $session
        }
        catch
        {
            $exception = $_
        }

        Get-PSSession $session.Id  | Remove-PSSession
        Get-PSSessionConfiguration $ConfigName | Unregister-PSSessionConfiguration -Force

        AssertNull $exception "Get-Module -List with -PSSession should return the available modules without any exceptions, $exception"
        Assert ($availableModules -and ($availableModules.Count -gt 0)) "Get-Module -List with -PSSession should return the available modules from PS 2.0 session, $availableModules"
    }

<#
    Purpose:
        Validate that system modules can get imported with a restricted execution policy
        
    Action:
        Set Execution policy to restricted
        Import system modules
                
    Expected Result: 
        The modules should be imported
    #>
    TestCase -Name ValidateImportOfSystemModulesWithRestrictedExecutionPolicy -Tag @("P1") {
        
        $oldExecutionPolicy = Get-ExecutionPolicy

        try
        {
            Set-ExecutionPolicy Restricted -Force
            $modules = @("Microsoft.PowerShell.Management", "Microsoft.PowerShell.Security", "Microsoft.PowerShell.Utility", "Microsoft.PowerShell.Host", "Microsoft.PowerShell.Diagnostics")
            $importedModules = $modules | % {Import-Module -Name $_ -ErrorAction SilentlyContinue -ErrorVariable ev -PassThru; Log $ev}
            AssertEquals $importedModules.count 5 "We should be able to import 5 System modules"
            0..4 | % {
                     AssertEquals $importedModules[$_].Name $modules[$_] "$modules[$_] should have been imported"
                     }
        }
        catch
        {
            $exception = $_
            Log $exception
        }
        finally
        {
            Set-ExecutionPolicy $oldExecutionPolicy -Force -ErrorAction SilentlyContinue -ErrorVariable ev
            Log $ev
        }
        
    }
}
   

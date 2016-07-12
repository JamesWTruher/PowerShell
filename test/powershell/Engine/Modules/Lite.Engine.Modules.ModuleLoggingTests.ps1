# This is a LITE3 test suite to validate module logging. 
#
# Copyright (c) Microsoft Corporation, 2014
#

Suite @args Engine.Module.ModuleLoggingTests -Definition {

    Include Asserts.psm1
    include ModuleLoggingVerifyFunctions.psm1

    SuiteSetup {
        $modulesDir = $env:TEMP -split ';' | select -first 1

        $script:tempdir = join-path $modulesDir ([IO.Path]::GetRandomFileName())
        mkdir $tempdir | Out-Null
        
        $fileName = [io.path]::GetFileName($tempdir)
    }

    SuiteCleanUp{
    remove-item $script:tempdir -recurse -force -ea silentlycontinue
    Get-Module -Name TestModuleLogging | rmo > $null
    Get-Module -Name bug332072 | rmo > $null
    }
    
    ShouldRun {     
        if ($env:PROCESSOR_ARCHITECTURE -eq "arm")
        {
            write-host "skipping test for arm machine"
            return $false
        }
        return $true
    }    

    <#
    Summary :    Called before every test case 
    #>
    TestCaseSetup -definition {        
        CleanAndEnableLog
    }

    <#
    Summary :    Called after every test case 
    #>
    TestCaseCleanup -definition {
        CleanAndEnableLog
    }

    <#
    Purpose:
        Validate that module logging works for binary modules 
        
    Action:
        Turn on module logging for a binary module and then execute a cmdlet from the binary module
        
    Expected Result: 
        Expected event is written
    #>
    TestCase ValidateModuleLoggingWorksForBinaryModules -Tag @("P1") {

    # Create bianry module 
    $content = @"
using System;
using System.Management.Automation;
namespace TestModuleLogging
{
    [Cmdlet("Test","ModuleLogging")]
    public class TestModuleLoggingCommand : PSCmdlet
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

        # Create binary module 1 
        $moduleName = "TestModuleLogging_$(Get-Random)"

        mkdir $tempdir\$moduleName -force > $null

        $outputAssembly = "$tempdir\$moduleName\$moduleName.dll"

        add-type -TypeDefinition $content -OutputAssembly $outputAssembly -OutputType Library  

        
        $m = Import-Module $outputAssembly -PassThru
        Assert ($m -ne $null -and $m.Name -eq $moduleName) "$moduleName module is not imported"
        $m.LogPipeLineExecutionDetails = $true
        
        Test-ModuleLogging -a 20 | Out-Null

        WaitFor { VerifyExpectedEvents "operational" @(0x1007) } -timeoutInMilliseconds 60000 -intervalInMilliseconds 100 -exceptionMessage " events @(0x1007) is expected in Operational"

        $trycount = 0;
        while($trycount -le 60)
        {
            $global:result = Get-WinEvent  Microsoft-Windows-PowerShell/Operational | ?{$_.Id -eq 4103 -and $_.Message.Contains("Test-ModuleLogging") -eq $true}
            if ($result.count -eq 0)
            {
                sleep 1;
                $trycount++;
            }
            else
            {
                break;
            }
        }
        Assert ($global:result.Task -eq 106 -and $global:result.Level -eq 4) "Expecting PipelineDetail event record"
        if ($PSCulture -eq "en-us")
        {
            Assert $global:result.Message.Contains("ParameterBinding(Test-ModuleLogging)") "Expecting parameter binding event record."
        }

    }    

    <#
    Purpose:
        Validate that module logging works for script modules 
        
    Action:
        Turn on module logging for a script module and then execute a function from the script module
        
    Expected Result: 
        Expected event is written
    #>
    TestCase ValidateModuleLoggingWorksForScriptModules -Tag @("P1") {

    # Create script module     

    mkdir $tempdir\bug332072 -force > $null

@"
function Get-Bug332072
{
    param ([int]`$val)

Write-Output `$val | Out-Null
}
"@ | set-content $tempdir\bug332072\bug332072.psm1

        $m = Import-Module $tempdir\bug332072\bug332072.psm1 -PassThru
        Assert ($m -ne $null -and $m.Name -eq "bug332072") "Bug332072 module is not imported"
        $m.LogPipeLineExecutionDetails = $true
        
        Get-Bug332072 -val 20 | Out-Null
        
        WaitFor { VerifyExpectedEvents "operational" @(0x1007) } -timeoutInMilliseconds 60000 -intervalInMilliseconds 100 -exceptionMessage " events @(0x1007) is expected in Operational"

        $global:result = Get-WinEvent  Microsoft-Windows-PowerShell/Operational | ?{$_.Id -eq 4103 -and $_.Message.Contains("Get-Bug332072") -eq $true}
        Assert ($global:result.Task -eq 106 -and $global:result.Level -eq 4) "Expecting PipelineDetail event record"
        if ($PSCulture -eq "en-us")
        {
            Assert $global:result.Message.Contains("ParameterBinding(Get-Bug332072)") "Expecting parameter binding event record."
        }
    }    
}
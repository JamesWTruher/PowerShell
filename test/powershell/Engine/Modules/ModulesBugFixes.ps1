# This is a LITE3 test suite to validate module bugs. 
#
# Copyright (c) Microsoft Corporation, 2014
#

Suite @args ModuleBugFixes -Definition {

    Include Asserts.psm1

    <#
    Purpose:
        Validate that Get-Module -List finds a module under a PSDrive path specified in $env:PSModulePath
        Ref: Blue bug# 628696
        
    Action:
        Create a module under one PSDrive path, specify that path in $env:PSModulePath, then run Get-Module -List
        
    Expected Result: 
        The module under PSDrive path should be listed
    #>
    TestCase GetModuleListAvailableShouldListTheModuleUnderPSDrivePath -Tag @("P1") {

        Get-PSDrive PS -ErrorAction SilentlyContinue |  Remove-PSDrive -ErrorAction SilentlyContinue
        $null = New-PSDrive -Name PS -PSProvider FileSystem -Root $env:TEMP

        $moduleName = "Foo_$(Get-Random)"
        $myModules = "PS:\MyModules_$(Get-Random)"
        $null = New-Item -ItemType Directory -Path "$myModules\$moduleName" -ErrorAction SilentlyContinue
        Set-Content "function foo { 'foo' }" -Path "$myModules\$moduleName\$moduleName.psm1" -Force

        $SavedPSModulePath = $env:PSModulePath
        $env:PSModulePath = (($env:PSModulePath + ';' + $myModules) -split ';' | Get-Unique) -join ';'

        $module = Get-Module -ListAvailable -Name $moduleName

        $env:PSModulePath = $SavedPSModulePath;
        Remove-Item $myModules -Recurse -Force -ErrorAction SilentlyContinue

        AssertEquals $module.Name $moduleName "Get-Module -List should find the module $moduleName under a PSDrive path specified in $env:PSModulePath"
    }
}
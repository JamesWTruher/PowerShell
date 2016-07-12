# This is a LITE3 test suite to validate module enhancements.
#
# Copyright (c) Microsoft Corporation, 2014
#

Suite @args Engine.Modules.AssemblyAnalyzerTests -Definition {

    Include Asserts.psm1

    # This suite only runs on OneCore powershell
    ShouldRun {
        <#
         # TODO:CORECLR - PowerShellModuleAssemblyAnalyzer is not enabled because 'System.Reflection.Metadata.dll' is not in our branch yet.
         #                Will enable this test once 'PowerShellModuleAssemblyAnalyzer' is enabled.
         #
        try
        {
            $null = [System.Runtime.Loader.AssemblyLoadContext]
        }
        catch 
        {
            return $false
        }

        return $true
        #>

        return $false
    }

    <#
    Purpose:
        If the analyzer doesn't need to go to other referenced assemblie when walking through the derivation chain, then we call it a self-contained module assembly.
        The self-contained module assembly "Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.FirstModule.dll" contains the following types:
            TestAnalyzerCommand -- valid cmdlet
            GetAnalyzerCommand  -- valid cmdlet
            RestartAnalyzerCommand -- Invalid cmdlet. Not deriving from PSCmdlet/Cmdlet
            OpenAnalyzerCommand    -- Invalid cmdlet. Not a public type
            CloseAnalyzerCommand   -- Invalid cmdlet. No default public constrcutor
            InvokeAnalyzerCommand  -- Invalid cmdlet. No CmdletAttribute
            AnalyzerBaseCommand    -- Invalid cmdlet. Abstract type
        "Get-Module -List Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.FirstModule.dll" should be able to find the valid cmdlets
        
    Action:
        Call Get-Module to analyze the module assembly
        
    Expected Result: 
        Get-Module should discover two cmdlets: Test-Analyzer, Get-Analyzer
        Get-Module should discover three aliases: taz, tanalyzer, and gaz
    #>
    TestCase AnalyzeSelfContainedModuleAssembly -Tag @("DRT") {
        
        $FirstModulePath = Join-Path -Path $PSScriptRoot -ChildPath "Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.FirstModule.dll"
        if (-not (Test-Path $FirstModulePath))
        {
            ## The assembly should be in the same folder as this ps1 file
            Assert $false "Cannot find assembly 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.FirstModule.dll' in the local directory."
        }

        $FirstModule = Get-Module -ListAvailable $FirstModulePath

        AssertEquals $FirstModule.ExportedCmdlets.Count 2 "Should discover 2 cmdlets from Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.FirstModule.dll"
        AssertNotNull $FirstModule.ExportedCmdlets["Test-Analyzer"] "Should discover Test-Analyzer"
        AssertNotNull $FirstModule.ExportedCmdlets["Get-Analyzer"] "Should discover Get-Analyzer"
        
        AssertEquals $FirstModule.ExportedAliases.Count 3 "Should discover 3 aliases from 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.FirstModule.dll'"
        AssertNotNull $FirstModule.ExportedAliases["taz"] "Should discover alias 'taz'"
        AssertNotNull $FirstModule.ExportedAliases["tanalyzer"] "Should discover alias 'tanalyzer'"
        AssertNotNull $FirstModule.ExportedAliases["gaz"] "Should discover alias 'gaz'"
    }


    <#
    Purpose:
        The assembly 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.SecondModule.dll' is not self-contained. Walking up the derivation chain for types
        in it requires the referenced assembly 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.FirstModule.dll'.
        This time we put 'FirstModule.dll' in the same folder as 'SecondModule.dll'. The local path should be part of the probing path.

        Assembly 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.SecondModule.dll' contains the following types:
            NewAnalyzerCommand -- valid cmdlet
            AnalyzeTextCommand -- valid cmdlet. Derive from 'AnalyzerBaseCommand', which derives from 'PSCmdlet'
            AnalyzeXmlCommand  -- valid cmdlet. Derive from 'AnalyzerBaseCommand', which derives from 'PSCmdlet'
            TestStream1        -- Invalid cmdlet. No 'CmdletAttribute' and not derived from 'Cmdlet/PSCmdlet'
            TestStream2        -- Invalid cmdlet. Has 'CmdletAttribute' but not derived from 'Cmdlet/PSCmdlet'
        "Get-Module -List Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.SecondModule.dll" should be able to find the valid cmdlets
        
    Action:
        Call Get-Module to analyze the module assembly
        
    Expected Result: 
        Get-Module should discover two cmdlets: Test-Analyzer, Analyze-Text, and Analyze-Xml
        Get-Module should discover three aliases: att, atext, and axml
    #>
    TestCase AnalyzeModuleAssemblyThatReferenceToFirstModuleDll_1 -Tag @("DRT") {
    
        $FirstModulePath = Join-Path -Path $PSScriptRoot -ChildPath "Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.FirstModule.dll"
        $SecondModulePath = Join-Path -Path $PSScriptRoot -ChildPath "Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.SecondModule.dll"

        if (-not (Test-Path $FirstModulePath))
        {
            ## The assembly should be in the same folder as this ps1 file
            Assert $false "Cannot find assembly 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.FirstModule.dll' in the local directory."
        }

        if (-not (Test-Path $SecondModulePath))
        {
            ## The assembly should be in the same folder as this ps1 file
            Assert $false "Cannot find assembly 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.SecondModule.dll' in the local directory."
        }

        ##
        ## 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.FirstModule.dll' is referenced by 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.SecondModule.dll',
        ## 'AnalyzeTextCommand' and 'AnalyzeXmlCommand' derives from 'AnalyzerBaseCommand' which is in the former assembly. So the analyzer
        ## needs to find the former assembly in order to successfully process the 'SecondModule.dll'.
        ## In this test case, the 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.FirstModule.dll' is in the same location as 'SecondModule.dll', and powershell
        ## will probe the folder of the 'SecondModule.dll', so the analysis should be successfuly.
        ##
        $SecondModule = Get-Module -ListAvailable $SecondModulePath

        AssertEquals $SecondModule.ExportedCmdlets.Count 3 "Should discover 3 cmdlets from 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.SecondModule.dll'"
        AssertNotNull $SecondModule.ExportedCmdlets["New-Analyzer"] "Should discover New-Analyzer"
        AssertNotNull $SecondModule.ExportedCmdlets["Analyze-Text"] "Should discover Analyze-Text"
        AssertNotNull $SecondModule.ExportedCmdlets["Analyze-Xml"] "Should discover Analyze-Xml"

        AssertEquals $SecondModule.ExportedAliases.Count 3 "Should discover 3 aliases from 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.SecondModule.dll'"
        AssertNotNull $SecondModule.ExportedAliases["att"] "Should discover alias 'att'"
        AssertNotNull $SecondModule.ExportedAliases["atext"] "Should discover alias 'atext'"
        AssertNotNull $SecondModule.ExportedAliases["axml"] "Should discover alias 'axml'"
    }


    <#
    Purpose:
        Walking up the derivation chain for types in assembly 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.SecondModule.dll' requires the referenced 
        assembly 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.FirstModule.dll'.
        This time, we move 'FirstModule.dll' to $PSHome, which is the default assembly probing path.

        Assembly 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.SecondModule.dll' contains the following types:
            NewAnalyzerCommand -- valid cmdlet
            AnalyzeTextCommand -- valid cmdlet. Derive from 'AnalyzerBaseCommand', which derives from 'PSCmdlet'
            AnalyzeXmlCommand  -- valid cmdlet. Derive from 'AnalyzerBaseCommand', which derives from 'PSCmdlet'
            TestStream1        -- Invalid cmdlet. No 'CmdletAttribute' and not derived from 'Cmdlet/PSCmdlet'
            TestStream2        -- Invalid cmdlet. Has 'CmdletAttribute' but not derived from 'Cmdlet/PSCmdlet'
        "Get-Module -List Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.SecondModule.dll" should be able to find the valid cmdlets
        
    Action:
        Call Get-Module to analyze the module assembly
        
    Expected Result: 
        Get-Module should discover two cmdlets: Test-Analyzer, Analyze-Text, and Analyze-Xml
        Get-Module should discover three aliases: att, atext, and axml
    #>
    TestCase AnalyzeModuleAssemblyThatReferenceToFirstModuleDll_2 -Tag @("DRT") {
    
        $FirstModulePath = Join-Path -Path $PSScriptRoot -ChildPath "Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.FirstModule.dll"
        $SecondModulePath = Join-Path -Path $PSScriptRoot -ChildPath "Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.SecondModule.dll"

        if (-not (Test-Path $FirstModulePath))
        {
            ## The assembly should be in the same folder as this ps1 file
            Assert $false "Cannot find assembly 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.FirstModule.dll' in the local directory."
        }

        if (-not (Test-Path $SecondModulePath))
        {
            ## The assembly should be in the same folder as this ps1 file
            Assert $false "Cannot find assembly 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.SecondModule.dll' in the local directory."
        }

        ## Move the 'FirstModule.dll' to $PSHome, which is the default probing location
        Move-Item -Path $FirstModulePath -Destination $PSHOME -Force
        if (!$?)
        {
            Assert $false "Cannot move the assembly 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.FirstModule.dll' to the default probing path '$PSHOME'"
        }

        ## The 'FirstModule.dll' should have been moved to $PSHome.
        if (Test-Path $FirstModulePath)
        {
            Assert $false "The assembly 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.FirstModule.dll' should be moved to '$PSHOME'"
        }

        try
        {
            ##
            ## 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.FirstModule.dll' is referenced by 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.SecondModule.dll',
            ## 'AnalyzeTextCommand' and 'AnalyzeXmlCommand' derives from 'AnalyzerBaseCommand' which is in the former assembly. So the analyzer
            ## needs to find the former assembly in order to successfully process the 'SecondModule.dll'.
            ## In this test case, the 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.FirstModule.dll' is in $PSHome, which is the base location that powershell
            ## will probe. So the analysis should be successfuly.
            ##
            $SecondModule = Get-Module -ListAvailable $SecondModulePath

            AssertEquals $SecondModule.ExportedCmdlets.Count 3 "Should discover 3 cmdlets from 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.SecondModule.dll'"
            AssertNotNull $SecondModule.ExportedCmdlets["New-Analyzer"] "Should discover New-Analyzer"
            AssertNotNull $SecondModule.ExportedCmdlets["Analyze-Text"] "Should discover Analyze-Text"
            AssertNotNull $SecondModule.ExportedCmdlets["Analyze-Xml"] "Should discover Analyze-Xml"

            AssertEquals $SecondModule.ExportedAliases.Count 3 "Should discover 3 aliases from 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.SecondModule.dll'"
            AssertNotNull $SecondModule.ExportedAliases["att"] "Should discover alias 'att'"
            AssertNotNull $SecondModule.ExportedAliases["atext"] "Should discover alias 'atext'"
            AssertNotNull $SecondModule.ExportedAliases["axml"] "Should discover alias 'axml'"
        }
        finally
        {
            $NewFirstModulePath = Join-Path -Path $PSHOME -ChildPath "Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.FirstModule.dll"
            if (Test-Path $NewFirstModulePath)
            {
                Move-Item -Path $NewFirstModulePath -Destination $PSScriptRoot -Force -ErrorAction SilentlyContinue
            }
        }
    }


    <#
    Purpose:
        Assembly 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.InvalidModule.dll' is an invalid module assembly, because it contains
        two cmdlet with the same name. The invalid module assembly cannot be successfully imported, and thus we stop analyzing it when
        we find it's invalid, and assume there is nothing exposed from it.

        "Get-Module -List Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.InvalidModule.dll" should show no exposed cmdlets/Alias
        
    Action:
        Call Get-Module to analyze the module assembly
        
    Expected Result: 
        There should be no exposed cmdlet/alias
    #>
    TestCase AnalyzeInvalidModuleAssembly -Tag @("DRT") {
    
        $InvalidModulePath = Join-Path -Path $PSScriptRoot -ChildPath "Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.InvalidModule.dll"

        if (-not (Test-Path $InvalidModulePath))
        {
            ## The assembly should be in the same folder as this ps1 file
            Assert $false "Cannot find assembly 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.InvalidModule.dll' in the local directory."
        }

        $InvalidModule = Get-Module -ListAvailable $InvalidModulePath

        AssertEquals $InvalidModule.ExportedCmdlets.Count 0 "Should not discover any cmdlets from 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.InvalidModule.dll'"
        AssertEquals $InvalidModule.ExportedAliases.Count 0 "Should not discover any aliases from 'Microsoft.PowerShell.CoreCLR.AssemblyAnalyzer.InvalidModule.dll'"
    }
}
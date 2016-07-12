# This is a LITE3 test suite which replaces the ScriptTestFixture 
# for script tests located under monad\testdata\scripts\ModulesPackages.
#
# Copyright (c) Microsoft Corporation, 2014
#

Suite @args Engine.ModulesAndPackagesScriptTests -Definition {
    Include Asserts.psm1
    Include ..\..\..\tools\RunScript\RunScript.psm1

    SuiteSetup {
        
        # Get the current Directory       
        $script:currentDirectory = $global:scriptRoot
        log -message ""
        log -message "Current directory: $script:currentDirectory"

        $script:testCaseParameter = "$currentDirectory\..\..\..\Win8\powershell\legacy\testdata\scripts\ModulesPackages\.."
        log -message "Test cases parameter: $script:testCaseParameter"

        $script:testCaseDirectory = "$currentDirectory\..\..\..\Win8\powershell\legacy\testdata\scripts\ModulesPackages"
        log -message "Test cases directory: $script:testCaseDirectory"

        $originalPSModulePath = $env:PSModulePath
        Log -message "originalPSModulePath: $($originalPSModulePath)"
        $env:PSModulePath += ";" + (Resolve-Path $script:testCaseDirectory\packages).Path
        
    }
    TestCaseSetUp {
        Log -message "current PSModulePath: $($env:PSModulePath)"
        $env:PSModulePath = $originalPSModulePath
    }

    SuiteCleanUp {
        $env:PSModulePath = $originalPSModulePath      
    }

    # <Test>
     #   <TestType>BVT</TestType>
     #   <summary>Utilize automatic variables PSScriptRoot, MyInvocation</summary>
     # </Test>
     TestCase automaticVariables -tags @("BVT") {
          RunScript  "$testCaseDirectory\automaticVariables.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>BVT</TestType>
     #   <summary>Load a binary module (.dll)</summary>
     # </Test>
     TestCase binaryModule -tags @("BVT") {
          RunScript  "$testCaseDirectory\binaryModule.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>BVT</TestType>
     #   <summary>Load a module manifest with most fields populated</summary>
     # </Test>
     TestCase modManifestAll -tags @("BVT") {
          RunScript  "$testCaseDirectory\modManifestAll.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>BVT</TestType>
     #   <summary>Load, then reload a module with and without force flag</summary>
     # </Test>
     TestCase moduleReload -tags @("BVT") {
          RunScript  "$testCaseDirectory\moduleReload.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>BVT</TestType>
     #   <summary>Load some modules, enumerate them and call exported functions</summary>
     # </Test>
     TestCase modulesEnumerate -tags @("BVT") {
          RunScript  "$testCaseDirectory\modulesEnumerate.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>BVT</TestType>
     #   <summary>Create a module manifest and use with Test-ModuleManifest</summary>
     # </Test>
     TestCase testModuleManifest -tags @("BVT") {
          RunScript  "$testCaseDirectory\testModuleManifest.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>import-Module with -AsCustomObject parameter</summary>
     # </Test>
     TestCase addModuleAsCustomObject -tags @("P1") {
          RunScript  "$testCaseDirectory\addModuleAsCustomObject.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Add a module from a module and access it</summary>
     # </Test>
     TestCase addModuleFromModule -tags @("P1") {
          RunScript  "$testCaseDirectory\addModuleFromModule.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Discover modules available to load</summary>
     # </Test>
     TestCase discoverModules -tags @("P1") {
          RunScript  "$testCaseDirectory\discoverModules.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Export variables, functions, aliases from a module</summary>
     # </Test>
     TestCase exportsMany -tags @("P1") {
          RunScript  "$testCaseDirectory\exportsMany.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Export variables explicitly from a script module</summary>
     # </Test>
     TestCase exportVariableExplicit -tags @("P1") {
          RunScript  "$testCaseDirectory\exportVariableExplicit.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Get-Module -listAvailable with module manifest</summary>
     # </Test>
     TestCase getModuleListAvailable -tags @("P1") {
          RunScript  "$testCaseDirectory\getModuleListAvailable.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Import-Module tests</summary>
     # </Test>
     TestCase importModule -tags @("P1") {
          RunScript  "$testCaseDirectory\importModule.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Load a module manifest specifying a prefix</summary>
     # </Test>
     TestCase importModulePrefix -tags @("P1") {
          RunScript  "$testCaseDirectory\importModulePrefix.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Attempt to load an empty module manifest</summary>
     # </Test>
     TestCase modManifestEmpty -tags @("P1") {
          RunScript  "$testCaseDirectory\modManifestEmpty.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Attempt to load a module manifest with empty hashtable</summary>
     # </Test>
     TestCase modManifestEmptyHash -tags @("P1") {
          RunScript  "$testCaseDirectory\modManifestEmptyHash.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Load a module that has no files</summary>
     # </Test>
     TestCase modManifestEmptyModule -tags @("P1") {
          RunScript  "$testCaseDirectory\modManifestEmptyModule.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Tests for *ToExport fields of module manifest</summary>
     # </Test>
     TestCase modManifestExports -tags @("P1") {
          RunScript  "$testCaseDirectory\modManifestExports.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Load a module manifest with TypesToProcess populated</summary>
     # </Test>
     TestCase modManifestFormats -tags @("P1") {
          RunScript  "$testCaseDirectory\modManifestFormats.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Load a binary module that has cmdlet and provider help. Help is loaded the directory for the current UI culture</summary>
     # </Test>
     TestCase modManifestHelp -tags @("P1") {
          RunScript  "$testCaseDirectory\modManifestHelp.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Create a module manifest that has international characters</summary>
     # </Test>
     TestCase modManifestInternational -tags @("P1") {
          RunScript  "$testCaseDirectory\modManifestInternational.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Tests for the load order of items in a manifest</summary>
     # </Test>
     TestCase modManifestLoadOrder -tags @("P1") {
          RunScript  "$testCaseDirectory\modManifestLoadOrder.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Attempt to load a module manifest with minimum required entries</summary>
     # </Test>
     TestCase modManifestMinimal -tags @("P1") {
          RunScript  "$testCaseDirectory\modManifestMinimal.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Tests for nested modules</summary>
     # </Test>
     TestCase modManifestNested -tags @("P1") {
          RunScript  "$testCaseDirectory\modManifestNested.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Create a module manifest that has private data</summary>
     # </Test>
     TestCase modManifestPrivateData -tags @("P1") {
          RunScript  "$testCaseDirectory\modManifestPrivateData.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Load a module manifest with TypesToProcess and FormatsToProcess populated.
     #            Have the format depend upon a type</summary>
     # </Test>
     TestCase modManifestTypeAndFormat -tags @("P1") {
          RunScript  "$testCaseDirectory\modManifestTypeAndFormat.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Load a module manifest with TypesToProcess populated</summary>
     # </Test>
     TestCase modManifestTypes -tags @("P1") {
          RunScript  "$testCaseDirectory\modManifestTypes.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Verify aliases for module commands</summary>
     # </Test>
     TestCase moduleAliases -tags @("P1") {
          RunScript  "$testCaseDirectory\moduleAliases.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Load module from a package that is a child of another package</summary>
     # </Test>
     TestCase moduleChildPackage -tags @("P1") {
          RunScript  "$testCaseDirectory\moduleChildPackage.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Access global scope from a module</summary>
     # </Test>
     TestCase moduleGlobalScope -tags @("P1") {
          RunScript  "$testCaseDirectory\moduleGlobalScope.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Import module with ImportList parameter</summary>
     # </Test>
     TestCase moduleImportList -tags @("P1") {
          RunScript  "$testCaseDirectory\moduleImportList.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Verify scoping for exported members of modules </summary>
     # </Test>
     TestCase moduleScope -tags @("P1") {
          RunScript  "$testCaseDirectory\moduleScope.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Load a signed module under different execution policies</summary>
     # </Test>
     TestCase moduleSigned -tags @("P1") {
          RunScript  "$testCaseDirectory\moduleSigned.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Load an invalidly signed module under different execution policies</summary>
     # </Test>
     TestCase moduleSignedInvalid -tags @("P1") {
          RunScript  "$testCaseDirectory\moduleSignedInvalid.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Load a signed module whose contents have been modified</summary>
     # </Test>
     TestCase moduleSignedModifiedContent -tags @("P1") {
          RunScript  "$testCaseDirectory\moduleSignedModifiedContent.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Create a script cmdlet inside a module</summary>
     # </Test>
     TestCase modulesScriptCmdlet -tags @("P1") {
          RunScript  "$testCaseDirectory\modulesScriptCmdlet.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Ensure that module visibility semantics are honored</summary>
     # </Test>
     TestCase moduleVisibility -tags @("P1") {
          RunScript  "$testCaseDirectory\moduleVisibility.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Create a transient module with New-Module</summary>
     # </Test>
     TestCase newModule -tags @("P1") {
          RunScript  "$testCaseDirectory\newModule.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Create a module with new-ModuleManifest</summary>
     # </Test>
     TestCase newModuleManifest -tags @("P1") {
          RunScript  "$testCaseDirectory\newModuleManifest.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Verify that the output stream is suppressed, but not the error stream</summary>
     # </Test>
     TestCase OutputAndErrorSuppressed -tags @("P1") {
          RunScript  "$testCaseDirectory\OutputAndErrorSuppressed.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Tests for PSModulePath environment variable</summary>
     # </Test>
     TestCase PSModulePath -tags @("P1") {
          RunScript  "$testCaseDirectory\PSModulePath.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Make a read-only script module</summary>
     # </Test>
     TestCase readonlyModule -tags @("P1") {
          RunScript  "$testCaseDirectory\readonlyModule.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Tests for the method ImportPSModule on InitialSessionState</summary>
     # </Test>
     TestCase sessionStateImportPSModule -tags @("P1") {
          RunScript  "$testCaseDirectory\sessionStateImportPSModule.ps1" $script:testCaseParameter
     }

     # <Test>
     #   <TestType>PriorityOne</TestType>
     #   <summary>Load a module of the same name from both the system and user directories</summary>
     # </Test>
     TestCase userAndSystemDir -tags @("P1") {
          RunScript  "$testCaseDirectory\userAndSystemDir.ps1" $script:testCaseParameter
     }
}

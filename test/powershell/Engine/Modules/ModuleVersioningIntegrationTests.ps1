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
Suite @args -Name PowerShell.Engine.Modules.ModuleVersioningIntegrationTests -definition {

    Include -fileName Asserts.psm1
    Include -fileName ModuleVersioningUtils.psm1





    <#
    Purpose:
     Save-Help should work with multiple module versions
    Action:
     1.Create different versions of module under the module root.
     2.Create a local server which contains the help file of the module
     3.Use Save-Help to save all the module help file to a local location. 
    Expect:
      All related help contens are saved
    #>
    #This test case needs to be finalized after product code complete
    TestCase SaveHelpOnMultipleVersions DEMO {


        $moduleDirectory = $scriptDirectory + "\TestModule"
        log -message "Start local Server"
        Start-Server
        log -message "Save help content to local file location"
        $helpDestination = $scriptDirectory + "\HelpConent" + [guid]::NewGuid().Guid

        Save-Help -Module TestModule -DestinationPath $helpDestination

        log -message "Verify the help content is correctly saved."
        # to be implemented after the design is confirmed.

        Remove-Server
    }

    <#
    Purpose:
     Save-Help should work with specific module version.
    Action:
     1.Create different versions of module under the module root, each version should contains its own unique help file.
     2.Create a local server which contains the help file of the module
     3.Use Save-Help to save specific version's help file to a local location. 
    Expect:
      The related help contens is saved
    #>
    #This test case needs to be finalized after product code complete
    TestCase SaveHelpOnSpecificVersion DEMO {


        $moduleDirectory = $scriptDirectory + "\TestModule"
        log -message "Start local Server"
        Start-Server
        log -message "Save help content to local file location"
        $helpDestination = $scriptDirectory + "\HelpConent" + (Get-Random).ToString()

        Save-Help -Module TestModule -DestinationPath $helpDestination -fullyqualifiedMoule {RequiredVersion="1.0.0.1"}

        log -message "Verify the help content is correctly saved."
        # to be implemented after the design is confirmed.

        Remove-Server
    }

    <#
    Purpose:
     Update-Help should work with multiple module versions
    Action:
     1.Create different versions of module under the module root, each version should contains its own unique help file.
     2.Create a local server which contains the help file of the module
     3.Use Update-Help to update all the module help file of the module 
    Expect:
      All related help contens are updated for the latest version.
    #>
    #This test case needs to be finalized after product code complete
    TestCase UpdateHelpOnMultipleVersions DEMO {


        $moduleDirectory = $scriptDirectory + "\TestModule"
        log -message "Start local Server"
        Start-Server

        log "Update help file of the whole module"
        Update-Help -Module TestModule

        log -message "Verify the help content is correctly updated."
        # to be implemented after the design is confirmed.

        Remove-Server
    }

    <#
    Purpose:
     Update-Help should work with specific module version.
    Action:
     1.Create different versions of module under the module root, each version should contains its own unique help file.
     2.Create a local server which contains the help file of the module
     3.Use Update-Help to update specific version's help file. 
    Expect:
      The related help contens is updated
    #>
    #This test case needs to be finalized after product code complete
    TestCase UpdateHelpOnSpecificVersion DEMO {

        $moduleDirectory = $scriptDirectory + "\TestModule"
        log -message "Start local Server"
        Start-Server

        log "Update help file of the whole module"
        Update-Help -Module TestModule -fullyqualifiedMoule {RequiredVersion="1.0.0.1"}

        log -message "Verify the help content is correctly updated."
        # to be implemented after the design is confirmed.

        Remove-Server
    }
    }

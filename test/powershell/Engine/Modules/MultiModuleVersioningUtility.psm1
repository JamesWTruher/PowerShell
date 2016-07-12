# This module file contains utility that perform Multiple Module Versioning related functions
#
# Copyright (c) 2014 Microsoft Corporation.
#
Include -fileName Asserts.psm1

<#
.Synopsis
   Generate-Modules
.DESCRIPTION
   Generate huge number of modules with different versions. The function can also generate invalid folders among valid ones
.EXAMPLE
   Generate-Modules -number 100 -addNoise $true -outPutPath c:\test
#>
function Generate-Modules
{

    param
    (
        
        # the number of modules the function will generate
        [Int] $number = 10,

        # if set as true, generation will generate some invalid modules
        [Boolean] $addNoise,

        # the module name
        [String] $moduleName = "TestModule",
               
        # the modules output path
        [String] $outPutPath = ".\")

    begin
    {
        Write-Verbose "Start generating $number modules..."
    }
    process
    {
        $initialVersion = "1.0.0"

        $versionBuild = 0

        $modulePath = Join-Path $outPutPath $moduleName

        if (!(Test-Path $modulePath))
        {
            md $modulePath
        }
        else
        {
            Remove-Item $modulePath\*.* -Force -Recurse
        }

        $moduleGuidId = [guid]::NewGuid().Guid

        for ($i = 0; $i -lt $number; $i++)
        {
            if ($addNoise)
            {
                if (Get-Random 2)
                {
                    $folderName = [guid]::NewGuid().Guid
                    $invalidFolder = $modulePath + "\$folderName"
                    md $invalidFolder
                    "function foo {write-verbose invalidFolder}" > ($invalidFolder + '\' + $moduleName + ".psm1")
                }
            }

            #increase the valid version number randomly.
            $versionBuild = $versionBuild + (Get-Random -Minimum 1 -Maximum 3)
            $version = $initialVersion + '.' + $versionBuild
            $versionFolder = $modulePath + "\$version"
            md $versionFolder

            New-ModuleManifest -Path ($versionFolder + '\' + $moduleName + ".psd1") -ModuleVersion $version -Guid $moduleGuidId -RootModule ($moduleName + ".psm1")

            #generate the psm1 file
            $psm1FileContent = "function foo {write-host $version}"
            $psm1FileContent > ($versionFolder + '\' + $moduleName + ".psm1")


        }

        return $version
    }
}


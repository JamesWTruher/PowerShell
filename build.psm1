# Use the .NET Core APIs to determine the current platform; if a runtime
# exception is thrown, we are on FullCLR, not .NET Core.
try {
    $Runtime = [System.Runtime.InteropServices.RuntimeInformation]
    $OSPlatform = [System.Runtime.InteropServices.OSPlatform]

    $IsCore = $true
    $IsLinux = $Runtime::IsOSPlatform($OSPlatform::Linux)
    $IsOSX = $Runtime::IsOSPlatform($OSPlatform::OSX)
    $IsWindows = $Runtime::IsOSPlatform($OSPlatform::Windows)
} catch {
    # If these are already set, then they're read-only and we're done
    try {
        $IsCore = $false
        $IsLinux = $false
        $IsOSX = $false
        $IsWindows = $true
    }
    catch { }
}


function Start-PSBuild {
    [CmdletBinding(DefaultParameterSetName='CoreCLR')]
    param(
        [switch]$NoPath,
        [switch]$Restore,
        [string]$Output,

        [Parameter(ParameterSetName='CoreCLR')]
        [switch]$Publish,

        # These runtimes must match those in project.json
        # We do not use ValidateScript since we want tab completion
        [ValidateSet("ubuntu.14.04-x64",
                     "centos.7.1-x64",
                     "win7-x64",
                     "win81-x64",
                     "win10-x64",
                     "osx.10.11-x64")]
        [Parameter(ParameterSetName='CoreCLR')]
        [string]$Runtime,

        [Parameter(ParameterSetName='FullCLR')]
        [switch]$FullCLR,

        [Parameter(ParameterSetName='FullCLR')]
        [string]$cmakeGenerator = "Visual Studio 14 2015",

        [Parameter(ParameterSetName='FullCLR')]
        [ValidateSet("Debug",
                     "Release")]
        [string]$msbuildConfiguration = "Release"
    )

    # simplify ParameterSetNames
    if ($PSCmdlet.ParameterSetName -eq 'FullCLR') {
        $FullCLR = $true
    }

    if (-not $NoPath) {
        Write-Verbose "Appending probable .NET CLI tool path"
        if ($IsWindows) {
            $env:Path += ";$env:LocalAppData\Microsoft\dotnet"
        } elseif ($IsOSX) {
            $env:PATH += ":/usr/local/share/dotnet"
        }
    }

    if ($IsWindows) {
        # use custom package store - this value is also defined in nuget.config under config/repositoryPath
        # dotnet restore uses this value as the target for installing the assemblies for referenced nuget packages.
        # dotnet build does not currently consume the  config value but will consume env:NUGET_PACKAGES to resolve these dependencies
        $env:NUGET_PACKAGES="$PSScriptRoot\Packages"
    }

    # verify we have all tools in place to do the build
    $precheck = precheck 'dotnet' "Build dependency 'dotnet' not found in PATH! See: https://dotnet.github.io/getting-started/"
    if ($FullCLR) {
        # cmake is needed to build powershell.exe
        $precheck = $precheck -and (precheck 'cmake' 'cmake not found. You can install it from https://chocolatey.org/packages/cmake.portable')

        # msbuild is needed to build powershell.exe
        # msbuild is part of .NET Framework, we can try to get it from well-known location.
        if (-not $NoPath -and -not (Get-Command -Name msbuild -ErrorAction Ignore)) {
            Write-Verbose "Appending probable Visual C++ tools path"
            $env:path += ";${env:SystemRoot}\Microsoft.Net\Framework\v4.0.30319"
        }

        $precheck = $precheck -and (precheck 'msbuild' 'msbuild not found. Install Visual Studio 2015.')
    } elseif ($IsLinux -or $IsOSX) {
        $InstallCommand = if ($IsLinux) {
            'apt-get'
        } elseif ($IsOSX) {
            'brew'
        }

        foreach ($Dependency in 'cmake', 'make', 'g++') {
            $precheck = $precheck -and (precheck $Dependency "Build dependency '$Dependency' not found. Run '$InstallCommand install $Dependency'")
        }
    }

    # Abort if any precheck failed
    if (-not $precheck) {
        return
    }

    # set output options
    $OptionsArguments = @{Publish=$Publish; Output=$Output; FullCLR=$FullCLR; Runtime=$Runtime}
    $script:Options = New-PSOptions @OptionsArguments

    # setup arguments
    $Arguments = @()
    if ($Publish) {
        $Arguments += "publish"
    } else {
        $Arguments += "build"
    }
    if ($Output) {
        $Arguments += "--output", (Join-Path $PSScriptRoot $Output)
    }
    $Arguments += "--configuration", $Options.Configuration
    $Arguments += "--framework", $Options.Framework
    $Arguments += "--runtime", $Options.Runtime

    # handle Restore
    if ($Restore -or -not (Test-Path "$($Options.Top)/project.lock.json")) {
        log "Run dotnet restore"

        $RestoreArguments = @("--verbosity")
        if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {
            $RestoreArguments += "Info"
        } else {
            $RestoreArguments += "Warning"
        }

        $RestoreArguments += "$PSScriptRoot"

        Start-NativeExecution { dotnet restore $RestoreArguments }
    }

    # Build native components
    if ($IsLinux -or $IsOSX) {
        $Ext = if ($IsLinux) {
            "so"
        } elseif ($IsOSX) {
            "dylib"
        }

        $Native = "$PSScriptRoot/src/libpsl-native"
        $Lib = "$($Options.Top)/libpsl-native.$Ext"
        log "Start building $Lib"

        try {
            Push-Location $Native
            cmake -DCMAKE_BUILD_TYPE=Debug .
            make -j
            make test
        } finally {
            Pop-Location
        }

        if (-not (Test-Path $Lib)) {
            throw "Compilation of $Lib failed"
        }
    } elseif ($FullCLR) {
        log "Start building native powershell.exe"

        try {
            Push-Location "$PSScriptRoot\src\powershell-native"

            if ($cmakeGenerator) {
                cmake -G $cmakeGenerator .
            } else {
                cmake .
            }

            Start-NativeExecution { msbuild powershell.vcxproj /p:Configuration=$msbuildConfiguration }

        } finally {
            Pop-Location
        }
    }

    try {
        # Relative paths do not work well if cwd is not changed to project
        Push-Location $Options.Top
        log "Run dotnet $Arguments from $pwd"
        Start-NativeExecution { dotnet $Arguments }
        log "PowerShell output: $($Options.Output)"
    } finally {
        Pop-Location
    }

}


function New-PSOptions {
    [CmdletBinding()]
    param(
        [ValidateSet("Linux", "Debug", "Release")]
        [string]$Configuration,

        [ValidateSet("netcoreapp1.0", "net451")]
        [string]$Framework,

        # These are duplicated from Start-PSBuild
        # We do not use ValidateScript since we want tab completion
        [ValidateSet("",
                     "ubuntu.14.04-x64",
                     "centos.7.1-x64",
                     "win7-x64",
                     "win81-x64",
                     "win10-x64",
                     "osx.10.11-x64")]
        [string]$Runtime,

        [switch]$Publish,
        [string]$Output,

        [switch]$FullCLR
    )

    if ($FullCLR) {
        $Top = "$PSScriptRoot/src/Microsoft.PowerShell.ConsoleHost"
    } else {
        $Top = "$PSScriptRoot/src/powershell"
    }
    Write-Verbose "Top project directory is $Top"

    if (-not $Configuration) {
        $Configuration = if ($IsLinux -or $IsOSX) {
            "Linux"
        } elseif ($IsWindows) {
            "Debug"
        }
        log "Using configuration '$Configuration'"
    }

    if (-not $Framework) {
        $Framework = if ($FullCLR) {
            "net451"
        } else {
            "netcoreapp1.0"
        }
        log "Using framework '$Framework'"
    }

    if (-not $Runtime) {
        $Runtime = dotnet --info | % {
            if ($_ -match "RID") {
                $_ -split "\s+" | Select-Object -Last 1
            }
        }

        if (-not $Runtime) {
            Throw "Could not determine Runtime Identifier, please update dotnet"
        } else {
            log "Using runtime '$Runtime'"
        }
    }

    $Executable = if ($IsLinux -or $IsOSX) {
        "powershell"
    } elseif ($IsWindows) {
        "powershell.exe"
    }

    # Build the Output path
    if ($Output) {
        $Output = Join-Path $PSScriptRoot $Output
    } else {
        $Output = [IO.Path]::Combine($Top, "bin", $Configuration, $Framework)

        # FullCLR only builds a library, so there is no runtime component
        if (-not $FullCLR) {
            $Output = [IO.Path]::Combine($Output, $Runtime)
        }

        # Publish injects the publish directory
        if ($Publish) {
            $Output = [IO.Path]::Combine($Output, "publish")
        }

        $Output = [IO.Path]::Combine($Output, $Executable)
    }

    return @{ Top = $Top;
              Configuration = $Configuration;
              Framework = $Framework;
              Runtime = $Runtime;
              Output = $Output }
}


function Get-PSOutput {
    [CmdletBinding()]param(
        [hashtable]$Options
    )
    if ($Options) {
        return $Options.Output
    } elseif ($script:Options) {
        return $script:Options.Output
    } else {
        return (New-PSOptions).Output
    }
}


function Start-PSPester {
    [CmdletBinding()]param(
        [string]$Flags = '-EnableExit -OutputFile pester-tests.xml -OutputFormat NUnitXml',
        [string]$Tests = "*",
        [ValidateScript({ Test-Path -PathType Container $_})]
        [string]$Directory = "$PSScriptRoot/test/powershell"
    )

    & (Get-PSOutput) -noprofile -c "Invoke-Pester $Flags $Directory/$Tests"
    if ($LASTEXITCODE -ne 0) {
        throw "$LASTEXITCODE Pester tests failed"
    }
}


function Start-PSxUnit {
    [CmdletBinding()]param()
    if ($IsWindows) {
        throw "xUnit tests are only currently supported on Linux / OS X"
    }

    if ($IsOSX) {
        log "Not yet supported on OS X, pretending they passed..."
        return
    }

    $Content = Split-Path -Parent (Get-PSOutput)
    $Arguments = "--configuration", "Linux"
    try {
        Push-Location $PSScriptRoot/test/csharp
        # Path manipulation to obtain test project output directory
        $Output = Join-Path $pwd ((Split-Path -Parent (Get-PSOutput)) -replace (New-PSOptions).Top)
        Write-Host "Output is $Output"

        Start-NativeExecution { dotnet build $Arguments }
        Copy-Item -ErrorAction SilentlyContinue -Recurse -Path $Content/* -Include Modules,libpsl-native* -Destination $Output
        Start-NativeExecution { dotnet test $Arguments }

        if ($LASTEXITCODE -ne 0) {
            throw "$LASTEXITCODE xUnit tests failed"
        }
    } finally {
        Pop-Location
    }
}


function Start-PSBootstrap {
    [CmdletBinding()]param()

    Write-Host "Installing Open PowerShell build dependencies"

    if ($IsLinux) {
        precheck 'curl' "Bootstrap dependency 'curl' not found in PATH, please install!" > $null
        precheck 'apt-get' "Bootstrap dependency 'apt-get' not found in PATH, this only supports Ubuntu 14.04!" > $null

        # Setup LLVM feed
        curl -s http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add -
        echo "deb http://llvm.org/apt/trusty/ llvm-toolchain-trusty-3.6 main" | sudo tee /etc/apt/sources.list.d/llvm.list
        sudo apt-get update -qq

        # Install ours and .NET's dependencies
        sudo apt-get install -y make g++ cmake libc6 libgcc1 libstdc++6 libcurl3 libgssapi-krb5-2 libicu52 liblldb-3.6 liblttng-ust0 libssl1.0.0 libunwind8 libuuid1 zlib1g clang-3.5

        # Install .NET CLI packages
        Remove-Item dotnet*.deb

        wget https://dotnetcli.blob.core.windows.net/dotnet/beta/Installers/Latest/dotnet-host-ubuntu-x64.latest.deb
        sudo dpkg -i dotnet-host-ubuntu-x64.latest.deb

        wget https://dotnetcli.blob.core.windows.net/dotnet/beta/Installers/Latest/dotnet-sharedframework-ubuntu-x64.latest.deb
        sudo dpkg -i dotnet-sharedframework-ubuntu-x64.latest.deb

        wget https://dotnetcli.blob.core.windows.net/dotnet/beta/Installers/Latest/dotnet-sdk-ubuntu-x64.latest.deb
        sudo dpkg -i dotnet-sdk-ubuntu-x64.latest.deb

    } elseif ($IsOSX) {
        precheck 'brew' "Bootstrap dependency 'brew' not found, must install Homebrew! See http://brew.sh/"

        # Install ours and .NET's dependencies
        brew install cmake wget openssl

        # Install .NET CLI packages
        Remove-Item dotnet*.pkg
        wget https://dotnetcli.blob.core.windows.net/dotnet/beta/Installers/Latest/dotnet-dev-osx-x64.latest.pkg
        sudo installer -pkg dotnet-dev-osx-x64.latest.pkg -target /

    } elseif ($IsWindows -And -Not $IsCore) {
        Remove-Item -ErrorAction SilentlyContinue -Recurse -Force ~\AppData\Local\Microsoft\dotnet
        Invoke-WebRequest -Uri https://raw.githubusercontent.com/dotnet/cli/rel/1.0.0/scripts/obtain/install.ps1 -OutFile install.ps1
        ./install.ps1 -Version 1.0.0-rc2-002655

    } else {
        Write-Warning "Start-PSBootstrap cannot be run in Core PowerShell on Windows (need Invoke-WebRequest!)"
    }
}


function Start-PSPackage {
    [CmdletBinding()]param(
        # PowerShell packages use Semantic Versioning http://semver.org/
        [string]$Version,
        # Package iteration version (rarely changed)
        [int]$Iteration = 1,
        # Ubuntu, CentOS, and OS X packages are supported
        [ValidateSet("deb", "osxpkg", "rpm")]
        [string]$Type
    )

    $Description = @"
Open PowerShell on .NET Core
PowerShell is an open-source, cross-platform, scripting language and rich object shell.
Built upon .NET Core, it is also a C# REPL.
"@

    if ($IsWindows) { throw "Building Windows packages is not yet supported!" }

    if (-not (Get-Command "fpm" -ErrorAction SilentlyContinue)) {
        throw "Build dependency 'fpm' not found in PATH! See: https://github.com/jordansissel/fpm"
    }

    $Source = Split-Path -Parent (Get-PSOutput)
    if ((Split-Path -Leaf $Source) -ne "publish") {
        throw "Please Start-PSBuild -Publish with the corresponding runtime for the package"
    }

    # Decide package output type
    if (-not $Type) {
        $Type = if ($IsLinux) { "deb" } elseif ($IsOSX) { "osxpkg" }
        Write-Warning "-Type was not specified, continuing with $Type"
    }

    # Follow the Filesystem Hierarchy Standard for Linux and OS X
    $Destination = if ($IsLinux) {
        "/opt/microsoft/powershell"
    } elseif ($IsOSX) {
        "/usr/local/microsoft/powershell"
    }

    # Destination for symlink to powershell executable
    $Link = if ($IsLinux) {
        "/usr/bin"
    } elseif ($IsOSX) {
        "/usr/local/bin"
    }

    New-Item -Force -ItemType SymbolicLink -Path /tmp/powershell -Target $Destination/powershell >$null
    
    # there is a weired bug in fpm
    # if the target of the powershell symlink exists, `fpm` aborts
    # with a `utime` error on OS X.
    # so we move it to make symlink broken
    $symlink_dest = "$Destination/powershell"
    $hack_dest = "./_fpm_symlink_hack_powershell"
    if ($IsOSX)
    {
        if (Test-Path $symlink_dest)
        {
            Write-Warning "Move $symlink_dest to $hack_dest (fpm utime bug)"
            Move-Item $symlink_dest $hack_dest
        }
    }


    # Change permissions for packaging
    chmod -R go=u $Source /tmp/powershell

    # Use Git tag if not given a version
    if (-not $Version) {
        $Version = (git --git-dir="$PSScriptRoot/.git" describe) -Replace '^v'
    }

    $libunwind = switch ($Type) {
        "deb" { "libunwind8" }
        "rpm" { "libunwind" }
    }

    $libicu = switch ($Type) {
        "deb" { "libicu52" }
        "rpm" { "libicu" }
    }


    $Arguments = @(
        "--force", "--verbose",
        "--name", "powershell",
        "--version", $Version,
        "--iteration", $Iteration,
        "--maintainer", "Andrew Schwartzmeyer <andschwa@microsoft.com>",
        "--vendor", "Microsoft <mageng@microsoft.com>",
        "--url", "https://github.com/PowerShell/PowerShell",
        "--license", "Unlicensed",
        "--description", $Description,
        "--category", "shells",
        "--rpm-os", "linux",
        "--depends", $libunwind,
        "--depends", $libicu,
        "--deb-build-depends", "dotnet",
        "--deb-build-depends", "cmake",
        "--deb-build-depends", "g++",
        "-t", $Type,
        "-s", "dir",
        "$Source/=$Destination/",
        "/tmp/powershell=$Link"
    )

    # Build package
    fpm $Arguments

    if ($IsOSX)
    {
        # this is continuation of a fpm hack for a weired bug
        if (Test-Path $hack_dest)
        {
            Write-Warning "Move $hack_dest to $symlink_dest (fpm utime bug)"
            Move-Item $hack_dest $symlink_dest
        }
    }
}


function Start-DevPSGitHub {
    param(
        [switch]$ZapDisable,
        [string[]]$ArgumentList = '',
        [switch]$LoadProfile,
        [string]$binDir = "$PSScriptRoot\src\Microsoft.PowerShell.ConsoleHost\bin\Debug\net451",
        [switch]$NoNewWindow
    )

    try {
        if ($LoadProfile -eq $false) {
            $ArgumentList = @('-noprofile') + $ArgumentList
        }

        $env:DEVPATH = $binDir
        if ($ZapDisable) {
            $env:COMPLUS_ZapDisable = 1
        }

        if (-not (Test-Path $binDir\powershell.exe.config)) {
            $configContents = @"
<?xml version="1.0" encoding="utf-8" ?>
<configuration>
<runtime>
<developmentMode developerInstallation="true"/>
</runtime>
</configuration>
"@
            $configContents | Out-File -Encoding Ascii $binDir\powershell.exe.config
        }

        # splatting for the win
        $startProcessArgs = @{
            FilePath = "$binDir\powershell.exe"
            ArgumentList = "$ArgumentList"
        }

        if ($NoNewWindow) {
            $startProcessArgs.NoNewWindow = $true
            $startProcessArgs.Wait = $true
        }

        Start-Process @startProcessArgs
    } finally {
        ri env:DEVPATH
        if ($ZapDisable) {
            ri env:COMPLUS_ZapDisable
        }
    }
}


<#
.EXAMPLE Copy-SubmoduleFiles                # copy files FROM submodule TO src/<project> folders
.EXAMPLE Copy-SubmoduleFiles -ToSubmodule   # copy files FROM src/<project> folders TO submodule
#>
function Copy-SubmoduleFiles {

    [CmdletBinding()]
    param(
        [string]$mappingFilePath = "$PSScriptRoot/mapping.json",
        [switch]$ToSubmodule
    )


    if (-not (Test-Path $mappingFilePath)) {
        throw "Mapping file not found in $mappingFilePath"
    }

    $m = cat -Raw $mappingFilePath | ConvertFrom-Json | Convert-PSObjectToHashtable

    # mapping.json assumes the root folder
    Push-Location $PSScriptRoot
    try {
        $m.GetEnumerator() | % {

            if ($ToSubmodule) {
                cp $_.Value $_.Key -Verbose:$Verbose
            } else {
                mkdir (Split-Path $_.Value) -ErrorAction SilentlyContinue > $null
                cp $_.Key $_.Value -Verbose:$Verbose
            }
        }
    } finally {
        Pop-Location
    }
}


<#
.EXAMPLE Create-MappingFile # create mapping.json in the root folder from project.json files
#>
function New-MappingFile {
    param(
        [string]$mappingFilePath = "$PSScriptRoot/mapping.json",
        [switch]$IgnoreCompileFiles,
        [switch]$Ignoreresource
    )

    function Get-MappingPath([string]$project, [string]$path) {
        if ($project -match 'TypeCatalogGen') {
            return Split-Path $path -Leaf
        }

        if ($project -match 'Microsoft.Management.Infrastructure') {
            return Split-Path $path -Leaf
        }

        return ($path -replace '../monad/monad/src/', '')
    }

    $mapping = [ordered]@{}

    # assumes the root folder
    Push-Location $PSScriptRoot
    try {
        $projects = ls .\src\ -Recurse -Depth 2 -Filter 'project.json'
        $projects | % {
            $project = Split-Path $_.FullName
            $json = cat -Raw -Path $_.FullName | ConvertFrom-Json
            if (-not $IgnoreCompileFiles) {
                $json.compileFiles | % {
                    if ($_) {
                        if (-not $_.EndsWith('AssemblyInfo.cs')) {
                            $fullPath = Join-Path $project (Get-MappingPath -project $project -path $_)
                            $mapping[$_.Replace('../', 'src/')] = ($fullPath.Replace("$($pwd.Path)\",'')).Replace('\', '/')
                        }
                    }
                }
            }

            if ((-not $Ignoreresource) -and ($json.resource)) {
                $json.resource | % {
                    if ($_) {
                        ls $_.Replace('../', 'src/') | % {
                            $fullPath = Join-Path $project (Join-Path 'resources' $_.Name)
                            $mapping[$_.FullName.Replace("$($pwd.Path)\", '').Replace('\', '/')] = ($fullPath.Replace("$($pwd.Path)\",'')).Replace('\', '/')
                        }
                    }
                }
            }
        }
    } finally {
        Pop-Location
    }

    Set-Content -Value ($mapping | ConvertTo-Json) -Path $mappingFilePath -Encoding Ascii
}


<#
.EXAMPLE Send-GitDiffToSd -diffArg1 45555786714d656bd31cbce67dbccb89c433b9cb -diffArg2 45555786714d656bd31cbce67dbccb89c433b9cb~1 -pathToAdmin d:\e\ps_dev\admin
Apply a signle commit to admin folder
#>
function Send-GitDiffToSd {
    param(
        [Parameter(Mandatory)]
        [string]$diffArg1,
        [Parameter(Mandatory)]
        [string]$diffArg2,
        [Parameter(Mandatory)]
        [string]$pathToAdmin,
        [string]$mappingFilePath = "$PSScriptRoot/mapping.json",
        [switch]$WhatIf
    )

    $patchPath = Join-Path (get-command git).Source ..\..\bin\patch
    $m = cat -Raw $mappingFilePath | ConvertFrom-Json | Convert-PSObjectToHashtable
    $affectedFiles = git diff --name-only $diffArg1 $diffArg2
    $rev = Get-InvertedOrderedMap $m
    foreach ($file in $affectedFiles) {
        if ($rev.Contains) {
            $sdFilePath = Join-Path $pathToAdmin $rev[$file].Substring('src/monad/'.Length)
            $diff = git diff $diffArg1 $diffArg2 -- $file
            if ($diff) {
                Write-Host -Foreground Green "Apply patch to $sdFilePath"
                Set-Content -Value $diff -Path $env:TEMP\diff -Encoding Ascii
                if ($WhatIf) {
                    Write-Host -Foreground Green "Patch content"
                    cat $env:TEMP\diff
                } else {
                    & $patchPath --binary -p1 $sdFilePath $env:TEMP\diff
                }
            } else {
                Write-Host -Foreground Green "No changes in $file"
            }
        } else {
            Write-Host -Foreground Green "Ignore changes in $file, because there is no mapping for it"
        }
    }
}

function Start-ResGen
{
    @("Microsoft.PowerShell.Commands.Management",
"Microsoft.PowerShell.Commands.Utility",
"Microsoft.PowerShell.ConsoleHost",
"Microsoft.PowerShell.CoreCLR.Eventing",
"Microsoft.PowerShell.Security",
"System.Management.Automation") | % {
        $module = $_
        ls "$PSScriptRoot/src/$module/resources" | % {
            $className = $_.Name.Replace('.resx', '')
            $xml = [xml](cat -raw $_.FullName)
            $genSource = Get-StronglyTypeCsFileForResx -xml $xml -ModuleName $module -ClassName $className
            $outPath = "$PSScriptRoot/src/windows-build/gen/$module/$className.cs"
            log "ResGen for $outPath"
            mkdir -ErrorAction SilentlyContinue (Split-Path $outPath) > $null
            Set-Content -Encoding Ascii -Path $outPath -Value $genSource
        }
    }
}


function script:log([string]$message) {
    Write-Host -Foreground Green $message
}


function script:precheck([string]$command, [string]$missedMessage) {
    $c = Get-Command $command -ErrorAction SilentlyContinue
    if (-not $c) {
        Write-Warning $missedMessage
        return $false
    } else {
        return $true
    }
}


function script:Get-InvertedOrderedMap {
    param(
        $h
    )
    $res = [ordered]@{}
    foreach ($q in $h.GetEnumerator()) {
        if ($res.Contains($q.Value)) {
            throw "Cannot invert hashtable: duplicated key $($q.Value)"
        }

        $res[$q.Value] = $q.Key
    }
    return $res
}


## this function is from Dave Wyatt's answer on
## http://stackoverflow.com/questions/22002748/hashtables-from-convertfrom-json-have-different-type-from-powershells-built-in-h
function script:Convert-PSObjectToHashtable {
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process {
        if ($null -eq $InputObject) { return $null }

        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) { Convert-PSObjectToHashtable $object }
            )

            Write-Output -NoEnumerate $collection
        } elseif ($InputObject -is [psobject]) {
            $hash = @{}

            foreach ($property in $InputObject.PSObject.Properties)
            {
                $hash[$property.Name] = Convert-PSObjectToHashtable $property.Value
            }

            $hash
        } else {
            $InputObject
        }
    }
}

# this function wraps native command Execution
# for more information, read https://mnaoumov.wordpress.com/2015/01/11/execution-of-external-commands-in-powershell-done-right/
function script:Start-NativeExecution([scriptblock]$sb)
{
    $backupEAP = $script:ErrorActionPreference
    $script:ErrorActionPreference = "Continue"
    try
    {
        & $sb
        # note, if $sb doens't have a native invokation, $LASTEXITCODE will
        # point to the obsolete value
        if ($LASTEXITCODE -ne 0)
        {
            throw "Execution of {$sb} failed with exit code $LASTEXITCODE"
        }
    }
    finally
    {
        $script:ErrorActionPreference = $backupEAP
    }
}

function script:Get-StronglyTypeCsFileForResx
{
    param($xml, $ModuleName, $ClassName)
$body = @'
//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a Start-ResGen funciton from build.psm1.
//     To add or remove a member, edit your .ResX file then rerun Start-ResGen.
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

using System;
using System.Reflection;

/// <summary>
///   A strongly-typed resource class, for looking up localized strings, etc.
/// </summary>
[global::System.CodeDom.Compiler.GeneratedCodeAttribute("System.Resources.Tools.StronglyTypedResourceBuilder", "4.0.0.0")]
[global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
[global::System.Runtime.CompilerServices.CompilerGeneratedAttribute()]

internal class {0} {{

    private static global::System.Resources.ResourceManager resourceMan;

    private static global::System.Globalization.CultureInfo resourceCulture;

    [global::System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("Microsoft.Performance", "CA1811:AvoidUncalledPrivateCode")]
    internal {0}() {{
    }}

    /// <summary>
    ///   Returns the cached ResourceManager instance used by this class.
    /// </summary>
    [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Advanced)]
    internal static global::System.Resources.ResourceManager ResourceManager {{
        get {{
            if (object.ReferenceEquals(resourceMan, null)) {{
                global::System.Resources.ResourceManager temp = new global::System.Resources.ResourceManager("{1}.resources.{0}", typeof({0}).GetTypeInfo().Assembly);
                resourceMan = temp;
            }}
            return resourceMan;
        }}
    }}

    /// <summary>
    ///   Overrides the current thread's CurrentUICulture property for all
    ///   resource lookups using this strongly typed resource class.
    /// </summary>
    [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Advanced)]
    internal static global::System.Globalization.CultureInfo Culture {{
        get {{
            return resourceCulture;
        }}
        set {{
            resourceCulture = value;
        }}
    }}
    {2}
}}
'@

    $entry = @'

    /// <summary>
    ///   Looks up a localized string similar to {1}
    /// </summary>
    internal static string {0} {{
        get {{
            return ResourceManager.GetString("{0}", resourceCulture);
        }}
    }}
'@
    $entries = $xml.root.data | % {
        if ($_) {
            $val = $_.value.Replace("`n", "`n    ///")
            $name = $_.name.Replace(' ', '_')
            $entry -f $name,$val
        }
    } | Out-String
    $body -f $ClassName,$ModuleName,$entries
}


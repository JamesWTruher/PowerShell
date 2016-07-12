<#
Creates a collection of script/cim/mixed modules and returns information
about them.  The information is returned in objects with the following
format:
[
   Name - string
   Path - string
   Type - string [Script/Cim/Mixed]
   HasManifest - bool
]

#>



#
# Module Folders
#

<# The name of the dll for the binary module #>
$BinaryName = 'BinaryModule'

$BinaryModuleFolderName = "BinaryModule"
$BinaryManifestModuleFolderName = "BinaryManifest"
$CimModuleFolderName = "CimModule"
$CimManifestModuleFolderName = "CimManifest"
$ScriptModuleFolderName = "ScriptModule"
$ScriptManifestModuleFolderName = "ScriptManifest"
$MixedManifestCimAllNestedFolderName = "MixedManifestCimAllNested"
$MixedManifestCimMainFolderName = "MixedManifestCimMain"
$MixedManifestScriptMainFolderName = "MixedManifestScriptMain"
$MixedManifestBinaryMainFolderName = "MixedManifestBinaryMain"
$MixedManifestNestedCimFolderName = "MixedManifestNestedCim"



#
# Calculate the paths to all the module files.
#
$myDir = split-path $myInvocation.MyCommand.Path;
$binaryFilesFolder = join-path $myDir "Binary";
$cimFilesFolder = join-path $myDir "Cim";
$mixedFilesFolder = join-path $myDir "Mixed";
$scriptFilesFolder = join-path $myDir "Script";




#
# Define the modules and what files they have.
#
$ModuleDefinitions = [ordered] @{
  $BinaryModuleFolderName = @{
    IsBroken = $false
    HasManifest = $false
    ExportedCommands = @('Test-BinaryModuleCmdlet')
    ManifestExportedCommands = @()
    PSRPExports = @('Test-BinaryModuleCmdlet')
    CIMExports = @()
    Files = @("${binaryFilesFolder}\${BinaryName}.dll")
    }

  $BinaryManifestModuleFolderName = @{
    IsBroken = $false
    HasManifest = $true
    ExportedCommands = @('Test-BinaryModuleCmdlet')
    ManifestExportedCommands = @('Test-BinaryModuleCmdlet')
    PSRPExports = @('Test-BinaryModuleCmdlet')
    CIMExports = @()
    Files = @("${binaryFilesFolder}\${BinaryName}.dll", 
    "${binaryFilesFolder}\BinaryManifest.psd1")
    }

  $ScriptModuleFolderName = @{
    IsBroken = $false
    HasManifest = $false
    ExportedCommands = @('Test-ScriptModuleFunction')
    ManifestExportedCommands = @()
    PSRPExports = @('Test-ScriptModuleFunction')
    CIMExports = @()
    Files = @("${scriptFilesFolder}\ScriptModule.psm1")
    }

  $ScriptManifestModuleFolderName = @{
    IsBroken = $false
    HasManifest = $true
    ExportedCommands = @('Test-ScriptModuleFunction')
    ManifestExportedCommands = @()
    PSRPExports = @('Test-ScriptModuleFunction')
    CIMExports = @()
    Files = @(
      "${scriptFilesFolder}\ScriptModule.psm1", 
      "${scriptFilesFolder}\ScriptManifest.psd1",
      "${scriptFilesFolder}\ScriptTestType.ps1xml",
      "${scriptFilesFolder}\ScriptTestType.format.ps1xml")
    }

  $CimModuleFolderName = @{
    IsBroken = $false
    HasManifest = $false
    ExportedCommands = @('Get-CimComputerSystem')
    ManifestExportedCommands = @()
    PSRPExports = @()
    CIMExports = @('Get-CimComputerSystem')
    Files = @("${cimFilesFolder}\CimModule.cdxml")
    }

  $CimManifestModuleFolderName = @{
    IsBroken = $false
    HasManifest = $true
    ExportedCommands = @('Get-CimComputerSystem')
    ManifestExportedCommands = @('Get-CimComputerSystem', 'Get-CimProcess')
    PSRPExports = @()
    CIMExports = @('Get-CimComputerSystem', 'Get-CimProcess')
    Files = @(
      "${cimFilesFolder}\CimModule.cdxml", 
      "${cimFilesFolder}\CimModule2.cdxml",
      "${cimFilesFolder}\CimManifest.psd1",
      "${cimFilesFolder}\CimTestType.format.ps1xml",
      "${cimFilesFolder}\CimTestType.ps1xml"
      )
    }
      
  $MixedManifestCimMainFolderName = @{
    IsBroken = $true
    HasManifest = $true
    ExportedCommands = @('Get-CimComputerSystem')
    ManifestExportedCommands = @('Get-CimComputerSystem', 'Test-ScriptModuleFunction')
    PSRPExports = @('Test-ScriptModuleFunction')
    CIMExports = @('Get-CimComputerSystem')
    Files = @(
      "${mixedFilesFolder}\MixedManifestCimMain.psd1",
      "${cimFilesFolder}\CimModule.cdxml",
      "${scriptFilesFolder}\ScriptModule.psm1")
    }

  $MixedManifestCimAllNestedFolderName = @{
    IsBroken = $false
    HasManifest = $true
    ExportedCommands = @('Get-CimComputerSystem', 'Get-CimProcess')
    ManifestExportedCommands = @()
    PSRPExports = @()
    CIMExports = @('Get-CimComputerSystem', 'Get-CimProcess')
    Files = @(
      "${cimFilesFolder}\CimModule2.cdxml", 
      "[OUTPUT_PATH]\$CimModuleFolderName",
      "${cimFilesFolder}\MixedManifestCimAllNested.psd1")
    }

  $MixedManifestScriptMainFolderName = @{
    IsBroken = $false
    HasManifest = $true
    ExportedCommands = @('Test-ScriptModuleFunction', 'Test-BinaryModuleCmdlet', 'Get-CimComputerSystem')
    ManifestExportedCommands = @('Test-ScriptModuleFunction', 'Test-BinaryModuleCmdlet', 'Get-CimComputerSystem')
    PSRPExports = @('Test-ScriptModuleFunction', 'Test-BinaryModuleCmdlet')
    CIMExports = @('Get-CimComputerSystem')
    Files = @(
      "${mixedFilesFolder}\MixedManifestScriptMain.psd1",
      "${scriptFilesFolder}\ScriptModule.psm1",
      "${BinaryFilesFolder}\${BinaryName}.dll",
      "${cimFilesFolder}\CimModule.cdxml")
    }
            
  $MixedManifestBinaryMainFolderName = @{
    IsBroken = $false
    HasManifest = $true
    ExportedCommands = @('Test-BinaryModuleCmdlet', 'Get-CimComputerSystem')
    ManifestExportedCommands =  @('Test-BinaryModuleCmdlet', 'Get-CimComputerSystem')
    PSRPExports = @('Test-BinaryModuleCmdlet')
    CIMExports = @('Get-CimComputerSystem')
    Files = @(
      "${mixedFilesFolder}\MixedManifestBinaryMain.psd1",
      "${BinaryFilesFolder}\${BinaryName}.dll",
      "${cimFilesFolder}\CimModule.cdxml")
    }

  $MixedManifestNestedCimFolderName = @{
    IsBroken = $false
    HasManifest = $true
    ExportedCommands = @('Get-CimComputerSystem', 'Get-CimProcess')
    ManifestExportedCommands = @('Get-CimComputerSystem', 'Get-CimProcess')
    PSRPExports = @()
    CIMExports = @('Get-CimComputerSystem', 'Get-CimProcess')
    Files = @(
      "${mixedFilesFolder}\MixedManifestNestedCim.psd1",
      "[OUTPUT_PATH]\$CimManifestModuleFolderName")
    }
}





function Get-ModuleInfo
{
  param($modulePath)

  $moduleName = split-path -leaf $modulePath;

  switch -wild ($moduleName)
  {
    "Binary*" { $type = 'Script'; break; }
    "Script*" { $type = 'Script'; break; }
    "Cim*"    { $type = 'Cim'; break; }
    "Mixed*"  { $type = 'Mixed'; break; }
    default   { throw 'Unknown exception type!'; }
  }

  switch -wild ($moduleName)
  {
    "*Manifest*" { $hasManifest = $true; break; }
    default { $hasManifest = $false; break; }
  }

  $exportedCommands = $ModuleDefinitions[$moduleName].ExportedCommands;
  $manifestExportedCommands = $ModuleDefinitions[$moduleName].ManifestExportedCommands;
  $cimExports = $ModuleDefinitions[$moduleName].CIMExports;
  $psrpExports = $ModuleDefinitions[$moduleName].PSRPExports;
  $isBroken = $ModuleDefinitions[$moduleName].IsBroken;


  $info = new-object psobject -property @{
    Name = $moduleName;
    Path = $modulePath;
    ImportType = $type;
    HasManifest = $hasManifest;
    IsBroken = $isBroken;
    ExportedCommands = $exportedCommands;
    CIMExports = $cimExports;
    PSRPExports = $psrpExports;
    ManifestExportedCommands = $manifestExportedCommands;
  }

  return $info;
}


function Create-Modules
{
  [CmdletBinding()]
  param(
    $outputPath = '.\Modules'
  )

  #
  # Create the directory to deploy all the modules
  #
  if (test-path $outputPath)
  {
    write-verbose "Removing '$outputPath'"
    remove-item $outputPath -recurse -force;
  }

  write-verbose "Creating directory '$outputPath'";
  $outputPath = mkdir $outputPath | foreach FullName;

  #
  # Compile the binary for the binary module
  #
  write-verbose "Compiling the binary module."
  add-type -path "${binaryFilesFolder}\*.cs" -outputassembly "${binaryFilesFolder}\${BinaryName}.dll" -outputtype library -referenced system.configuration.install




  #
  # Create the modules defined above.
  #
  pushd $myDir
  try
  {
    foreach($kv in $ModuleDefinitions.GetEnumerator())
    {
      $folder = $kv.Key;
      $filesToCopy = $kv.Value.Files;

      $folder = join-path $outputPath $folder;
      write-verbose "Creating the module directory '$folder'"

      if (test-path $folder)
      {
        del $folder -ea SilentlyContinue -rec -force;
      }

      $modulePath = mkdir $folder | foreach FullName;
      $filesToCopy | foreach { $_.Replace('[OUTPUT_PATH]',$outputPath) } | copy-item -dest $folder -rec;

      $moduleInfo = Get-ModuleInfo $modulePath;
      Write-Output $moduleInfo;
    }
  }
  finally
  {
    popd
  }
}



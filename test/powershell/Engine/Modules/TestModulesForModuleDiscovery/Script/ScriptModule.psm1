

<#
.Synopsis
   HELP HELP HELP
.DESCRIPTION
   HELP HELP HELP
.PARAMETER param1
   HELP HELP HELP
.EXAMPLE
   HELP HELP HELP
#>
function Test-ScriptModuleFunction
{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$false)]
    [object]
    $parameter = $null
  )

  end
  {
    if ($parameter -ne $null)
    {
      $parameter;
    }
  }
}

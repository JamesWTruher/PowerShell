##
## Simple Test Module
##

function Get-MyModule
{
    Param(
        [Parameter(Mandatory=$true, Position=0)]
	[ValidateNotNullOrEmpty()]
	[string]
	$Title
    )

    Write-Output "Get-MyModule Title: $Title"
}

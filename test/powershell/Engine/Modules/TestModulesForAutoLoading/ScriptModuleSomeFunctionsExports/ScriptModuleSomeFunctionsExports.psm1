
function Get-Hello{
	'Hello-Message'
}

function Get-Strings([string]$a, [string]$b) 
{ 
   	$c= $a + $b 
	$c
}

function Get-Sum($first, $second) 
{ 
   	$sum= $first + $second 
	$sum
}

Export-ModuleMember -Function * -Cmdlet * -Alias *

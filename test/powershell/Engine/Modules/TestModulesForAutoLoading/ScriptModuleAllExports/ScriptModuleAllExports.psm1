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

set-Alias New-Hello Print-Hello 

Export-ModuleMember -Function * -Cmdlet * -Alias *
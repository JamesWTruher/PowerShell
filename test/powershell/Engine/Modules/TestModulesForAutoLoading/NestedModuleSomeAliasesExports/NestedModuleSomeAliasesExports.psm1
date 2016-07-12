function Get-Hello{
	write-host 'Hello-Message'
}

function Get-Strings([string]$a, [string]$b) 
{ 
   	$c= $a + $b 
	Write-Host $c
}

function Get-Sum($first, $second) 
{ 
   	$sum= $first + $second 
	$sum
}

set-Alias Get-HelloMessage Get-Hello
set-Alias Get-SumNumbers Get-sum

Export-ModuleMember -Alias Get-SumNumbers -Function Get-sum 
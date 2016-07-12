function Get-Hello{
	write-host 'Hello-Message'
}

function Get-Strings([string]$a, [string]$b) 
{ 
   	$c= $a + $b 
	Write-Output $c
}

function Get-Sum($first, $second) 
{ 
   	$sum= $first + $second 
	Write-Output $sum
}

set-Alias Get-HelloMessage Get-Hello
set-Alias Get-SumNumbers Get-sum

Export-ModuleMember -Function * -Cmdlet * -Alias *
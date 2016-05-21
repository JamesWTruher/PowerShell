$crontabcmd = "/usr/bin/crontab"

# Internal helper functions

function Invoke-CronTab ([String] $user, [String] $arguments, [Switch] $noThrow) {
    If ($user -ne [String]::Empty) {
        $arguments = "-u $UserName $arguments"
    }
    
    $cmd  = "$crontabcmd $arguments"
    Write-Verbose $cmd
    $output = Invoke-Expression $cmd 2>&1
    if ($LastExitCode -ne 0 -and -not $noThrow) {
        $e = New-Object System.InvalidOperationException -ArgumentList $output
        throw $e
    } else {
        $output
    }
}

function Import-CronTab ([String] $user, [String] $cronTab) {
    $temp = New-TemporaryFile
    $crontab | Set-Content $temp
    Invoke-CronTab -user $user $temp.FullName
    Remove-Item $temp
}

# Public functions

function Remove-CronJob {
<#
.SYNOPSIS
  Removes the exactly matching cron job from the cron table
.DESCRIPTION
  Removes the exactly matching cron job from the cron table
.EXAMPLE
  get-diskfreespace pcrs23
  df pcrs23
.RETURNVALUE
  None
.PARAMETER UserName
  Optional parameter to specify a user's cron table
.PARAMETER Job
  Cron job object returned from Get-CronJob
#>   
    [CmdletBinding()]
    param (
        [Alias("u")][Parameter(Mandatory=$false,ValueFromPipeline=$true)][String] $UserName,
        [Alias("j")][Parameter(Mandatory=$true,ValueFromPipeline=$true)][CronJob] $Job  
    )
    
        
}

function New-CronJob {
    [CmdletBinding()]
    param (
        [Alias("u")][Parameter(Mandatory=$false,ValueFromPipeline=$true)][String] $UserName,
        [Alias("mi")][String] $Minute = "*",
        [Alias("h")][String] $Hour = "*",
        [Alias("dm")][String] $DayOfMonth = "*",
        [Alias("mo")][String] $Month = "*",
        [Alias("dw")][String] $DayOfWeek = "*",
        [Alias("c")][Parameter(Mandatory=$true)][String] $Command
    )
    process {
        # TODO: validate parameters, one complexity is different versions support different capabilities
        $line = "{0} {1} {2} {3} {4} {5}" -f $Minute, $Hour, $DayOfMonth, $Month, $DayOfWeek, $Command
        $crontab = (Invoke-CronTab -user $UserName -arguments "-l" -noThrow) + [Environment]::NewLine
        if ($crontab -is [System.Management.Automation.ErrorRecord]) {
            if ($crontab.Exception.Message.StartsWith("no crontab for ")) {
                $crontab = [String]::Empty
            }
            else {
                throw $crontab.Exception
            }
        }
        $crontab += $line
        Import-CronTab -User $UserName -crontab $crontab
    }
}

function Get-CronJob {
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Alias("u")][Parameter(Mandatory=$false,ValueFromPipeline=$true)][String] $UserName
    )
    process {
        $crontab = Invoke-CronTab -user $UserName -arguments "-l"

        ForEach ($line in $crontab) {
            if ($line.Trim().Length -gt 0)
            {
                $arRes = $line.split(" ", 6)
                $cronjob = New-Object -TypeName PSObject -Property @{
                    Minute = $arRes[0]
                    Hour = $arRes[1]
                    DayOfMonth= $arRes[2]
                    Month =$arRes[3]
                    DayOfWeek = $arRes[4]
                    Command = $arRes[5]
                }
                $cronjob.psobject.TypeNames.Insert(0,"Cron.Job")
                $cronjob
            }
        }
    }
}

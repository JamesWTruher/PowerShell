$crontabcmd = "/usr/bin/crontab"

# Internal helper functions

function Invoke-CronTab ([String] $user, [String] $args) {
    If ($UserName -ne [String]::Empty) {
        $args = "-u $UserName $args"
    }
    
    $cmd  = "$crontabcmd $args"
    Invoke-Expression $cmd
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
        $line = "{0} {1} {2} {3} {4} {5}" -f $Minute, $Hour, $DayOfMonth, $Month, $DayOfWeek, $Command
        
    }
}

function Get-CronJob {
    [CmdletBinding()]
    [OutputType([Cron.Job])]
    param (
        [Alias("u")][Parameter(Mandatory=$false,ValueFromPipeline=$true)][String] $UserName
    )
    process {
        $crontab = Invoke-CronTab -user $UserName -args "-l"

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

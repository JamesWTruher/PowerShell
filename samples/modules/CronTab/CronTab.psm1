$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path

enum DayOfWeek{
    
}

function New-CronJob {
    [CmdletBinding()]
    param (
        [int] $Minute,
        [int] $Hour,
        [int] $DayOfMonth,
        [int] $Month,
        [int] $DayOfWeek,
        [string] $Command
    )
}

function Get-CronJob {
    [CmdletBinding()]
    param (
        [Alias("u")]
        [parameter(Mandatory=$false,ValueFromPipeline=$true)]
        [string]$UserName
    )
    PROCESS {
        $args = ""
        If ($UserName -ne [String]::Empty) {
            $args = "-u $UserName"
        }
        
        $cmd  = "/usr/bin/crontab $args -l"
        $res = Invoke-Expression $cmd

        ForEach ($line in $res) {
                $arRes = $line.split(" ")
                $indx = $arRes[0].Length + $arRes[1].Length + $arRes[2].Length + $arRes[3].Length + $arRes[4].Length + 5
                $Cmd = $line.Substring($indx,$line.Length - $indx)
                $cronjob = New-Object -TypeName CronTab -Property @{
                    Minute = $arRes[0]
                    Hour = $arRes[1]
                    DayOfMonth= $arRes[2]
                    Month =$arRes[3]
                    DayOfWeek = $arRes[4]
                    Command = "$cmd"
                }
                $cronjob
        }
    }
}

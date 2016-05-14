$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path

Function New-CronJob {
    [CmdletBinding()]
    PARAM (
        [Alias("u")][Parameter(Mandatory=$false,ValueFromPipeline=$true)]
        [string] $UserName,
        [Alias("mi")][string] $Minute = "*",
        [Alias("h")][string] $Hour = "*",
        [Alias("dm")][string] $DayOfMonth = "*",
        [Alias("mo")][string] $Month = "*",
        [Alias("dw")][string] $DayOfWeek = "*",
        [Alias("c")][Parameter(Mandatory=$true)][string] $Command
    )
    PROCESS {
        $line = "{0} {1} {2} {3} {4} {5}" -f $Minute, $Hour, $DayOfMonth, $Month, $DayOfWeek, $Command
        
    }
}

Function Get-CronJob {
    [CmdletBinding()]
    PARAM (
        [Alias("u")]
        [parameter(Mandatory=$false,ValueFromPipeline=$true)]
        [string] $UserName
    )
    PROCESS {
        $args = ""
        If ($UserName -ne [String]::Empty) {
            $args = "-u $UserName"
        }
        
        $cmd  = "/usr/bin/crontab $args -l"
        $res = Invoke-Expression $cmd

        ForEach ($line in $res) {
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
                $cronjob.psobject.TypeNames.Insert(0,"CronJob")
                $cronjob
            }
        }
    }
}

$crontabcmd = "/usr/bin/crontab"

#TODO fix after https://github.com/PowerShell/PowerShell/issues/932 is fixed
#class CronJob {
#    [string] $Minute
#    [string] $Hour
#    [string] $DayOfMonth
#    [string] $Month
#    [string] $DayOfWeek
#    [string] $Command
#}

# Internal helper functions

function Get-CronTab ([String] $user) {
    $crontab = Invoke-CronTab -user $user -arguments "-l" -noThrow
    if ($crontab -is [System.Management.Automation.ErrorRecord]) {
        if ($crontab.Exception.Message.StartsWith("no crontab for ")) {
            $crontab = $null
        }
        else {
            throw $crontab.Exception
        }
    }
    [string[]] $crontab
}

function ConvertTo-CronJob ([String] $crontab) {
    $split = $crontab.split(" ", 6)
    $cronjob = New-Object -TypeName PSObject -Property @{  #TODO: change to CronJob type
        Minute = $split[0];
        Hour = $split[1];
        DayOfMonth= $split[2];
        Month =$split[3];
        DayOfWeek = $split[4];
        Command = $split[5]
    }
    $cronjob.PSObject.TypeNames.Insert(0,"CronJob")  #TODO: remove when using CronJob type
    $cronjob
}

function Invoke-CronTab ([String] $user, [String] $arguments, [Switch] $noThrow) {
    If ($user -ne [String]::Empty) {
        $arguments = "-u $UserName $arguments"
    }
    
    $cmd  = "$crontabcmd $arguments 2>&1"
    Write-Verbose $cmd
    $output = Invoke-Expression $cmd
    if ($LastExitCode -ne 0 -and -not $noThrow) {
        $e = New-Object System.InvalidOperationException -ArgumentList $output.Exception.Message
        throw $e
    } else {
        $output
    }
}

function Import-CronTab ([String] $user, [String[]] $crontab) {
    $temp = New-TemporaryFile
    [String]::Join([Environment]::NewLine,$crontab) | Set-Content $temp.FullName
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
  Get-CronJob | ? {%_.Command -like 'foo *'} | Remove-CronJob
.RETURNVALUE
  None
.PARAMETER UserName
  Optional parameter to specify a specific user's cron table
.PARAMETER Job
  Cron job object returned from Get-CronJob
#>   
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="High")]
    param (
        [Alias("u")][Parameter(Mandatory=$false)][String] $UserName,
        [Alias("j")][Parameter(Mandatory=$true,ValueFromPipeline=$true)][PSObject] $Job  #TODO use CronJob type  
    )
    process {

        if (-not $Job.PSObject.TypeNames.Contains("CronJob")) { #TODO remove when using CronJob type
            throw "Only CronJobs are accepted"
        }
        [string[]] $crontab = Get-CronTab -user $UserName
        [string[]] $newcrontab = $null
        $found = $false
        
        foreach ($line in $crontab) {
            $cronjob = ConvertTo-CronJob -crontab $line
            if ((Compare-object $cronjob.psobject.properties $Job.psobject.properties) -eq $null) {
                $found = $true
            } else {
                $newcrontab += $line
            }
        }
        
        if (-not $found) {
            $e = New-Object System.Exception -ArgumentList "Job not found"
            throw $e
        }
        if ($pscmdlet.ShouldProcess($Job.Command,"Remove")) {
            Import-CronTab -user $UserName -crontab $newcrontab
        }
    }        
}

function New-CronJob {
<#
.SYNOPSIS
  Create a new cron job
.DESCRIPTION
  Create a new job in the cron table.  Date and time parameters can be specified
  as ranges such as 10-30, as a list: 5,6,7, or combined 1-5,10-15.  An asterisk
  means 'first through last' (the entire allowed range).  Step values can be used 
  with ranges or with an asterisk.  Every 2 hours can be specified as either
  0-23/2 or */2.
.EXAMPLE
  New-CronJob -Minute 10-30 -Hour 10-20/2 -DayOfMonth */2 -Command "/bin/bash -c 'echo hello' > ~/hello"
.RETURNVALUE
  If successful, an object representing the cron job is returned
.PARAMETER UserName
  Optional parameter to specify a specific user's cron table
.PARAMETER Minute
  Valid values are 0 to 59.  If not specified, defaults to *.
.PARAMETER Hour
  Valid values are 0-23.  If not specified, defaults to *.
.PARAMETER DayOfMonth
  Valid values are 1-31.  If not specified, defaults to *.
.PARAMETER Month
  Valid values are 1-12.  If not specified, defaults to *.
.PARAMETER DayOfWeek
  Valid values are 0-7.  0 and 7 are both Sunday.  If not specified, defaults to *.
.PARAMETER Command
  Command to execute at the scheduled time and day.
#>   
    [CmdletBinding()]
    param (
        [Alias("u")][Parameter(Mandatory=$false)][String] $UserName,
        [Alias("mi")][Parameter(Position=1)][String[]] $Minute = "*",
        [Alias("h")][Parameter(Position=2)][String[]] $Hour = "*",
        [Alias("dm")][Parameter(Position=3)][String[]] $DayOfMonth = "*",
        [Alias("mo")][Parameter(Position=4)][String[]] $Month = "*",
        [Alias("dw")][Parameter(Position=5)][String[]] $DayOfWeek = "*",
        [Alias("c")][Parameter(Mandatory=$true,Position=6)][String] $Command
    )
    process {
        # TODO: validate parameters, note that different versions of crontab support different capabilities
        $line = "{0} {1} {2} {3} {4} {5}" -f [String]::Join(",",$Minute), [String]::Join(",",$Hour), 
            [String]::Join(",",$DayOfMonth), [String]::Join(",",$Month), [String]::Join(",",$DayOfWeek), $Command
        [string[]] $crontab = Get-CronTab -user $UserName
        $crontab += $line
        Import-CronTab -User $UserName -crontab $crontab
        ConvertTo-CronJob -crontab $line
    }
}

function Get-CronJob {
<#
.SYNOPSIS
  Returns the current cron jobs from the cron table
.DESCRIPTION
  Returns the current cron jobs from the cron table
.EXAMPLE
  Get-CronJob -UserName Steve
.RETURNVALUE
  CronJob objects
.PARAMETER UserName
  Optional parameter to specify a specific user's cron table
#>   
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Alias("u")][Parameter(Mandatory=$false)][String] $UserName
    )
    process {
        $crontab = Get-CronTab -user $UserName
        ForEach ($line in $crontab) {
            if ($line.Trim().Length -gt 0)
            {
                ConvertTo-CronJob -crontab $line
            }
        }
    }
}

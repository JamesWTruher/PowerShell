# This is a helper module to look for the expected events in event log
#
# Copyright (c) Microsoft Corporation, 2014
#


# This function looks in the event log for specific events

function VerifyExpectedEvents
(
    [string][Parameter(Mandatory=$true)]$channel,
    [int[]][Parameter(Mandatory=$true)]$expectedEventsId
)
{
    $OriginalErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'continue'
    $events = get-winevent -logname Microsoft-Windows-PowerShell/$channel -oldest
    $ErrorActionPreference = $OriginalErrorAction
    Assert $? "failed to get events in $channel"

    foreach($expectedId in $expectedEventsId)
    {
        $find = $false
        foreach($event in $events)
        {
            if($event.id -eq $expectedId)
            {
                $find = $true
                break
            }
        }
        if(!$find) 
        {
            break;
        }
    }
	$find
}   

    
function CleanAndEnableLog
{
    #sometimes we will get the error "The process cannot access the file because it is being used by another process.". So do it in a loop
    $trycount = 0;
    $logs=@("Microsoft-Windows-PowerShell/Operational")
    foreach($logName in $logs)
    {
        #sometimes we will get the error "The process cannot access the file because it is being used by another process.". So do it in a loop
        $trycount = 0;
        while($trycount -le 60)
        {
            $err = wevtutil set-log $logName /e:false /q:false 2>&1	        
            if($? -eq $false) 
            {
                sleep 1; 
                $trycount++; 
                log ($err); 
                continue;
            }
            break;
        }
        if($trycount -eq 61) 
        { 
            log("Could not disable log $logName")
        }
        $trycount = 0;
        while($trycount -le 60)
        {
            $err = wevtutil cl $logName 2>&1	
            if($? -eq $false) 
            {
                sleep 1; 
                $trycount++; 
                log ($err); 
                continue;
            }
            break;
        }
        if($trycount -eq 61) 
        { 
            log("Could not clear log $logName")
        }
        $trycount = 0;
        while($trycount -le 60)
        {
            $err = wevtutil set-log $logName /e:true /q:true 2>&1	        
            if($? -eq $false) 
            {
                sleep 1; 
                $trycount++; 
                log ($err); 
                continue;
            }
            break;
        }
        if($trycount -eq 61) 
        { 
            log("Could not enable log $logName")
        }
    }
}
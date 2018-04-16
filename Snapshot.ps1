Import-Module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"

#Log
$LOG_PATH="C:\AWS\Logs\"


function WriteToLog([string[]] $text, [bool] $isException = $false)
{    
    try
    {
        if((Test-Path $LOG_PATH) -eq $false)
        {
            [IO.Directory]::CreateDirectory($LOG_PATH) 
        }
        $date = GetLogDate
        $logFilePath = $LOG_PATH + $date + ".txt"
        $currentDatetime = get-date -format G 
        add-content -Path $logFilePath -Value "$currentDatetime $text"
        write-host "$datetime $text"
        #In case an error occurs while logging to log file, and error will be logged to the Windows Event Log 
        #This was not working so it's commented out. It can work if Chrome is used as the Application
        #if($isException)
        #{
        #Write-EventLog -LogName "Application" -Source "Chrome" -EventID 3001 -EntryType Information -Message "MyApp added a user-requested feature to the display." -Category 1 -RawData 10,20
        #    #write-eventlog -Logname "Application" -Source "AWS PowerShell Utilities" -EventID 3001 -CategoryInfo 1 -Message $text -EntryType "Information"
        #}
    }
    catch [Exception]
    {
        $function = "WriteToLog"
        $exception = $_.Exception.ToString()
        WriteToLog "function: $exception" -isException $true
    }    
}

#Description: Returns the current log name by determining the timestamp for the first day of the current week
#Returns: string
function GetLogDate
{
    $dayOfWeek = (get-date).DayOfWeek
    switch($dayOfWeek)
    {
        "Sunday" {$dayOfWeekNumber=0}
        "Monday" {$dayOfWeekNumber=1}
        "Tuesday" {$dayOfWeekNumber=2}
        "Wednesday" {$dayOfWeekNumber=3}
        "Thursday" {$dayOfWeekNumber=4}
        "Friday" {$dayOfWeekNumber=5}
        "Saturday" {$dayOfWeekNumber=6}
    }
    if($dayOfWeekNumber -eq 0)
    {
        $logDate = get-date -f yyyyMMdd
    }
    else
    {
        $logDate = get-date ((get-date).AddDays($dayOfWeekNumber * -1)) -f yyyyMMdd
    } 
    $logName = $logDate #+ ".txt"
    return  $logName 
}

try{
    WriteTOLog "Starting Process"
    #Set-AWSCredential -AccessKey AKIAIOSFODNN7EXAMPLE -SecretKey wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY -StoreAs RDS_SCRIPT_PROFILE
    Set-AWSCredential -ProfileName rds_user
    $date = get-date -f yyyyMMdd
    $today = Get-Date
    $snapshotName = "Via-Powershell"+$date
    #clean up old snapshots
    $snapshots = Get-RDSDBSnapshot -DBInstanceIdentifier bpernikoff
    $takenToday = $false
    foreach($snapshot in $snapshots)
    {
        $EXPIRATION_DAYS = 2
        $backupDateTime = get-date $snapshot.snapshotcreatetime
        $expireDate = (get-date).AddDays($EXPIRATION_DAYS*-1)
       #verify if the snapshot is older than two days tnen delete it
       if (($backupDateTime) -lt ($expireDate)){
           if ($snapshot.SnapshotType -eq "manual"){
               WriteToLog $snapshot.DBSnapshotIdentifier is over 2 days old and is being deleted.
               Remove-RDSDBSnapshot -DBSnapshotIdentifier $snapshot.DBSnapshotIdentifier 
           }         
       }
       #verify if a snapshot was taken today
       if($backupDateTime.Date -eq $today.Date -and $snapshot.SnapshotType -eq "manual"){
           $takenToday = $true
       }
    }
     if(($takenToday) -eq ($false))
     {
         WriteToLog "Creating new snapshot."
         New-RDSDBSnapshot -DBSnapshotIdentifier $snapshotName -DBInstanceIdentifier "bpernikoff"
     }
     WriteToLog "Process Complete"
}
    catch [Exception]
    {
        $function = "Creating New Instance"
        $exception = $_.Exception.ToString()
        WriteToLog "function: $exception" -isException $true
    }    
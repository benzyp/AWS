Import-Module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"

#Log
$LOG_PATH="C:\Users\TA\Desktop\Images\AWSBackup\Logs\"

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
    WriteTOLog "Starting Process for verificationlog-production-aurora-cluster instance."
    #Set-AWSCredential -AccessKey AKIAIOSFODNN7EXAMPLE -SecretKey wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY -StoreAs RDS_SCRIPT_PROFILE
    Set-AWSCredential -ProfileName rds_user
    $date = get-date -f yyyyMMdd
    $today = Get-Date
    $snapshotName = "Via-Powershell-production-aurora-cluster"+$date
    #clean up old snapshots -only interested in manual ones
    $snapshots = Get-RDSDBClusterSnapshot -DBClusterIdentifier verificationlog-production-aurora-cluster -SnapshotType manual
    $takenToday = $false
    foreach($snapshot in $snapshots)
    {
        $EXPIRATION_DAYS = 2 #retention time is 2 days
        $backupDateTime = get-date $snapshot.snapshotcreatetime
        $expireDate = (get-date).AddDays($EXPIRATION_DAYS*-1)
        #verify if the snapshot is older than two days tnen delete it
        if (($backupDateTime) -lt ($expireDate)){
            #only delete manual snapshots in available state not containing final in their name
            if ($snapshot.SnapshotType -eq "manual" -and $snapshot.Status -eq "available" -and ($snapshot.DBSnapshotIdentifier.Contains("final")) -ne $true){
                WriteToLog ($snapshot.DBSnapshotIdentifier.ToString() + "is over 2 days old and will be deleted.")
                Remove-RDSDBClusterSnapshot -DBClusterSnapshotIdentifier $snapshot.DBClusterSnapshotIdentifier -Force
            }         
        }
        #verify if a snapshot was taken today including in creating status which don't yet have a createtime
        if($backupDateTime.Date -eq $today.Date -or $backupDateTime -eq [DateTime]::MinValue){
            $takenToday = $true
        }
    }
    #if a snapshot was not taken today then create one
    if(($takenToday) -eq ($false))
    {
        WriteToLog "Creating new snapshot for verificationlog-production-aurora-cluster."
        New-RDSDBClusterSnapshot -DBClusterSnapshotIdentifier $snapshotName -DBClusterIdentifier "verificationlog-production-aurora-cluster"
    }
    WriteToLog "Process Complete for verificationlog-production-aurora-cluster instance."
}
catch [Exception]
{
    $function = "Creating New Instance"
    $exception = $_.Exception.ToString()
    WriteToLog "function: $exception" -isException $true
}    

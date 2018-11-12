$MailMessage = New-Object system.net.mail.mailmessage
$mailmessage.from = ("")
$mailmessage.To.add("")
$SmtpServer = "smtp.gmail.com" 
$SmtpClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
#$smtpClient.DeliveryMethod = SmtpDeliveryMethod.Network;
$SmtpClient.EnableSsl = $true 
$SmtpClient.UseDefaultCredentials = $false;
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential("", ""); 
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

try
{
    # Load WinSCP .NET assembly
    Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"
 
    # Setup session options
    $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol = [WinSCP.Protocol]::Sftp
        HostName = ".compute-1.amazonaws.com"
        UserName = ""
        SshPrivateKeyPath = "C:\Users\keyfile.ppk"
        SshHostKeyFingerprint = ="
        #PermitRootLogin = "yes"
    }
 
    try
    {
        $session = New-Object WinSCP.Session
        $session.SessionLogPath = "C:\Users\LogFile.txt"

        # Connect
        $session.Open($sessionOptions)
 
        # Upload files
        $transferOptions = New-Object WinSCP.TransferOptions
        $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
 
        $transferResult = $session.GetFiles("/var/www/html/wp-content/*", "C:\Users\wp-content\*", $False, $transferOptions)

        # Throw on any error
        $transferResult.Check()
 
        # Print results
        foreach ($transfer in $transferResult.Transfers)
        {
            Write-Host "Upload of $($transfer.FileName) succeeded"
        }
        $session.GetFiles("/var/www/html/wp-config.php", "C:\Users\wp-config.php", $False, $transferOptions)
    }
    finally
    {
        # Disconnect, clean up
        $session.Dispose()
    }
    #only send out the email on Friday
    if($dayOfWeekNumber -eq 5)
    {
        $mailmessage.Subject = “WP File Backup successful"
        $mailmessage.Body = “Your WP Files were successfuly backed up.”
        $SmtpClient.Send($mailmessage)
    }
    exit 0
}
catch
{
    Write-Host "Error: $($_.Exception.Message)"
    $mailmessage.Subject = “WP File Backup failed"
    $mailmessage.Body = “The following error prvented your WP file backup from completing.`n`n" + $_.Exception.Message + "`n`n Please contact your support personel.”
    $SmtpClient.Send($mailmessage)
    exit 1
}

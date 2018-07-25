$MailMessage = New-Object system.net.mail.mailmessage
$mailmessage.from = ("gmail_address@gmail.com")
$mailmessage.To.add("to_address@yahoo.com")
$SmtpServer = "smtp.gmail.com" 
$SmtpClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
#$smtpClient.DeliveryMethod = SmtpDeliveryMethod.Network;
$SmtpClient.EnableSsl = $true 
$SmtpClient.UseDefaultCredentials = $false;
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential("gmail_email_account", "gmail_email_account_password"); 

try{
    cd C:\Users\Benzy\Documents\Bitbucket\baishoraah
    $output = ""
    $output = $(git pull origin master)
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
    #only send out the email on Monday
    if($dayOfWeekNumber -eq 1)
    {
        $mailmessage.Subject = "Bitbucket code pull has completed"
        if ($output -eq "Already up to date."){
                    $mailmessage.Body = “Your Bitbucket code base has been backup up to C:\Users\Benzy\Documents\Bitbucket\baishoraah. `n`nThere are no changes to report”
        }
        else
        {
            $mailmessage.Body = "Your Bitbucket code base has been backup up to C:\Users\Benzy\Documents\Bitbucket\baishoraah.`n`n" + $output
        }
    }
} 
catch
{
    $mailmessage.Subject = “Code backup failed"
    $mailmessage.Body = “The following error prvented your BitBucket code from being backed up.`n`n" + $_.Exception.Message + "`n`n Please contact your support personel.”
}
$SmtpClient.Send($mailmessage)

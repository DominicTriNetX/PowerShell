# Checks if a password is about to expire, and emails the user. If no users are listed, IT receives a notifcaiton.

###############################################################################
# main                                                                        #
###############################################################################
function main(){
    # Call function to generate the list of users
    createList
}

###############################################################################
# notifyUser                                                                  #
# Sends each user listed an email regarding password expiration               #
# @Param $users - The list of users with passwords expired or about to expire #
###############################################################################
function notifyUser($users){
    #------SMTP Settings------
    $sender = "Postmaster@trinetx.com"
    $trinetxit = @("it@trinetx.com")
    $smtp = "trinetx-com.mail.protection.outlook.com"
    $port = "25" 
    #-------------------------

    # If there are no users, send an email to it
    If ($users -eq $null){
        # The subject of the email
        $subject = "Password Expiration Notification: No Users Expiring"
        # The body of the email
        $message = "There are no users that need to change their password."

        # Send an email to it and exit the script
        Send-MailMessage -To $trinetxit -SmtpServer $smtp -UseSsl -subject $subject -port $port -Body $message -From $sender -BodyAsHtml
        Exit
    # If there are users in the list
    } Else{
        # Subject of the email
        $subject = "Password Expiration Notification: Your password will expire within the next 10 days"

        # Password reset instructions
        $instructions = @"
	        <br><br>If you have not configured the SonicWALL VPN on your computer yet, please see these instructions:<br>
            https://rwhdinc.sharepoint.com/Operations/Shared%20Documents/How%20To/Connecting%20to%20the%20Corporate%20VPN.pdf. 
            <br><br>As a reminder, passwords must be changed every 180 days, and must have at least 8 characters, numbers, letters (upper and lower case), and special characters.
            <br><br>To change your password, please follow these instructions while logged into your computer:<br><br>
	        Windows:<br><ol>
	        <li>Press &#34Ctrl + Alt + Del&#34</li>
	        <li>Select &#34Change a password&#34</li>
            <li>Enter your above password</li>
            <li>Enter a new password, confirming it</li>
            <li>Press enter</li></ol>
	        <br>Mac:<br><ol>
	        <li>Open &#34System Preferences&#34</li>
	        <li>Select &#34Users and Groups&#34</li>
	        <li>Select your name from the left</li>
	        <li>Select Change Password</li>
            <li>Enter your above password</li>
            <li>Enter a new password, confirming it</li>
            <li>A hint may be set, but should not contain your password, or make it easily guessed</li>
            <li>Press &#34Ok&#34</li></ol>
            <br><br>Please note, this is an automated message set to send at 6am ET M-F. You will receive this message until your password has been changed.
            Please contact the IT Department with any questions, comments, or concerns.<br><br>

            Thanks,<br><br>

            Information  Technology (IT)<br>
            125 Cambridgepark Drive, Suite 203 | Cambridge, MA 02140 USA<br>
            (Dominic) 857-285-6064 | (Matt) 857-285-6063<br>
            it@trinetx.com | http://www.trinetx.com/
"@


        # Iterate over each user in the list
        ForEach ($user in $users){
            # Password expiration time
            $EXPIRE_DATE = ($user.passwordlastset).adddays(180)
            # Body of the email - alerts the user of the password expiration
            $message = "Hi " + $user.GivenName + "- This message is to notify you that your domain password will expire on <strong><font color=red>" + $($EXPIRE_DATE)  + `
                "</font></strong>.<br><br>Please change your password from your computer prior to then. In order to change your password, you will need to be either in" + `
                " the office on the wired or wireless networks, or connected to the corporate VPN. "

            # Append the instructions to the message
            $message += $instructions

            # Sets the UPN as the email address
            $userEmail = $user.UserPrincipalName

            # Send a separate message to each user
            Send-MailMessage  -To $userEmail -Cc $trinetxit -SmtpServer $smtp -UseSsl -subject $subject -port $port -Body $message -From $sender -BodyAsHtml
        }
    }
}

##############################################################################
# createList                                                                 #
# Creates a list of users with passwords that expired or are about to expire #
##############################################################################
function createList(){
    # Determines the expiration date
    $expires = (Get-Date).AddDays(-170).ToString()

    # Creates a list of users based on the last password reset attribute
    $users = Get-ADUser -SearchBase "ou=trinetx users,dc=trinetx,dc=int" -filter * -Properties passwordlastset,passwordneverexpires |? `
        {($_.PasswordNeverExpires -eq $false) -and ($_.passwordlastset -le $expires )}

    # Call function to notify users
    notifyUser $users
}

# Start
main
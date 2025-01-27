# While waiting for $corporateOverlords to configure Akamai logging to the Corporate Splunk
# (It is currently January, we started the process in May)
# I made this script that read my Inbox folder "Akamai_Logs" for the logs Akamai emailed us
# (I don't believe they offer emailing logs to new implementations anymore)
# then unzipped the emailed logs to a folder that Splunk knew to watch and import from. 
#
# No reason you can't use this process to similarly interact with Outlook.


$tempDir="c:\temp"
$zipDir="\\<redacted>\AkamaiLogs\zipped"
$uncompressedDir="\\<redacted>\AkamaiLogs\logs"

# Process the Akamai folder:
	$outlook = new-object -com outlook.application;
	$mapi = $outlook.GetNameSpace("MAPI");
	$olDefaultFolderInbox = 6
	$inbox = $mapi.GetDefaultFolder($olDefaultFolderInbox)
	# $inbox.Folders | SELECT FolderPath
	$akamaiFolder="\\Dal90@<redacted>\Inbox\Akamai_Logs"
	$targetFolder = $inbox.Folders | Where-Object { $_.FolderPath -eq $akamaiFolder }
	$emails=$targetFolder.items


function f_doit() {
	# What is the latest file in the zipped folder?
	$latestTime=(gci $zipDir | sort LastWriteTime | select -last 1).LastWriteTime

	# Let's go back three hours to be safe we didn't miss any emails:
	$searchTime=($latestTime).addhours(-3)
	$theseEmails=($emails | ?{$_.ReceivedTime -ge $searchTime})

	foreach ($email in $theseEmails) {
		$subject=$email.subject
		get-date; echo "Subject is $($subject)"
		$email.Attachments | foreach {
			$fileName=$_.FileName
			$shortName=($filename | %{$_ -replace '.gz\z',''})
			$tempFile="$($tempDir)\$($filename)"
			$saveFile="$($zipdir)\$($fileName)"
			$uncompressedTempFile="$($uncompressedDir)\$($shortName)"
			$uncompressedPermFile="$($uncompressedDir)\$($shortName).txt"
			
			echo "Debug"
			$fileName
			$shortName
			$tempFile
			$saveFile
			$uncompressedTempFile
			$uncompressedPermFile
			echo "Done"
	
			if (!(test-path $saveFile)) {
				$_.saveasfile($tempFile)
				& 'C:\Program Files\7-Zip\7z.exe' e $tempFile -o"$($uncompressedDir)"
				# Need to remove the # at the top of the file (since I don't have access
				# to do it in Splunk.
				get-content $uncompressedTempFile | %{$_ -replace '^#.*\z',''} | out-file $uncompressedPermFile
				rm $uncompressedTempFile				
				# Need the zipped files for ~24 hours to test-path if we've downloaded them;
				# at some point I can put in a routine to removed those > 2 weeks.	
				mv $tempFile $saveFile
			}
		} 
	} 
}

f_doit
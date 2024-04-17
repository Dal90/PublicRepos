# March 2024 /u/Dal90
# https://eff-certbot.readthedocs.io/en/latest/using.html#hooks
# https://github.com/FubarDevelopment/certbot-dns-windows

# Usage:
# $certName="ACMEtest"
# $domains="*.test.contoso.com,*.contoso.com,dal90.x.contoso.com"
# certbot.exe certonly --dry-run --cert-name $certName --domain $domains --preferred-challenges=dns --manual --manual-auth-hook .\manual-auth-hook_ultradns.ps1 --manual-cleanup-hook .\manual-cleanup-hook_ultradns.ps1

# Start our logging
# Logging to a file is important because you will not see the output of the screen when CertBot calls it.
	$logFile=".\manual-auth-hook.log"
	get-date | out-file -append $logfile

# Read in the variables CertBot set in memory
# You read that right folks, CertBot doesn't pass a parameter but sets essentially global variables in memory!
	$domain				=$env:CERTBOT_DOMAIN
	$validation			=$env:CERTBOT_VALIDATION
	$httpToken			=$env:CERTBOT_TOKEN						# Not used by this script 
	$remainingChallenges=$env:CERTBOT_REMAINING_CHALLENGES		# Not used by this script
	$allDomains			=$env:CERTBOT_ALL_DOMAINS				# Not used by this script
	
# Test variables for debugging script
	# If using these do not call by cert bot but just run script.
	# These need to exist on your DNS provider, because part of the script queries for valid zones
	# before running checks to determine which zone the record should be created in.
	# Just comment out the invoke-restmethod that POSTs JSON to prevent actual changes while debugging.
	
	# "x.contoso.com" and "contoso.com" are zones.
	# $domain="dal90.contoso.com"
	# $domain="*.contoso.com"
	# $domain="*.dev.contoso.com"
	# $domain="dal90.x.contoso.com"
	# $domain="*.x.contoso.com"
	# $domain="*.test.x.contoso.com"
	
	# $validation="Dal90"
	# $remainingChallenges=0
 
	
# Retrieve our credentials from UltraDNS from a Powershell Secrets Vault
	$credentials=@(get-secret -name 'dal90_ultradns' -vault 'dal90_secretstore')
	$username=($credentials).username
	$bstr=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(($credentials).password)
	$password=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr);
	
# Get Token from UltraDNS	
	$url = "https://restapi.ultradns.com/v1/authorization/token"
	$body = @{ 
		grant_type='password';
		username=$username;
		password=$password;
     }

# Call the service, pass in the body as a POST with x-ww-form-urlencoded content type, and get just the token.
	$token=(Invoke-RestMethod -Uri $url -Body $body -Method POST -Verbose -ContentType "application/x-www-form-urlencoded" | Select-Object accessToken)
	$token=($token).accesstoken

# Turn the token into an authorization header
	$headers = @{ 
        authorization="Bearer $token";
     }

# My UltraDNS account has several subdomains configured as their own zones.
# So I need some fancy footwork to determine which zone is correct for changes.
	$thisUri="https://api.ultradns.com/v3/zones"
	$zones=(invoke-restMethod -uri $thisUri -header $headers -method GET)
	foreach ($zone in $zones) {
		$ourDomains=@($zone.zones.properties.name)
	}

# Main Procedure
	# Preserve the original $domain in case I need it later
	$thisRecord=$domain
	$elements=$thisRecord.split(".")
	# Need special handling of wildcards
	# Let's Encrypt just validates the part of the FQDN after the *.
		$wildcardFlag=$false
		if ($thisRecord -match '\*') {
			$thisRecord=($thisRecord | %{$_ -replace '\*','wildcard'})
			$wildcardFlag=$true
		}
	if ($ourDomains | ?{$_ -match "$($thisRecord)"}) {
		$zone=$thisRecord
	
	# I never said I was good at scripting. Someday years from now I will probably cringe....
	# I have a nagging suspicion this could benefit from a refactoring that converts stuff 
	# to https://en.wikipedia.org/wiki/Reverse_domain_name_notation, matches left to right, then
	# converts back. Because holy heck matching from right to left is painful. 
	} elseif ($elements.count -eq 3){
		# If you run a very deep Matryoshka Doll DNS you may need to add more iterations. 
		# Using the test variables above is your friend in debugging this. It will read 
		# your live UltraDNS zones and match them. 
		$zone="$($elements[1]).$($elements[2])"
	} elseif ($elements.count -eq 4) {
		$tryDomain="$($elements[2]).$($elements[3])"
		if ($ourDomains | ?{$_ -match "$($tryDomain).$"}) {$zone=$tryDomain}
		$tryDomain="$($elements[1]).$($elements[2]).$($elements[3])"
		if ($ourDomains | ?{$_ -match "$($tryDomain).$"}) {$zone=$tryDomain}
	} elseif ($elements.count -eq 5) {
		$tryDomain="$($elements[3]).$($elements[4])"
		if ($ourDomains | ?{$_ -match "$($tryDomain).$"}) {$zone=$tryDomain}
		$tryDomain="$($elements[2]).$($elements[3]).$($elements[4])"
		if ($ourDomains | ?{$_ -match "$($tryDomain).$"}) {$zone=$tryDomain}
		$tryDomain="$($elements[1]).$($elements[2]).$($elements[3]).$($elements[4])"
		if ($ourDomains | ?{$_ -match "$($tryDomain).$"}) {$zone=$tryDomain}
	} elseif ($elements.count -eq 6) {
		$tryDomain="$($elements[4]).$($elements[5])"
		if ($ourDomains | ?{$_ -match "$($tryDomain).$"}) {$zone=$tryDomain}
		$tryDomain="$($elements[3]).$($elements[4]).$($elements[5])"
		if ($ourDomains | ?{$_ -match "$($tryDomain).$"}) {$zone=$tryDomain}
		$tryDomain="$($elements[2]).$($elements[3]).$($elements[4]).$($elements[5])"
		if ($ourDomains | ?{$_ -match "$($tryDomain).$"}) {$zone=$tryDomain}
		$tryDomain="$($elements[1]).$($elements[2]).$($elements[3]).$($elements[4]).$($elements[5])"
		if ($ourDomains | ?{$_ -match "$($tryDomain).$"}) {$zone=$tryDomain}
	}

	# Uncomment for debugging
	# For clarity, use $domain rather than $thisRecord in case it is a wildcard.
	# write-host "$($domain) has $($elements.count) elements and belongs in $($zone)"

# RestAPI calls to insert the new record 
	$acmePrefix="_acme-challenge"
	$uriBase="https://api.ultradns.com/zones"
	
	# TXT Record to Create:
	$thisHost="$($acmePrefix).$($thisRecord)"
	$thisUri="$($uriBase)/$($zone)./rrsets/TXT/$($thisHost)"

	# Use a low TTL; otherwise it'll cause caching issues when testing
	# or if you cancel a request and start a new one since intermediate 
	# DNS servers will be caching old entries.
	# Also be mindful of the SOA TTL for your domain, which governs
	# negative caching (although plenty of intermediate DNS do not respect it; 
	# either checking sooner or checking on their own schedule.)
	$json="{`"ttl`":`"60`",`"rdata`":[`"$($validation)`"]}"
	
	# Comment this out if just testing logic and don't want to make changes at UltraDNS
	invoke-restMethod -uri $thisUri -header $headers -body $json -method POST -verbose -contentType "application/json"
	
# Log it
	# Make this log a little more secure so someone can't steal our token from the log while it is still valid.
	$shortToken=$($token.substring(0,10))
	echo "$($domain),$($validation),$($httpToken),$($remainingChallenges),$($allDomains),$($shortToken),$($zone),$($thisHost),$($invokeFlag)" | out-file -append $logfile
	echo "$($thisUri)" | out-file -append $logfile
	echo "$json" | out-file -append $logfile

# Ok, now lets see the record exists
	# Method 1:
	
	# At work the servers I run certbot from are blocked from Port 53 and DNS-over-HTTPS.
	# We also have split-brain DNS with our private DNS horizon resolving differently from our
	# public DNS -- and Let's Encrypt needs to check the public DNS. So checking the internal
	# private DNS for these records is useless.
	# While I could hack around it, rather than risk a WTF? from Information Security, 
	# I eschew the 21st century and put in a five minute sleep cycle to avoid
	# a race condition between DNS propagation and Let's Encrypt checking public DNS.
	
	# Sleep 300

	# Method 2:
	# Wrote this on my home office machine, I don't know why it wouldn't work from
	# a corporate environment as long as you have access to the public DNS servers.

	# First sleep 30 seconds to give DNS propagation a chance...
	$sleep=30
	$now=(get-date); echo "$($now) sleeping $($sleep) seconds then will check DNS" | out-file -append $logfile
	sleep $sleep
	$dnsServer="8.8.8.8"
	$thisHost="$($acmePrefix).$($thisRecord)"
	echo "Checking $($thisRecord) in DNS" | out-file -append $logfile
	while ($recordExists -ne "yes") {
		$txtRecords=(resolve-dnsname -server $dnsServer -type TXT $thisHost -erroraction ignore)
		foreach ($txtRecord in $txtRecords) {
			$recordExists=""
			echo write-host "Checking for DNS for $($thisHost) TXT $($validation)"  | out-file -append $logfile
			echo "$($txtRecord.name),$($txtRecord.ttl),$($txtRecord.strings)"  | out-file -append $logfile
			if ($txtRecord.strings -eq $validation) {
				$recordExists="yes"
			}					 
		}
		if ($recordExists -ne "yes") {
			$now=(get-date); echo "$($now) sleeping $($sleep) seconds then will check DNS again" | out-file -append $logfile
			sleep $sleep
		}
	}
		
# Notifications
	# Add notification (email, etc.) if desired. 
	# At work I expect cerbot to run these hook scripts when renewing 
	# so I have it email me.
	# At that point I have other scripts in Powershell that use RestAPI, scp, and ssh (plink) 
	# which I can run to push the new certificate to update the F5 load balancers.
	# If I get comfortable enough, I could schedule a script that looks for new certs in
	# in certbot's "live" directory and if present automagically update the F5s.
# March 2024 /u/Dal90
# https://eff-certbot.readthedocs.io/en/latest/using.html#hooks
# https://github.com/FubarDevelopment/certbot-dns-windows

# For usage see manual-auth-hook_ultradns.ps1 

# Start our logging
# Logging to a file is important because you will not see the output of the screen when CertBot calls it.
	$logFile=".\manual-cleanup-hook.log"
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

# Retrieve our credentials from UltraDNS
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
	
	# TXT Record to Delete:
	$thisHost="$($acmePrefix).$($thisRecord)"
	$thisUri="$($uriBase)/$($zone)./rrsets/TXT/$($thisHost)"

	# Comment this out if just testing logic and don't want to make changes at UltraDNS
	invoke-restMethod -uri $thisUri -header $headers -method DELETE
	
# Log it
	# Make this log a little more secure so someone can't steal our token from the log while it is still valid.
		$shortToken=$($token.substring(0,10))
		echo "$($domain),$($validation),$($httpToken),$($remainingChallenges),$($allDomains),$($shortToken),$($thisHost),$($invokeFlag)" | out-file -append $logfile
		echo "$($thisUri)" | out-file -append $logfile


$isThisAnIP="mattFoo"
if ([ipaddress]::TryParse("$($isThisAnIP)",[ref]$null)) { echo "IP Address" } else { echo "Not an IP Address!" }
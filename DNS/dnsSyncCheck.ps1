param (
    [parameter(mandatory)][string]$name,
    [parameter(mandatory)][string]$data,
    [parameter(mandatory)][string]$dnsServers
)

# Usage:
#   .\dnsSyncCheck.ps1 -name something.d90.us -data "1.2.3.4" -dnsServers "contoso.com"

# This was just a stupid little script I wrote to keep from being bored during parts of an overnight
# data center failover. We wanted to time just how long it actually took for DNS to update across all
# our Domain Controllers which are still our DNS servers, really wish we had Infoblox for the logging
# features!

# Because I can't convince people weird, erratic things happen when DNS is blocked to DCs located in the Cloud...
# (We've weaned almost everyone off plain old LDAP, but many folks used to connect to LDAP using the domain name)
    $excludePattern="10.3*"

$dnsServers2=@(resolve-dnsname $dnsServers).ipaddress

function f_check() {
    while ($true) {
    $dataArray=@()
    foreach ($dnsServer in $dnsServers2) {
        if ($dnsServer -notlike $excludePattern) {
            resolve-dnsname $name -server $dnsServer 
            if ($? -eq $true) {
                $thisRecord=(resolve-dnsname $name -server $dnsServer)
                $dataArray+=($thisRecord.IPAddress)
                $dataArray+=($thisRecord.CNAME)
            }
        }
    }
    $dataArray=@($dataArray | select -unique)
    if ($dataArray.count -gt 1) {
        write-host "WARNING: NOT SYNCED, multiple records across DNS"
        write-host "Desired is $($data), Data is:"
        write-host "$($dataArray)"
        } else {
        if ($dataArray -notcontains $data) {
            write-host "Only one record, BUT DOES NOT MATCH DESIRED data"
            write-host "Desired is $($data), Data is:"
            write-host "$($dataArray)"
        } else {
            write-host "Only one record, looks good"
            write-host "Desired is $($data), Data is:"
            write-host "$($dataArray)"
            $flag=$true
            break
        }
        }
    $now=(get-date)
    write-host "Sleeping for 10 at $($now)"
    sleep 10
    }
}

$measurement=(measure-command {f_check})
write-host "Elapsed seconds: $($measurement.totalseconds)"

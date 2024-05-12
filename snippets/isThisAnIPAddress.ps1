param (
    [parameter(mandatory)][string]$isThisAnIPAddress
)
if ([ipaddress]::TryParse("$($isThisAnIPAddress)",[ref]$null)) { return $true } else { return $false }
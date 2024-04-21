param(
    [parameter(mandatory)][string]$cidr
)

# Based on:
# https://gist.github.com/davidjenni/7eb707e60316cdd97549b37ca95fbe93

$addr, $maskLength = $cidr -split '/'
    [int]$maskLen = 0
if (-not [int32]::TryParse($maskLength, [ref] $maskLen)) {
throw "Cannot parse CIDR mask length string: '$maskLen'"
    }
if (0 -gt $maskLen -or $maskLen -gt 32) {
throw "CIDR mask length must be between 0 and 32"
    }
$ipAddr = [Net.IPAddress]::Parse($addr)
if ($ipAddr -eq $null) {
throw "Cannot parse IP address: $addr"
    }
if ($ipAddr.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork) {
throw "Can only process CIDR for IPv4"
    }
$shiftCnt = 32 - $maskLen
$mask = -bnot ((1 -shl $shiftCnt) - 1)
$ipNum = [Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($ipAddr.GetAddressBytes(), 0))
$ipStart = ($ipNum -band $mask) + 1
$ipEnd = ($ipNum -bor (-bnot $mask)) - 1

# return as tuple of strings:
# This is useful if you want to see the range, but for this script it is not important.
#   ([BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($ipStart)) | ForEach-Object { $_ } ) -join '.'
#   ([BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($ipEnd)) | ForEach-Object { $_ } ) -join '.'

# return as tuple every IP in the CIDR
$thisIP=($ipStart)
while ($thisIP -le $ipEnd) {
    ([BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($thisIP)) | ForEach-Object { $_ } ) -join '.'
    $thisIP++
}

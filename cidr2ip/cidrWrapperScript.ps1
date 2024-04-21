param(
    [parameter(mandatory)]$sourceFile
)

$theseCidrs=(get-content ($sourceFile))

foreach ($thisCidr in $theseCidrs) {
    .\cidr2ip.ps1 -cidr $thisCidr
}

param (
    [parameter(mandatory)][string]$zone,
	[parameter(mandatory)][string]$name,
    [parameter(mandatory)][ValidateSet("A","CNAME","TXT")][string]$type
	[parameter(mandatory)][string]$rdata,
	[parameter(mandatory)][string]$ttl,
	[parameter()][string]$secretName="dal90_vendorX",
	[parameter()][string]$secretVault="dal90_secretVault",
	[parameter()][string]$logFile=".\ultradns_create_txt_record.log",
    [parameter(mandatory,HelpMessage="10 digits phone number formatted like 8605551212 is expected.")]
        [ValidatePattern('\(?(?<areaCode>\d{3})\)?(-| )?(?<first>\d{3})(-| )?(?<second>\d{4})$')][string]$phoneNumber,
    [parameter][ValidatePattern("^.*Dal90")][string]$author,
    [parameter][ValidateLength(6,10)][string[]]$someParameter
)

# Lot more information here:
    # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters?view=powershell-7.4

# To see the help message:
    # cmdlet test.ps1 at command pipeline position 1
    # Supply values for the following parameters:
    # (Type !? for Help.)
    # phoneNumber: !?
    # 10 digits phone number formatted like 8605551212 is expected.

# See also contextHelp.ps1 for another way to document these hints:
    # .\ultradnsCreateRecord.ps1 -zone x.mapfreusa.com -name matt2 -type A -rdata "10.20.30.40" -ttl 599
    # .\ultradnsCreateRecord.ps1 -zone x.mapfreusa.com -name matt3 -type TXT -rdata "Record 1" -ttl 599
    # .\ultradnsCreateRecord.ps1 -zone x.mapfreusa.com -name "@" -type TXT -rdata "Use @ for apex or root of domain" -ttl 599

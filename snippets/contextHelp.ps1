<#
    .SYNOPSIS
    This snippet is just to demonstrate how to make a comment-based help menu

    .DESCRIPTION
    Really doesn't do much beyond demonstrating comment-based help.

    .PARAMETER Name
    There are no parameters.

    .PARAMETER Extension
    There are no extensions for the parameter.

    .INPUTS
    None. You can't pipe objects to this script.

    .OUTPUTS
    System.String

    .EXAMPLE
    PS> get-help .\contextHelp.ps1 

    .EXAMPLE
    PS> get-help .\contextHelp.ps1 -example

    .EXAMPLE
    PS> get-help .\contextHelp.ps1 -inputs

    .LINK
    This is where you would include a link to more extensive explanations
    Online version: https://github.com/Dal90/PublicRepos
#>

write-host "Try things like:"
write-host "get-help .\contextHelp.ps1"
write-host "get-help .\contextHelp.ps1 -example"
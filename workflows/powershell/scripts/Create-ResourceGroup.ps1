param(
    [string]$SubscriptionId,
    [string]$Location,
    [string]$ResourceGroupSuffix
)

$ErrorActionPreference = "Stop"

Import-Module -Name $PSScriptRoot/modules/Tools/Tools.psm1
Import-Module -Name Az.Resources

try
{
    Connect-Azure -SubscriptionId $SubscriptionId
}
catch
{
    Write-Output -InputObject $PSItem
    exit 1
}

$randomString = New-RandomString -Characters 6 -Lowercase -Numbers
$resourceGroupName = $ResourceGroupSuffix + $randomString

# TODO: Check for existing resource group.
try
{
    New-AzResourceGroup -Name $resourceGroupName -Location $Location
}
catch
{
    Write-Output -InputObject $PSItem
    exit 1
}
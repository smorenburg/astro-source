param(
    [string]$SubscriptionId,
    [string]$Location,
    [string]$ResourceGroupSuffix
)

$ErrorActionPreference = "Stop"

Import-Module -Name $PSScriptRoot/modules/Helpers/Helpers.psm1
Import-Module -Name Az.Resources

try
{
    Connect-Azure -SubscriptionId $SubscriptionId

    $randomString = New-RandomString -Characters 6 -Lowercase -Numeric
    $resourceGroupName = $ResourceGroupSuffix + $randomString

    # TODO: Check for existing resource group.
    New-AzResourceGroup -Name $resourceGroupName -Location $Location
}
catch
{
    Write-Output -InputObject $PSItem
    exit 1
}
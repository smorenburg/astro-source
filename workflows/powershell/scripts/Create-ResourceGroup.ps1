Param(
    [bool]$ConnectAzure = $true,
    [string]$SubscriptionId,
    [string]$Location,
    [string]$ResourceGroupSuffix
)

$random = -Join ("0123456789abcdef".tochararray() | Get-Random -Count 6 | ForEach-Object -Parallel { [char]$_ })
$resourceGroupName = $ResourceGroupSuffix + $random

If ($ConnectAzure)
{
    Import-Module $PSScriptRoot/modules/Connect-Azure/Connect-Azure.psm1
    Connect-Azure -SubscriptionId $SubscriptionId
}

Import-Module Az.Resources
New-AzResourceGroup -Name $resourceGroupName `
    -Location $Location
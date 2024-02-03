Param(
    [string]$SubscriptionId,
    [string]$Location,
    [string]$ResourceGroupSuffix
)

$random = -Join ("0123456789abcdef".tochararray() | Get-Random -Count 6 | ForEach-Object -Parallel { [char]$_ })
$resourceGroupName = $ResourceGroupSuffix + $random

Import-Module -Name $PSScriptRoot/modules/Connect-Azure/Connect-Azure.psm1

Connect-Azure -SubscriptionId $SubscriptionId

Import-Module -Name Az.Resources

New-AzResourceGroup `
    -Name $resourceGroupName `
    -Location $Location
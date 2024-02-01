[CmdletBinding()]
param(
    [Parameter()]
    [string]$SubscriptionId = "ae9db8ac-2682-4a98-ad36-7d13b2bd5a24",
    [Parameter()]
    [string]$Location = "northeurope",
    [Parameter()]
    [string]$ResourceGroupSuffix = "rg-"
)

Import-Module Az.Accounts

$federatedToken = Get-Content $Env:AZURE_FEDERATED_TOKEN_FILE -Raw
$random = -Join ("0123456789abcdef".tochararray() | Get-Random -Count 6 | ForEach-Object { [char]$_ })
$resourceGroupName = $ResourceGroupSuffix + $random

Connect-AzAccount -ApplicationId $Env:AZURE_CLIENT_ID -TenantId $Env:AZURE_TENANT_ID -SubscriptionId $SubscriptionId -FederatedToken $federatedToken

Import-Module Az.Resources

New-AzResourceGroup -Name $resourceGroupName `
    -Location $Location
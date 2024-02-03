Param(
    [string]$SubscriptionId,
    [string]$Location,
    [string]$ResourceGroupSuffix
)

$federatedToken = Get-Content $Env:AZURE_FEDERATED_TOKEN_FILE -Raw
$random = -Join ("0123456789abcdef".tochararray() | Get-Random -Count 6 | ForEach-Object -Parallel { [char]$_ })
$resourceGroupName = $ResourceGroupSuffix + $random

Import-Module Az.Accounts
Connect-AzAccount -ApplicationId $Env:AZURE_CLIENT_ID `
    -TenantId $Env:AZURE_TENANT_ID `
    -SubscriptionId $SubscriptionId `
    -FederatedToken $federatedToken

Import-Module Az.Resources
New-AzResourceGroup -Name $resourceGroupName `
    -Location $Location
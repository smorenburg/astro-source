Import-Module Az.Accounts

$azureFederatedTokenFileContent = Get-Content $Env:AZURE_FEDERATED_TOKEN_FILE -Raw
$resourceGroupSuffix = "rg-tfstate-astro-neu-"
$location = "northeurope"
$random = (Get-Random -Minimum 0 -Maximum 99999).ToString('000000')
$resourceGroupName = $resourceGroupSuffix + $random

Connect-AzAccount -ApplicationId $Env:AZURE_CLIENT_ID -TenantId $Env:AZURE_TENANT_ID -FederatedToken $azureFederatedTokenFileContent

Import-Module Az.Resources

New-AzResourceGroup -Name $resourceGroupName `
    -Location $location
Function Connect-Azure
{
    Param(
        [string]$SubscriptionId
    )

    $federatedToken = Get-Content $Env:AZURE_FEDERATED_TOKEN_FILE -Raw

    Import-Module Az.Accounts
    Connect-AzAccount -ApplicationId $Env:AZURE_CLIENT_ID `
    -TenantId $Env:AZURE_TENANT_ID `
    -SubscriptionId $SubscriptionId `
    -FederatedToken $federatedToken
}

Export-ModuleMember -Function Connect-Azure
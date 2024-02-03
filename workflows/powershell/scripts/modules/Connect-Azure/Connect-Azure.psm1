Function Connect-Azure
{
    Param(
        [string]$SubscriptionId
    )

    $federatedToken = Get-Content `
        -Path $Env:AZURE_FEDERATED_TOKEN_FILE `
        -Raw

    Import-Module -Name Az.Accounts

    Connect-AzAccount `
        -ApplicationId $Env:AZURE_CLIENT_ID `
        -TenantId $Env:AZURE_TENANT_ID `
        -SubscriptionId $SubscriptionId `
        -FederatedToken $federatedToken `
        -WarningAction:SilentlyContinue |
            Out-Null
}

Export-ModuleMember -Function Connect-Azure
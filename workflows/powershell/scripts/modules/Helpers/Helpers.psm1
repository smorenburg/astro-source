$ErrorActionPreference = "Stop"

function Connect-Azure
{
    param(
        [string]$SubscriptionId
    )

    Import-Module -Name Az.Accounts

    # TODO: Add more connection methods besides workload identity.
    $federatedToken = Get-Content -Path $Env:AZURE_FEDERATED_TOKEN_FILE -Raw

    $account = @{
        ApplicationId = $Env:AZURE_CLIENT_ID
        TenantId = $Env:AZURE_TENANT_ID
        SubscriptionId = $SubscriptionId
        FederatedToken = $federatedToken
    }

    Connect-AzAccount @account -WarningAction:SilentlyContinue | Out-Null
}

Export-ModuleMember -Function Connect-Azure

function New-RandomString
{
    param(
        [int]$Characters,
        [switch]$Lowercase,
        [switch]$Uppercase,
        [switch]$Numeric,
        [switch]$Special
    )

    $input = $empty

    if ($Lowercase)
    {
        $input += "abcdefghijklmnopqrstuwvxyz"
    }
    if ($Uppercase)
    {
        $input += "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    }
    if ($Numeric)
    {
        $input += "0123456789"
    }
    if ($Special)
    {
        $input += "~`! @#$%^&*()_-+={[}]|\:;`"'<,>.?/"
    }

    $string = -Join ($input.tochararray() | Get-Random -Count $Characters | ForEach-Object { [char]$PSItem })

    return $string
}

Export-ModuleMember -Function New-RandomString
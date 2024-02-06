$ErrorActionPreference = "Stop"

Import-Module -Name Az.Accounts

function Connect-Azure
{
    param(
        [string]$SubscriptionId
    )

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
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [int]$Characters,
        [switch]$Lowercase,
        [switch]$Uppercase,
        [switch]$Numeric,
        [switch]$Special
    )

    $string = $empty

    if ($Lowercase)
    {
        $string += "abcdefghijklmnopqrstuwvxyz"
    }
    if ($Uppercase)
    {
        $string += "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    }
    if ($Numeric)
    {
        $string += "0123456789"
    }
    if ($Special)
    {
        $string += "~`! @#$%^&*()_-+={[}]|\:;`"'<,>.?/"
    }

    $randomString = -Join ($string.ToCharArray() | Get-Random -Count $Characters | ForEach-Object { [char]$PSItem })

    return $randomString
}

Export-ModuleMember -Function New-RandomString
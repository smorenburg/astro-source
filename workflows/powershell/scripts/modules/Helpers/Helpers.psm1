function Connect-Azure
{
    # TODO: Add more connection methods besides workload identity.
    param(
        [string]$SubscriptionId
    )

    Import-Module -Name Az.Accounts

    try
    {
        $federatedToken = Get-Content -Path $Env:AZURE_FEDERATED_TOKEN_FILE -Raw
    }
    catch
    {
        Write-Output -InputObject $PSItem
        exit 1
    }

    $account = @{
        ApplicationId = $Env:AZURE_CLIENT_ID
        TenantId = $Env:AZURE_TENANT_ID
        SubscriptionId = $SubscriptionId
        FederatedToken = $federatedToken
    }

    try
    {
        Connect-AzAccount @account -WarningAction:SilentlyContinue | Out-Null
    }
    catch
    {
        Write-Output -InputObject $PSItem
        exit 1
    }
}

Export-ModuleMember -Function Connect-Azure

function New-RandomString
{
    param(
        [int]$Characters,
        [switch]$Lowercase,
        [switch]$Uppercase,
        [switch]$Numbers,
        [switch]$Symbols
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
    if ($Numbers)
    {
        $input += "0123456789"
    }
    if ($Symbols)
    {
        $input += "~`! @#$%^&*()_-+={[}]|\:;`"'<,>.?/"
    }

    $string = -Join ($input.tochararray() | Get-Random -Count $Characters | ForEach-Object { [char]$PSItem })

    return $string
}

Export-ModuleMember -Function New-RandomString
$ErrorActionPreference = "Stop"

Import-Module -Name Az.Accounts
Import-Module -Name Az.Resources

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

function New-ResourceGroup
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$SubscriptionId,
        [string]$Location,
        [string]$ResourceGroupSuffix,
        [switch]$ConnectAzure
    )

    try
    {
        if ($ConnectAzure)
        {
            Connect-Azure -SubscriptionId $SubscriptionId
        }

        $randomString = New-RandomString -Characters 6 -Lowercase -Numeric
        $resourceGroupName = $ResourceGroupSuffix + $randomString

        # TODO: Check for existing resource group.
        New-AzResourceGroup -Name $resourceGroupName -Location $Location
    }
    catch
    {
        Write-Output -InputObject $PSItem
        exit 1
    }
}

Export-ModuleMember -Function New-ResourceGroup
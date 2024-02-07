$ErrorActionPreference = "Stop"

Import-Module -Name Az.Accounts
Import-Module -Name Az.Resources

function Connect-Azure
{
    param(
        [string]$Method,
        [string]$ApplicationId,
        [string]$TenantId,
        [string]$SubscriptionId,
        [string]$ClientSecret
    )

    <#
        .SYNOPSIS
        Connects to Azure using different connection methods.

        .DESCRIPTION
        Connects to Azure using different connection methods.
        The available connection methods are ServicePrincipal and WorkloadIdentity.

        .PARAMETER Method
        Specifies the method.

        .PARAMETER ApplicationId
        The application identifier. Only needed when using the ServicePrincipal connection method.

        .PARAMETER TenantId
        The tenant identifier. Only needed when using the ServicePrincipal connection method.

        .PARAMETER SubscriptionId
        The subscription identifier.

        .PARAMETER ClientSecret
        The client secret. Only needed when using the ServicePrincipal connection method.

        .INPUTS
        None. You can't pipe objects to Connect-Azure.

        .EXAMPLE
        PS> Connect-Azure -Type "WorkloadIdentity" -SubscriptionId "ae9db8ac-2682-4a98-ad36-7d13b2bd5a24"
    #>

    if ($Method -eq "ServicePrincipal")
    {
        $secureString = $ClientSecret | ConvertTo-SecureString -AsPlainText -Force
        $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationId, $secureString

        $account = @{
            Credential = $credential
            TenantId = $TenantId
            SubscriptionId = $SubscriptionId
        }

        Connect-AzAccount -ServicePrincipal @account
    }
    elseif ($Method -eq "WorkloadIdentity")
    {
        $federatedToken = Get-Content -Path $Env:AZURE_FEDERATED_TOKEN_FILE -Raw

        $account = @{
            ApplicationId = $Env:AZURE_CLIENT_ID
            TenantId = $Env:AZURE_TENANT_ID
            SubscriptionId = $SubscriptionId
            FederatedToken = $federatedToken
        }

        Connect-AzAccount @account -WarningAction:SilentlyContinue | Out-Null
    }
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

    <#
        .SYNOPSIS
        Generates a random string using different character options.

        .DESCRIPTION
        Generates a random string using different character options.
        The character options are Lowercase, Uppercase, Numeric, and Special.

        .PARAMETER Characters
        Specifies the number of characters.

        .PARAMETER Lowercase
        Enables lowercase characters.

        .PARAMETER Uppercase
        Enables uppercase characters.

        .PARAMETER Numeric
        Enables numeric characters.

        .PARAMETER Special
        Enables special characters.

        .INPUTS
        None. You can't pipe objects to New-RandomString.

        .EXAMPLE
        PS> New-RandomString -Characters 6 -Lowercase -Numeric
    #>

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
        [string]$Location,
        [string]$ResourceGroupPrefix,
        [string]$ConnectAzure,
        [string]$SubscriptionId,
        [string]$ApplicationId,
        [string]$TenantId,
        [string]$ClientSecret
    )

    <#
        .SYNOPSIS
        Creates a new resource group.

        .DESCRIPTION
        Creates a new resource group.
        Using a prefix followed by a random string of six characters container lowercase and numeric characters.

        .PARAMETER Location
        Specifies the location (region).

        .PARAMETER ConnectAzure
        Specifies the connection method. Without the parameter there will be no Azure connection established.
        The available connection methods are ServicePrincipal and WorkloadIdentity.

        .PARAMETER SubscriptionId
        The subscription identifier.

        .PARAMETER ApplicationId
        The application identifier. Only needed when using the ServicePrincipal connection method.

        .PARAMETER TenantId
        The tenant identifier. Only needed when using the ServicePrincipal connection method.

        .PARAMETER ClientSecret
        The client secret. Only needed when using the ServicePrincipal connection method.

        .INPUTS
        None. You can't pipe objects New-ResourceGroup.

        .EXAMPLE
        PS> New-ResourceGroup `
                -SubscriptionId "ae9db8ac-2682-4a98-ad36-7d13b2bd5a24" `
                -Location "northeurope" `
                -ResourceGroupPrefix "rg-astro-" `
                -ConnectAzure "WorkloadIdentity"

        .EXAMPLE
        PS> New-ResourceGroup -Location "northeurope" -ResourceGroupPrefix "rg-astro-"
    #>

    try
    {
        if ($ConnectAzure -eq "WorkloadIdentity")
        {
            Connect-Azure -Method "WorkloadIdentity" -SubscriptionId $SubscriptionId
        }
        elseif ($ConnectAzure -eq "ServicePrincipal")
        {
            $azure = @{
                Method = "ServicePrincipal"
                ApplicationId = $ApplicationId
                TenantId = $TenantId
                SubscriptionId = $SubscriptionId
                ClientSecret = $ClientSecret
            }

            Connect-Azure @azure
        }

        $randomString = New-RandomString -Characters 6 -Lowercase -Numeric
        $resourceGroupName = $ResourceGroupPrefix + $randomString

        New-AzResourceGroup -Name $resourceGroupName -Location $Location
    }
    catch
    {
        Write-Output -InputObject $PSItem
        exit 1
    }
}

Export-ModuleMember -Function New-ResourceGroup
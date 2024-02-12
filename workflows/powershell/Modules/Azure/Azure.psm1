$ErrorActionPreference = "Stop"

Import-Module -Name Az.Accounts
Import-Module -Name Az.Resources

function Connect-Azure
{
    param(
        [string]$SubscriptionId
    )

    <#
        .SYNOPSIS
        Connects to Azure.

        .DESCRIPTION
        Connects to Azure using workload identity.

        .PARAMETER SubscriptionId
        Specifies the subscription identifier.

        .INPUTS
        None. You can't pipe objects to Connect-Azure.

        .EXAMPLE
        PS> Connect-Azure -SubscriptionId "ae9db8ac-2682-4a98-ad36-7d13b2bd5a24"
    #>

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
        [string]$ResourceGroupName,
        [switch]$ConnectAzure,
        [string]$SubscriptionId
    )

    <#
        .SYNOPSIS
        Creates a new resource group.

        .DESCRIPTION
        Creates a new resource group. Is used by the subsequent functions when NewResourceGroup is $True.
        Checks if the resource group already exists. Fails if exists.

        .PARAMETER Location
        Specifies the location (region).

        .PARAMETER ResourceGroupName
        Specifies the resource group name.

        .PARAMETER ConnectAzure
        When specified, an Azure connection will be established.

        .PARAMETER SubscriptionId
        Specifies the subscription identifier.

        .INPUTS
        None. You can't pipe objects New-ResourceGroup.

        .EXAMPLE
        PS> New-ResourceGroup `
                -SubscriptionId "ae9db8ac-2682-4a98-ad36-7d13b2bd5a24" `
                -Location "northeurope" `
                -ResourceGroupName "rg-argo" `
                -ConnectAzure

        .EXAMPLE
        PS> New-ResourceGroup -Location "northeurope" -ResourceGroupName "rg-argo"
    #>

    try
    {
        if ($ConnectAzure)
        {
            Connect-Azure -SubscriptionId $SubscriptionId
        }

        Get-AzResourceGroup -Name $ResourceGroupName -ErrorVariable absent -ErrorAction SilentlyContinue | Out-Null

        if ($absent)
        {
            New-AzResourceGroup -Name $ResourceGroupName -Location $Location
        }
        else
        {
            Write-Output -InputObject "Error: Resource group $ResourceGroupName already exists."
            exit 1
        }
    }
    catch
    {
        Write-Output -InputObject $PSItem
        exit 1
    }
}

Export-ModuleMember -Function New-ResourceGroup

function New-StorageAccount
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Location,
        [string]$ResourceGroupName,
        [bool]$NewResourceGroup,
        [string]$StorageAccountPrefix,
        [string]$StorageAccountSku,
        [switch]$ConnectAzure,
        [string]$SubscriptionId
    )

    <#
        .SYNOPSIS
        Creates a new storage account.

        .DESCRIPTION
        Creates a new storage account.
        Using a prefix followed by a random string of 6 characters.

        .PARAMETER Location
        Specifies the location (region).

        .PARAMETER ResourceGroupName
        Specifies the resource group name.

        .PARAMETER NewResourceGroup
        Specifies creating the new resource group.

        .PARAMETER StorageAccountName
        Specifies the prefix for the storage account.

        .PARAMETER StorageAccountSku
        Specifies the SKU for the storage account.

        .PARAMETER ConnectAzure
        When specified, an Azure connection will be established.

        .PARAMETER SubscriptionId
        Specifies the subscription identifier.

        .INPUTS
        None. You can't pipe objects New-ResourceGroup.

        .EXAMPLE
        PS> New-StorageAccount `
                -SubscriptionId "ae9db8ac-2682-4a98-ad36-7d13b2bd5a24" `
                -Location "northeurope" `
                -NewResourceGroup $True `
                -ResourceGroupName rg-argo `
                -StorageAccountPrefix "saargo" `
                -ConnectAzure

        .EXAMPLE
        PS> New-StorageAccount -Location "northeurope" -ResourceGroupName rg-argo -StorageAccountPrefix "saargo"
    #>

    try
    {
        if ($ConnectAzure)
        {
            Connect-Azure -SubscriptionId $SubscriptionId
        }

        if ($NewResourceGroup)
        {
            New-ResourceGroup -Location $Location -ResourceGroupName $ResourceGroupName
        }

        $randomString = New-RandomString -Characters 6 -Lowercase -Numeric

        $deployment = @{
            ResourceGroupName = $ResourceGroupName
            TemplateFile = "Templates/storageAccount.bicep"
            storageAccountName = $StorageAccountPrefix + $randomString
            storageAccountSku = $StorageAccountSku
        }

        New-AzResourceGroupDeployment @deployment -WarningAction:SilentlyContinue
    }
    catch
    {
        Write-Output -InputObject $PSItem
        exit 1
    }
}

Export-ModuleMember -Function New-StorageAccount
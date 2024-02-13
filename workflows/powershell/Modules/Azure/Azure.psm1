$ErrorActionPreference = "Stop"

Import-Module -Name Az.Accounts
Import-Module -Name Az.Resources

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

function Connect-Azure
{
    [CmdletBinding()]
    param(
        [string]$SubscriptionId
    )
    process
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
    process
    {
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
}

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

function New-ResourceGroup
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$ConnectAzure,
        [string]$SubscriptionId,
        [string]$ResourceGroupName,
        [string]$Location
    )
    process
    {
        try
        {
            if ($ConnectAzure)
            {
                Connect-Azure -SubscriptionId $SubscriptionId
            }

            Get-AzResourceGroup -Name $ResourceGroupName -ErrorVariable absent -ErrorAction SilentlyContinue | Out-Null

            if ($absent)
            {
                New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Verbose
            }
            else
            {
                Write-Output -InputObject "Resource group $ResourceGroupName already exists."
            }
        }
        catch
        {
            Write-Output -InputObject $PSItem
            exit 1
        }
    }
}

Export-ModuleMember -Function New-ResourceGroup

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

function New-StorageAccount
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$ConnectAzure,
        [string]$SubscriptionId,
        [string]$ResourceGroupName,
        [bool]$NewResourceGroup,
        [string]$Location,
        [string]$StorageAccountNamePrefix,
        [string]$StorageAccountSku
    )
    process
    {
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

            $template = @{
                storageAccountName = $StorageAccountNamePrefix + $randomString
                storageAccountSku = $StorageAccountSku
            }

            $deployment = @{
                DeploymentName = New-RandomString -Characters 24 -Lowercase -Numeric
                ResourceGroupName = $ResourceGroupName
                TemplateFile = "Templates/storageAccount.bicep"
                TemplateParameterObject = $template
            }

            New-AzResourceGroupDeployment @deployment -WarningAction:SilentlyContinue -Verbose
        }
        catch
        {
            Write-Output -InputObject $PSItem
            exit 1
        }
    }
}

Export-ModuleMember -Function New-StorageAccount

function New-KeyVault
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$ConnectAzure,
        [string]$SubscriptionId,
        [string]$ResourceGroupName,
        [bool]$NewResourceGroup,
        [string]$Location,
        [string]$KeyVaultPrefix,
        [string]$KeyVaultName,
        [string]$ObjectId
    )
    process
    {
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

            if ($KeyVaultPrefix)
            {
                $randomString = New-RandomString -Characters 6 -Lowercase -Numeric

                $template = @{
                    keyVaultName = $KeyVaultPrefix + $randomString
                    objectId = $ObjectId
                }
            }
            else
            {
                $template = @{
                    keyVaultName = $KeyVaultName
                    objectId = $ObjectId
                }
            }

            $deployment = @{
                DeploymentName = New-RandomString -Characters 24 -Lowercase -Numeric
                ResourceGroupName = $ResourceGroupName
                TemplateFile = "Templates/keyVault.bicep"
                TemplateParameterObject = $template
            }

            New-AzResourceGroupDeployment @deployment -WarningAction:SilentlyContinue -Verbose
        }
        catch
        {
            Write-Output -InputObject $PSItem
            exit 1
        }
    }
}

Export-ModuleMember -Function New-KeyVault

function New-VirtualNetwork
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$ConnectAzure,
        [string]$SubscriptionId,
        [string]$ResourceGroupName,
        [bool]$NewResourceGroup,
        [string]$Location,
        [string]$VirtualNetworkName,
        [string]$VirtualNetworkAddressPrefix,
        [string]$SubnetName,
        [string]$SubnetAddressPrefix
    )
    process
    {
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

            $template = @{
                virtualNetworkName = $VirtualNetworkName
                virtualNetworkAddressPrefix = $VirtualNetworkAddressPrefix
                subnetName = $SubnetName
                subnetAddressPrefix = $SubnetAddressPrefix
            }

            $deployment = @{
                DeploymentName = New-RandomString -Characters 24 -Lowercase -Numeric
                ResourceGroupName = $ResourceGroupName
                TemplateFile = "Templates/virtualNetwork.bicep"
                TemplateParameterObject = $template
            }

            New-AzResourceGroupDeployment @deployment -WarningAction:SilentlyContinue -Verbose
        }
        catch
        {
            Write-Output -InputObject $PSItem
            exit 1
        }
    }
}

Export-ModuleMember -Function New-VirtualNetwork

function New-VirtualMachine
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$ConnectAzure,
        [string]$SubscriptionId,
        [string]$ResourceGroupName,
        [bool]$NewResourceGroup,
        [string]$Location,
        [string]$VirtualNetworkResourceGroupName,
        [string]$VirtualNetworkName,
        [string]$SubnetName,
        [string]$KeyVaultName,
        [bool]$NewKeyVault,
        [string]$ObjectId,
        [string]$VirtualMachineSize,
        [ValidateSet("Ubuntu")]
        [string]$Image
    )
    process
    {
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

            if ($Image -eq "Ubuntu")
            {
                $imageReference = @{
                    publisher = "canonical"
                    offer = "0001-com-ubuntu-server-jammy"
                    sku = "22_04-lts-gen2"
                    version = "latest"
                }
                $osDiskSizeGB = 32
                $virtualMachinePrefix = "azneulx"
            }

            $randomString = New-RandomString -Characters 4 -Numeric
            $virtualMachineName = $virtualMachinePrefix + $randomString

            if ($NewKeyVault)
            {
                $KeyVaultName = "kv-$virtualMachineName"

                $keyVault = @{
                    SubscriptionId = $SubscriptionId
                    Location = $Location
                    ResourceGroupName = $ResourceGroupName
                    KeyVaultName = $KeyVaultName
                    ObjectId = $ObjectId # TODO: Find another way of geting the ObjectId of the workload identity.
                }

                New-KeyVault @keyVault
            }

            $adminUsername = New-RandomString -Characters 8 -Lowercase -Numeric
            [securestring]$AdminUsernameSecure = ConvertTo-SecureString -String $adminUsername -AsPlainText -Force

            Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name "$VirtualMachineName-username" -SecretValue $adminUsernameSecure

            $adminPassword = New-RandomString -Characters 16 -Lowercase -Uppercase -Numeric -Special
            [securestring]$AdminPasswordSecure = ConvertTo-SecureString -String $adminPassword -AsPlainText -Force

            Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name "$VirtualMachineName-password" -SecretValue $adminPasswordSecure

            $template = @{
                virtualNetworkResourceGroupName = $VirtualNetworkResourceGroupName
                virtualNetworkName = $VirtualNetworkName
                subnetName = $SubnetName
                virtualMachineName = $virtualMachineName
                virtualMachineSize = $VirtualMachineSize # TODO: Limit to a handfull of D-series.
                image = $imageReference # TODO: Dropdown with a couple of images.
                adminUsername = $adminUsernameSecure
                adminPassword = $adminPasswordSecure
                osDiskSizeGB = $osDiskSizeGB
            }

            $deployment = @{
                DeploymentName = New-RandomString -Characters 24 -Lowercase -Numeric
                ResourceGroupName = $ResourceGroupName
                TemplateFile = "Templates/virtualMachine.bicep"
                TemplateParameterObject = $template
            }

            New-AzResourceGroupDeployment @deployment -WarningAction:SilentlyContinue -Verbose
        }
        catch
        {
            Write-Output -InputObject $PSItem
            exit 1
        }
    }
}

Export-ModuleMember -Function New-VirtualMachine
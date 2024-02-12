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
        [string]$StorageAccountPrefix,
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
                storageAccountName = $StorageAccountPrefix + $randomString
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
        [string]$VirtualMachineName,
        [string]$AvailabilityZone,
        [string]$VirtualMachineSize,
        [string]$Hostname,

        [ValidateSet("Ubuntu")]
        [string]$Image,

        [string]$AdminUsername,
        [string]$AdminPassword,
        [int]$OSDiskSizeGB,
        [string]$OSDiskType
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
            }

            $template = @{
                virtualNetworkResourceGroupName = $VirtualNetworkResourceGroupName
                virtualNetworkName = $VirtualNetworkName
                subnetName = $SubnetName
                virtualMachineName = $VirtualMachineName
                availabilityZone = $AvailabilityZone
                virtualMachineSize = $VirtualMachineSize
                hostname = $Hostname
                image = $imageReference
                adminUsername = $AdminUsername
                adminPassword = $AdminPassword
                osDiskSizeGB = $OSDiskSizeGB
                osDiskType = $OSDiskType
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
﻿# ----------------------------------------------------------------------------------
#
# Copyright Microsoft Corporation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------------------------

<#
.SYNOPSIS
Application security group management operations
#>
function Test-ApplicationSecurityGroupCRUD
{
    $rgLocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/ApplicationSecurityGroups"
    $location = Get-ProviderLocation $resourceTypeParent

    $rgName = Get-ResourceGroupName
    $asgName = Get-ResourceName

    try
    {
        # Create the resource group
        $resourceGroup = New-AzureRmResourceGroup -Name $rgName -Location $location -Tags @{ testtag = "ASG tag" }

        # Create the application security group
        $asgNew = New-AzureRmApplicationSecurityGroup -ResourceGroupName $rgName -Name $asgName -Location $rgLocation
        Assert-AreEqual $rgName $asgNew.ResourceGroupName
        Assert-AreEqual $asgName $asgNew.Name
        Assert-NotNull $asgNew.Location
        Assert-NotNull $asgNew.ResourceGuid
        Assert-NotNull $asgNew.Etag

        # Get the application security group
        $asgGet = Get-AzureRmApplicationSecurityGroup -ResourceGroupName $rgName -Name $asgName
        Assert-AreEqual $rgName $asgGet.ResourceGroupName
        Assert-AreEqual $asgName $asgGet.Name
        Assert-NotNull $asgGet.Location
        Assert-NotNull $asgGet.ResourceGuid
        Assert-NotNull $asgGet.Etag

        # Set the application security group to the same object
        Set-AzureRmApplicationSecurityGroup -ApplicationSecurityGroup $asgGet

        # Remove the application security group
        $asgDelete = Remove-AzureRmApplicationSecurityGroup -Name $asgName -ResourceGroupName $rgName -PassThru -Force
        Assert-AreEqual $rgName $asgDelete.ResourceGroupName
        Assert-AreEqual $asgName $asgDelete.Name
        Assert-NotNull $asgDelete.Location
        Assert-NotNull $asgDelete.ResourceGuid
        Assert-NotNull $asgDelete.Etag
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgName
    }
}

<#
.SYNOPSIS
Application security group collection operations
#>
function Test-ApplicationSecurityGroupCollections
{
    $rgLocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/ApplicationSecurityGroups"
    $location = Get-ProviderLocation $resourceTypeParent

    $rgName1 = Get-ResourceGroupName
    $rgName2 = Get-ResourceGroupName

    $asgName1 = Get-ResourceName
    $asgName2 = Get-ResourceName

    try
    {
        # Create the resource groups
        $resourceGroup1 = New-AzureRmResourceGroup -Name $rgName1 -Location $location -Tags @{ testtag = "ASG tag" }
        $resourceGroup2 = New-AzureRmResourceGroup -Name $rgName2 -Location $location -Tags @{ testtag = "ASG tag" }

        # Create ASGs in each resource group
        $asg1 = New-AzureRmApplicationSecurityGroup -Name $asgName1 -ResourceGroupName $rgName1 -Location $rgLocation
        $asg2 = New-AzureRmApplicationSecurityGroup -Name $asgName2 -ResourceGroupName $rgName2 -Location $rgLocation

        # Get the ASG in the first resource group by using the collections API
        $listRg = Get-AzureRmApplicationSecurityGroup -ResourceGroupName $rgName1
        Assert-AreEqual 1 @($listRg).Count
        Assert-AreEqual $listRg[0].ResourceGroupName $asg1.ResourceGroupName
        Assert-AreEqual $listRg[0].Name $asg1.Name
        Assert-AreEqual $listRg[0].Location $asg1.Location
        Assert-AreEqual $listRg[0].Etag $asg1.Etag

        # Get all ths ASGs in the subscription
        $listSub = Get-AzureRmApplicationSecurityGroup

        $asg1FromList = @($listSub) | Where-Object Name -eq $asgName1 | Where-Object ResourceGroupName -eq $rgName1
        Assert-AreEqual $asg1.ResourceGroupName $asg1FromList.ResourceGroupName
        Assert-AreEqual $asg1.Name $asg1FromList.Name
        Assert-AreEqual $asg1.Location $asg1FromList.Location
        Assert-AreEqual $asg1.Etag $asg1FromList.Etag

        $asg2FromList = @($listSub) | Where-Object Name -eq $asgName2 | Where-Object ResourceGroupName -eq $rgName2
        Assert-AreEqual $asg2.ResourceGroupName $asg2FromList.ResourceGroupName
        Assert-AreEqual $asg2.Name $asg2FromList.Name
        Assert-AreEqual $asg2.Location $asg2FromList.Location
        Assert-AreEqual $asg2.Etag $asg2FromList.Etag
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgName1
        Clean-ResourceGroup $rgName2
    }
}

<#
.SYNOPSIS
#>
function Test-ApplicationSecurityGroupInNewSecurityRule
{
    param
    (
        $useIds
    )

    $rgLocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/ApplicationSecurityGroups"
    $location = Get-ProviderLocation $resourceTypeParent

    $rgName = Get-ResourceGroupName
    $asgName = Get-ResourceName
    $nsgName = Get-ResourceName
    $securityRuleNames = @((Get-ResourceName), (Get-ResourceName), (Get-ResourceName), (Get-ResourceName))

    try
    {
        # Create the resource group
        $resourceGroup = New-AzureRmResourceGroup -Name $rgName -Location $location -Tags @{ testtag = "ASG tag" }

        # Create the application security group
        $asg = New-AzureRmApplicationSecurityGroup -ResourceGroupName $rgName -Name $asgName -Location $rgLocation

        # Create security rule
        $securityRules = @()

        if ($useIds)
        {
            $securityRules += New-AzureRmNetworkSecurityRuleConfig -Name $securityRuleNames[0] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroupId $asg.Id -DestinationApplicationSecurityGroupId $asg.Id -Access Allow -Priority 100 -Direction Inbound
            $securityRules += New-AzureRmNetworkSecurityRuleConfig -Name $securityRuleNames[1] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroupId $asg.Id -DestinationAddressPrefix * -Access Allow -Priority 102 -Direction Inbound
            $securityRules += New-AzureRmNetworkSecurityRuleConfig -Name $securityRuleNames[2] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationApplicationSecurityGroupId $asg.Id -Access Allow -Priority 103 -Direction Inbound
            $securityRules += New-AzureRmNetworkSecurityRuleConfig -Name $securityRuleNames[3] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 104 -Direction Inbound
        }
        else
        {
            $securityRules += New-AzureRmNetworkSecurityRuleConfig -Name $securityRuleNames[0] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroup $asg -DestinationApplicationSecurityGroup $asg -Access Allow -Priority 100 -Direction Inbound
            $securityRules += New-AzureRmNetworkSecurityRuleConfig -Name $securityRuleNames[1] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroup $asg -DestinationAddressPrefix * -Access Allow -Priority 102 -Direction Inbound
            $securityRules += New-AzureRmNetworkSecurityRuleConfig -Name $securityRuleNames[2] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationApplicationSecurityGroup $asg -Access Allow -Priority 103 -Direction Inbound
            $securityRules += New-AzureRmNetworkSecurityRuleConfig -Name $securityRuleNames[3] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 104 -Direction Inbound
        }

        # Create the network security group
        $nsg = New-AzureRmNetworkSecurityGroup -name $nsgName -ResourceGroupName $rgName -Location $location -SecurityRule $securityRules

        #verification
        Assert-AreEqual $rgName $nsg.ResourceGroupName
        Assert-AreEqual $nsgName $nsg.Name
        Assert-NotNull $nsg.Location
        Assert-NotNull $nsg.Etag
        Assert-AreEqual 4 @($nsg.SecurityRules).Count

        $securityRule = @($nsg.SecurityRules) | Where-Object Name -eq $securityRuleNames[0]
        Assert-AreEqual $null $securityRule.SourceAddressPrefix
        Assert-AreEqual $null $securityRule.DestinationAddressPrefix
        Assert-AreEqual $asg.Id $securityRule.SourceApplicationSecurityGroups.Id
        Assert-AreEqual $asg.Id $securityRule.DestinationApplicationSecurityGroups.Id

        $securityRule = @($nsg.SecurityRules) | Where-Object Name -eq $securityRuleNames[1]
        Assert-AreEqual $null $securityRule.SourceAddressPrefix
        Assert-AreEqual "*" $securityRule.DestinationAddressPrefix
        Assert-AreEqual $asg.Id $securityRule.SourceApplicationSecurityGroups.Id
        Assert-AreEqual $null $securityRule.DestinationApplicationSecurityGroups

        $securityRule = @($nsg.SecurityRules) | Where-Object Name -eq $securityRuleNames[2]
        Assert-AreEqual "*" $securityRule.SourceAddressPrefix
        Assert-AreEqual $null $securityRule.DestinationAddressPrefix
        Assert-AreEqual $null $securityRule.SourceApplicationSecurityGroups
        Assert-AreEqual $asg.Id $securityRule.DestinationApplicationSecurityGroups.Id

        $securityRule = @($nsg.SecurityRules) | Where-Object Name -eq $securityRuleNames[3]
        Assert-AreEqual "*" $securityRule.SourceAddressPrefix
        Assert-AreEqual "*" $securityRule.DestinationAddressPrefix
        Assert-AreEqual $null $securityRule.SourceApplicationSecurityGroups
        Assert-AreEqual $null $securityRule.DestinationApplicationSecurityGroups
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgName
    }
}

<#
.SYNOPSIS
#>
function Test-ApplicationSecurityGroupInAddedSecurityRule
{
    param
    (
        $useIds
    )

    $rgLocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/ApplicationSecurityGroups"
    $location = Get-ProviderLocation $resourceTypeParent

    $rgName = Get-ResourceGroupName
    $asgName = Get-ResourceName
    $nsgName = Get-ResourceName
    $securityRuleNames = @((Get-ResourceName), (Get-ResourceName), (Get-ResourceName), (Get-ResourceName))

    try
    {
        # Create the resource group
        $resourceGroup = New-AzureRmResourceGroup -Name $rgName -Location $location -Tags @{ testtag = "ASG tag" }

        # Create the application security group
        $asg = New-AzureRmApplicationSecurityGroup -ResourceGroupName $rgName -Name $asgName -Location $rgLocation

        # Create the network security group
        $nsg = New-AzureRmNetworkSecurityGroup -name $nsgName -ResourceGroupName $rgName -Location $location

        if ($useIds)
        {
            Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[0] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroupId $asg.Id -DestinationApplicationSecurityGroupId $asg.Id -Access Allow -Priority 100 -Direction Inbound
            Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[1] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroupId $asg.Id -DestinationAddressPrefix * -Access Allow -Priority 102 -Direction Inbound
            Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[2] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationApplicationSecurityGroupId $asg.Id -Access Allow -Priority 103 -Direction Inbound
            Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[3] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 104 -Direction Inbound
        }
        else
        {
            Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[0] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroup $asg -DestinationApplicationSecurityGroup $asg -Access Allow -Priority 100 -Direction Inbound
            Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[1] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroup $asg -DestinationAddressPrefix * -Access Allow -Priority 102 -Direction Inbound
            Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[2] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationApplicationSecurityGroup $asg -Access Allow -Priority 103 -Direction Inbound
            Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[3] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 104 -Direction Inbound
        }

        $securityRules = Get-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg

        #verification
        Assert-AreEqual 4 @($securityRules).Count

        $securityRule = @($securityRules) | Where-Object Name -eq $securityRuleNames[0]
        Assert-AreEqual $null $securityRule.SourceAddressPrefix
        Assert-AreEqual $null $securityRule.DestinationAddressPrefix
        Assert-AreEqual $asg.Id $securityRule.SourceApplicationSecurityGroups.Id
        Assert-AreEqual $asg.Id $securityRule.DestinationApplicationSecurityGroups.Id

        $securityRule = @($securityRules) | Where-Object Name -eq $securityRuleNames[1]
        Assert-AreEqual $null $securityRule.SourceAddressPrefix
        Assert-AreEqual "*" $securityRule.DestinationAddressPrefix
        Assert-AreEqual $asg.Id $securityRule.SourceApplicationSecurityGroups.Id
        Assert-AreEqual $null $securityRule.DestinationApplicationSecurityGroups

        $securityRule = @($securityRules) | Where-Object Name -eq $securityRuleNames[2]
        Assert-AreEqual "*" $securityRule.SourceAddressPrefix
        Assert-AreEqual $null $securityRule.DestinationAddressPrefix
        Assert-AreEqual $null $securityRule.SourceApplicationSecurityGroups
        Assert-AreEqual $asg.Id $securityRule.DestinationApplicationSecurityGroups.Id

        $securityRule = @($securityRules) | Where-Object Name -eq $securityRuleNames[3]
        Assert-AreEqual "*" $securityRule.SourceAddressPrefix
        Assert-AreEqual "*" $securityRule.DestinationAddressPrefix
        Assert-AreEqual $null $securityRule.SourceApplicationSecurityGroups
        Assert-AreEqual $null $securityRule.DestinationApplicationSecurityGroups
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgName
    }
}

<#
.SYNOPSIS
#>
function Test-ApplicationSecurityGroupInSetSecurityRule
{
    param
    (
        $useIds
    )

    $rgLocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/ApplicationSecurityGroups"
    $location = Get-ProviderLocation $resourceTypeParent

    $rgName = Get-ResourceGroupName
    $asgName = Get-ResourceName
    $nsgName = Get-ResourceName
    $securityRuleNames = @((Get-ResourceName), (Get-ResourceName), (Get-ResourceName), (Get-ResourceName))

    try
    {
        $resourceGroup = New-AzureRmResourceGroup -Name $rgName -Location $location -Tags @{ testtag = "ASG tag" }

        $asg = New-AzureRmApplicationSecurityGroup -ResourceGroupName $rgName -Name $asgName -Location $rgLocation

        $securityRules = @()
        $securityRules += New-AzureRmNetworkSecurityRuleConfig -Name $securityRuleNames[0] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 100 -Direction Inbound
        $securityRules += New-AzureRmNetworkSecurityRuleConfig -Name $securityRuleNames[1] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 102 -Direction Inbound
        $securityRules += New-AzureRmNetworkSecurityRuleConfig -Name $securityRuleNames[2] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 103 -Direction Inbound
        
        $nsg = New-AzureRmNetworkSecurityGroup -name $nsgName -ResourceGroupName $rgName -Location $location -SecurityRule $securityRules

        if ($useIds)
        {
            Set-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[0] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroupId $asg.Id -DestinationApplicationSecurityGroupId $asg.Id -Access Allow -Priority 100 -Direction Inbound
            Set-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[1] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroupId $asg.Id -DestinationAddressPrefix * -Access Allow -Priority 102 -Direction Inbound
            Set-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $securityRuleNames[2] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationApplicationSecurityGroupId $asg.Id -Access Allow -Priority 103 -Direction Inbound
        }
        else
        {
            Set-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg  -Name $securityRuleNames[0] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroup $asg -DestinationApplicationSecurityGroup $asg -Access Allow -Priority 100 -Direction Inbound
            Set-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg  -Name $securityRuleNames[1] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceApplicationSecurityGroup $asg -DestinationAddressPrefix * -Access Allow -Priority 102 -Direction Inbound
            Set-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg  -Name $securityRuleNames[2] -Description "description" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationApplicationSecurityGroup $asg -Access Allow -Priority 103 -Direction Inbound
        }

        $securityRules = Get-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg

        $securityRule = @($securityRules) | Where-Object Name -eq $securityRuleNames[0]
        Assert-AreEqual $null $securityRule.SourceAddressPrefix
        Assert-AreEqual $null $securityRule.DestinationAddressPrefix
        Assert-AreEqual $asg.Id $securityRule.SourceApplicationSecurityGroups.Id
        Assert-AreEqual $asg.Id $securityRule.DestinationApplicationSecurityGroups.Id

        $securityRule = @($securityRules) | Where-Object Name -eq $securityRuleNames[1]
        Assert-AreEqual $null $securityRule.SourceAddressPrefix
        Assert-AreEqual "*" $securityRule.DestinationAddressPrefix
        Assert-AreEqual $asg.Id $securityRule.SourceApplicationSecurityGroups.Id
        Assert-AreEqual $null $securityRule.DestinationApplicationSecurityGroups

        $securityRule = @($securityRules) | Where-Object Name -eq $securityRuleNames[2]
        Assert-AreEqual "*" $securityRule.SourceAddressPrefix
        Assert-AreEqual $null $securityRule.DestinationAddressPrefix
        Assert-AreEqual $null $securityRule.SourceApplicationSecurityGroups
        Assert-AreEqual $asg.Id $securityRule.DestinationApplicationSecurityGroups.Id
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgName
    }
}

<#
.SYNOPSIS
#>
function Test-ApplicationSecurityGroupInNewNetworkInterface
{
    $rgLocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/ApplicationSecurityGroups"
    $location = Get-ProviderLocation $resourceTypeParent

    $rgName = Get-ResourceGroupName

    $asgName1 = Get-ResourceName
    $asgName2 = Get-ResourceName
    $asgName3 = Get-ResourceName

    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $nicName = Get-ResourceName

    try
    {
        $resourceGroup = New-AzureRmResourceGroup -Name $rgName -Location $location -Tags @{ testtag = "ASG tag" }

        $asg1 = New-AzureRmApplicationSecurityGroup -ResourceGroupName $rgName -Name $asgName1 -Location $rgLocation
        $asg2 = New-AzureRmApplicationSecurityGroup -ResourceGroupName $rgName -Name $asgName2 -Location $rgLocation
        $asg3 = New-AzureRmApplicationSecurityGroup -ResourceGroupName $rgName -Name $asgName3 -Location $rgLocation

        $subnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzureRmvirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet

        $nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $location -Subnet $vnet.Subnets[0] -ApplicationSecurityGroup $asg1

        Assert-AreEqual 1 @($nic.IpConfigurations.ApplicationSecurityGroups).Count
        Assert-AreEqual $asg1.Id @($nic.IpConfigurations.ApplicationSecurityGroups)[0].Id

        $nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $location -Subnet $vnet.Subnets[0] -ApplicationSecurityGroup @($asg2, $asg3) -Force

        Assert-AreEqual 2 @($nic.IpConfigurations.ApplicationSecurityGroups).Count
        Assert-IsTrue @($nic.IpConfigurations.ApplicationSecurityGroups.Id) -contains $asg2.Id
        Assert-IsTrue @($nic.IpConfigurations.ApplicationSecurityGroups.Id) -contains $asg3.Id
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgName
    }
}

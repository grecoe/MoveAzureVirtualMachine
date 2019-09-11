<#	
	Copyright  Microsoft Corporation ("Microsoft").
	
	Microsoft grants you the right to use this software in accordance with your subscription agreement, if any, to use software 
	provided for use with Microsoft Azure ("Subscription Agreement").  All software is licensed, not sold.  
	
	If you do not have a Subscription Agreement, or at your option if you so choose, Microsoft grants you a nonexclusive, perpetual, 
	royalty-free right to use and modify this software solely for your internal business purposes in connection with Microsoft Azure 
	and other Microsoft products, including but not limited to, Microsoft R Open, Microsoft R Server, and Microsoft SQL Server.  
	
	Unless otherwise stated in your Subscription Agreement, the following applies.  THIS SOFTWARE IS PROVIDED "AS IS" WITHOUT 
	WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL MICROSOFT OR ITS LICENSORS BE LIABLE 
	FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
	TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
	HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
	NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THE SAMPLE CODE, EVEN IF ADVISED OF THE
	POSSIBILITY OF SUCH DAMAGE.
#>

<#
	This file contains a group of helper functions to create new resources allowing the main script to not be so cluttered.
#>

using module .\VirtualMachineUtil.psm1
using module .\DiskUtil.psm1
using module .\Configuration.psm1

<#
	CreateOsDiskSnapshot
	
	Creates a snapshot of the OS disk attached to an existing virtual machine.
	
	Parameters:
		vmInfo - Information about the Virtual MachineName
		
	Returns:
		PSSnapshot
#>
function CreateOsDiskSnapshot{
	Param([VirtualMachineInfo] $vmInfo)

	$snapshotName = $vmInfo.MachineName.ToLower() + "_ss"
	$osDisk = Get-AzureRmDisk -ResourceGroupName $vmInfo.ResourceGroup -DiskName $vmInfo.DiskName
	$snapshotConfig = New-AzureRmSnapshotConfig -SourceUri $osDisk.Id -CreateOption Copy -Location $vmInfo.Region
	$snapshot= New-AzureRmSnapshot -Snapshot $snapshotConfig -SnapshotName $snapshotName -ResourceGroupName $vmInfo.ResourceGroup

	$snapshot
}

<#
	CreateDiskSnapshot
	
	Creates a snapshot of the OS disk attached to an existing virtual machine.
	
	Parameters:
		diskInfo - Information about the disk
		
	Returns:
		PSSnapshot
#>
function CreateDiskSnapshot{
	Param([DiskInformation] $diskInfo)

	$snapshotName = $diskInfo.Name.ToLower() + "_ss"
	$snapshotConfig = New-AzureRmSnapshotConfig -SourceUri $diskInfo.Id -CreateOption Copy -Location $diskInfo.Region
	$snapshot= New-AzureRmSnapshot -Snapshot $snapshotConfig -SnapshotName $snapshotName -ResourceGroupName $diskInfo.ResourceGroup

	$snapshot
}

<#
	GetDiskStorageType
	
	Get the storage type to use for the re-created disk from snapshot.
	
	Parameters:
		vmInfo - Information about the Virtual MachineName
		
	Returns:
		Storage type name (string)
#>
function GetDiskStorageType{
	Param([VirtualMachineInfo] $vmInfo)

	$osDisk = Get-AzureRmDisk -ResourceGroupName $vmInfo.ResourceGroup -DiskName $vmInfo.DiskName
	
	Write-Host("Disk Storage Type: " + $osDisk.Sku.Name)
	$osDisk.Sku.Name
}

<#
	CreateManagedDiskFromSnapshot
	
	Creates a managed disk from a snapshot object
	
	Parameters:
		vmInfo - Information about the Virtual MachineName
		storageType - Type of Azure storage 
		snapshotId - Azure ResourceID of a snapshot object
		
	Returns:
		PSDisk
#>
function CreateManagedDiskFromSnapshot2 {
	Param([DiskInformation] $diskInfo, [string]$snapshotId)

	$diskName = $diskInfo.Name.ToLower() + "_dsk"
	$newOSDiskConfig = New-AzureRmDiskConfig -AccountType $diskInfo.StorageType -Location $diskInfo.Region -CreateOption Copy -SourceResourceId $snapshotId
	$newOSDisk = New-AzureRmDisk -Disk $newOSDiskConfig -ResourceGroupName $diskInfo.ResourceGroup -DiskName $diskName
	
	$newOSDisk
}

<#
	CreateManagedDiskFromSnapshot2
	
	Creates a managed disk from a snapshot object
	
	Parameters:
		vmInfo - Information about the Virtual MachineName
		storageType - Type of Azure storage 
		snapshotId - Azure ResourceID of a snapshot object
		
	Returns:
		PSDisk
#>
function CreateManagedDiskFromSnapshot {
	Param([VirtualMachineInfo] $vmInfo, [string] $storageType, [string]$snapshotId)

	$diskName = $vmInfo.MachineName.ToLower() + "_dsk"
	$newOSDiskConfig = New-AzureRmDiskConfig -AccountType $storageType -Location $vmInfo.Region -CreateOption Copy -SourceResourceId $snapshotId
	$newOSDisk = New-AzureRmDisk -Disk $newOSDiskConfig -ResourceGroupName $vmInfo.ResourceGroup -DiskName $diskName
	
	$newOSDisk
}

<#
	CreateDestinationResourceGroup
	
	Checks in the destination subscription for a resource group with the name provided in teh 
	configuration. If not there it is created.
	
	Subscription is switched to the destination subscription on entry and switched back to the 
	source subscription on return.
	
	Parameters:
		config - Script configuration object
		vmInfo - Information about the Virtual MachineName
		
	Returns:
		Nothing
#>
function CreateDestinationResourceGroup{
	Param([MoveConfiguration] $config, [VirtualMachineInfo] $vmInfo)

	# have to set context to the destination sub
	$result = Select-AzureRMSubscription -SubscriptionId $config.DestinationSubscriptionId
	$result = az account set -s $config.DestinationSubscriptionId
	
	$result = az group exists -n $config.DestinationResourceGroup
	
	if($result -and ($result.ToLower() -eq 'false'))
	{
		Write-Host("Creating Destination Resource Group")
		$autoTags = @{}
		$autoTags.Add("CopyFromSub", $config.SubscriptionId)
		$autoTags.Add("CopyFromRg", $config.ResourceGroupName)
		$result = New-AzureRmResourceGroup -Name $config.DestinationResourceGroup -Location $vmInfo.Region -Tag $autoTags 
	}

	# Set it back to originating subscription
	$result = Select-AzureRMSubscription -SubscriptionId $config.SubscriptionId
	$result = az account set -s $config.SubscriptionId
}


<#
	MoveDisk
	
	Internally is just a MoveAzureRMResource so any resource could be moved.
	
	Parameters:
		config - Script configuration object
		diskId - Azure resource ID of the disk to move.
		
	Returns:
		Nothing
#>
function MoveDisk{
	Param([MoveConfiguration] $config, [string]$diskId)

	$moveCommand = "Move-AzureRmResource -Force -DestinationSubscriptionId " + $config.DestinationSubscriptionId + " -DestinationResourceGroupName " + $config.DestinationResourceGroup + " -ResourceId " + $diskId
	$result = Invoke-Expression $moveCommand
}

<#
	CreateVNET
	
	Create an Azure Virtual Network if it doesn't exist.
	
	config has the name of a virtual network. The destination resouce group is checked for that resource by name. If not found, a new 
	virtual network is created.
	
	Parameters:
		config - Script configuration object
		vmInfo - Information about the Virtual MachineName
		
	Returns:
		Nothing
#>
function CreateVNET{
	Param([MoveConfiguration] $config, [VirtualMachineInfo] $vmInfo)
	
	$existingVnet = Get-AzureRMResource -ResourceGroupName $config.DestinationResourceGroup -Name $config.VirtualNetworkName -ErrorAction SilentlyContinue
	
	if($existingVnet -eq $null)
	{
		$addressSpace = "172.30.25.0/24"
		Write-Host("Creating default VNET with address space : " + $addressSpace)
		
		$defaultSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name default -AddressPrefix $addressSpace
		$result = New-AzureRmVirtualNetwork -Name $config.VirtualNetworkName -ResourceGroupName $config.DestinationResourceGroup -Location $vmInfo.Region -AddressPrefix $addressSpace -Subnet $defaultSubnet
	}
}

<#
	CreateVirtualMachine
	
	Create an Azure Virtual Machine in total. 
	
	Parameters:
		config - Script configuration object
		vmInfo - Information about the Virtual MachineName
		diskName - Name of the managed disk that was copied over from the source account.
		
	Returns:
		Nothing
#>
function CreateVirtualMachine{
	Param([MoveConfiguration] $config, [VirtualMachineInfo] $vmInfo, [string]$diskName)
	
	# Names needed along the way
	$publicIpName = $vmInfo.MachineName.ToLower()+'_ip'
	$nicName = $vmInfo.MachineName.ToLower() + '_nic'
	$machineName = $vmInfo.MachineName + (Get-Date).Ticks.ToString().Substring(0,6)

	# Get the disk to attach
	$osDiskToRessurect = Get-AzureRmDisk -ResourceGroupName $config.DestinationResourceGroup -DiskName $diskName

	#Initialize virtual machine configuration
	$newVirtualMachine = New-AzureRMVMConfig -VMName $machineName -VMSize $vmInfo.Sku

	# Attach the disk with the appropriate OS flag
	if($vmInfo.OsType.ToLower() -eq 'windows')
	{
		$newVirtualMachine = Set-AzureRMVMOSDisk -VM $newVirtualMachine -ManagedDiskId $osDiskToRessurect.Id -CreateOption Attach -Windows
	}
	else
	{
		$newVirtualMachine = Set-AzureRMVMOSDisk -VM $newVirtualMachine -ManagedDiskId $osDiskToRessurect.Id -CreateOption Attach -Linux
	}
	
	# Apply market place tags, if there
	if($vmInfo.Plan)
	{
		# Set plan info
		$newVirtualMachine = Set-AzureRmVMPlan -VM $newVirtualMachine -Product $vmInfo.Plan.Product -Name $vmInfo.Plan.Name -Publisher $vmInfo.Plan.Publilisher
		
		#accept terms
		$agreementTerms = Get-AzureRmMarketplaceTerms -Product $vmInfo.Plan.Product -Name $vmInfo.Plan.Name -Publisher $vmInfo.Plan.Publilisher
		$agreementTerms = Set-AzureRmMarketplaceTerms -Accept -InputObject $agreementTerms
	}
	
	################## Prepare the NIC
	#Create a public IP for the VM
	$publicIp = New-AzureRMPublicIpAddress -Name $publicIpName -ResourceGroupName $config.DestinationResourceGroup -Location $vmInfo.Region -AllocationMethod Dynamic

	#Get the virtual network where virtual machine will be hosted
	$vnet = Get-AzureRMVirtualNetwork -Name $config.VirtualNetworkName -ResourceGroupName $config.DestinationResourceGroup

	# Create the security group
	$nsg = CreateNetworkSecurityGroup -config $config -vmInfo $vmInfo
	
	# Create the NIC with the security group, public IP and vnet
	$nic = New-AzureRMNetworkInterface -Name $nicName -NetworkSecurityGroupId $nsg.Id -ResourceGroupName $config.DestinationResourceGroup -Location $vmInfo.Region -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $publicIp.Id
	################## Prepare the NIC

	#Add network interface
	$newVirtualMachine = Add-AzureRMVMNetworkInterface -VM $newVirtualMachine -Id $nic.Id

	# Create storage and associate it
	$storageName = CreateVMStorageAccount -config $config -vmInfo $vmInfo
	$newVirtualMachine = Set-AzureRmVMBootDiagnostics -VM $newVirtualMachine -Enable -ResourceGroupName $config.DestinationResourceGroup -StorageAccount $storageName

	
	#Create the virtual machine with Managed Disk
	New-AzureRMVM -VM $newVirtualMachine -ResourceGroupName $config.DestinationResourceGroup -Location $vmInfo.Region
}

<#
	CreateNetworkSecurityGroup
	
	Create an Azure Network Security Group. Default rules on the group are extended with the appropriate additional defaults depending
	on the operating system type. 
	
	Parameters:
		config - Script configuration object
		vmInfo - Information about the Virtual MachineName
		
	Returns:
		Nothing
#>
function CreateNetworkSecurityGroup{
	Param([MoveConfiguration] $config, [VirtualMachineInfo] $vmInfo)
	
	$nsgName = $vmInfo.MachineName.ToLower()+'_nsg'
	$nsg = New-AzureRmNetworkSecurityGroup -Name $nsgName -ResourceGroupName $config.DestinationResourceGroup -Location $vmInfo.Region
	
	if($vmInfo.OsType.ToLower() -eq 'windows')
	{
		$result = Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name Jupyter -Description "Jupyter" -Access Allow -Protocol Tcp -Direction Inbound -Priority 1010 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 9999  
		$result = Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name MSSQL -Description "MSSQL" -Access Allow -Protocol Tcp -Direction Inbound -Priority 1020 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 1433  
		$result = Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name default-allow-rdp -Description "default-allow-rdp" -Access Allow -Protocol Tcp -Direction Inbound -Priority 1030 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389  
	}
	else
	{
		$result = Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name JupyterHub -Description "JupyterHub" -Access Allow -Protocol Tcp -Direction Inbound -Priority 1010 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8000  
		$result = Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name RStudioServer -Description "RStudioServer" -Access Allow -Protocol Tcp -Direction Inbound -Priority 1020 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8787  
		$result = Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name default-allow-ssh -Description "default-allow-ssh" -Access Allow -Protocol Tcp -Direction Inbound -Priority 1030 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22  
	}
	
	$result = Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $nsg

	$nsg
}


<#
	CreateVMStorageAccount
	
	Creats a storage account to be attached for boot diagnostics to the virtual machine.
	
	Parameters:
		config - Script configuration object
		vmInfo - Information about the Virtual MachineName
		
	Returns:
		Name of the storage account created.
#>
function CreateVMStorageAccount{
	Param([MoveConfiguration] $config, [VirtualMachineInfo] $vmInfo)
	
	$stgName = $config.DestinationResourceGroup.ToLower() + $vmInfo.Region.ToLower() + "diag"
	
	if($stgName.Length -gt 23)
	{ 
		$stgName = $stgName.SubString(0,18) + "diag"
	}
	
	
	$result = New-AzureRmStorageAccount -ResourceGroupName $config.DestinationResourceGroup -AccountName $stgName -Location $vmInfo.Region -SkuName Standard_LRS -Kind StorageV2 -AccessTier Hot
	
	$stgName
}


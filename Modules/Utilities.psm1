
using module .\VirtualMachineUtil.psm1
using module .\Configuration.psm1


function CreateOsDiskSnapshot{
	Param([VirtualMachineInfo] $vmInfo)

	$snapshotName = $vmInfo.MachineName.ToLower() + "_ss"
	$osDisk = Get-AzureRmDisk -ResourceGroupName $vmInfo.ResourceGroup -DiskName $vmInfo.DiskName
	$snapshotConfig = New-AzureRmSnapshotConfig -SourceUri $osDisk.Id -CreateOption Copy -Location $vmInfo.Region
	$snapshot= New-AzureRmSnapshot -Snapshot $snapshotConfig -SnapshotName $snapshotName -ResourceGroupName $vmInfo.ResourceGroup

	$snapshot
}

function CreateManagedDiskFromSnapshot {
	Param([VirtualMachineInfo] $vmInfo, [string] $storageType, [string]$snapshotId)

	$diskName = $vmInfo.MachineName.ToLower() + "_dsk"
	$newOSDiskConfig = New-AzureRmDiskConfig -AccountType $storageType -Location $vmInfo.Region -CreateOption Copy -SourceResourceId $snapshotId
	$newOSDisk = New-AzureRmDisk -Disk $newOSDiskConfig -ResourceGroupName $vmInfo.ResourceGroup -DiskName $diskName
	
	$newOSDisk
}

function MoveDisk{
	Param([MoveConfiguration] $config, [string] $storageType, [string]$diskId)

	$moveCommand = "Move-AzureRmResource -DestinationSubscriptionId " + $config.DestinationSubscriptionId + " -DestinationResourceGroupName " + $config.DestinationResourceGroup + " -ResourceId " + $diskId
	$result = Invoke-Expression $moveCommand
}

function CreateVirtualMachine{
	Param([MoveConfiguration] $config, [VirtualMachineInfo] $vmInfo, [string]$diskName)
	
	# Names needed along the way
	$publicIpName = $vmInfo.MachineName.ToLower()+'_ip'
	$nicName = $vmInfo.MachineName.ToLower() + '_nic'

	# Get the disk to attach
	$osDiskToRessurect = Get-AzureRmDisk -ResourceGroupName $config.DestinationResourceGroup -DiskName $diskName

	#Initialize virtual machine configuration
	$newVirtualMachine = New-AzureRMVMConfig -VMName $vmInfo.MachineName -VMSize $vmInfo.Sku

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
		$newVirtualMachine = Set-AzureRmVMPlan -VM $newVirtualMachine -Product $vmInfo.Plan.Product -Name $vmInfo.Plan.Name -Publisher $vmInfo.Plan.Publilisher
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

	
	$newVirtualMachine = Add-AzureRMVMNetworkInterface -VM $newVirtualMachine -Id $nic.Id

	#Create the virtual machine with Managed Disk
	New-AzureRMVM -VM $newVirtualMachine -ResourceGroupName $config.DestinationResourceGroup -Location $vmInfo.Region
}

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


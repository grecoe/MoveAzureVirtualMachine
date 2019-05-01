

class MarketPlacePlan {
	[string]$Name
	[string]$Publilisher 
	[string]$Product 
}

class VirtualMachineInfo {
	[string]$ResourceGroup 
	[string]$MachineName 
	[string]$OsType 
	[string]$DiskName  
	[string]$DiskSize  
	[string]$Sku  
	[String]$Region  
	
	[MarketPlacePlan]$Plan 
}

class VirtualMachineUtils{

	static [VirtualMachineInfo] GetVmInfo([string]$resourceGroup, [string]$virtualMachineName) 
	{
		[VirtualMachineInfo] $returnInfo = [VirtualMachineInfo]::new()
		$existingVM = Get-AzureRmVM -ResourceGroupName $resourceGroup -Name $virtualMachineName

		$returnInfo.ResourceGroup = $resourceGroup
		$returnInfo.MachineName = $virtualMachineName
		$returnInfo.DiskName = $existingVm.StorageProfile.OsDisk.Name
		$returnInfo.DiskSize = $existingVm.StorageProfile.OsDisk.DiskSizeGB.ToString()
		$returnInfo.Sku = $existingVm.HardwareProfile.VmSize
		$returnInfo.Region = $existingVm.Location

		if($existingVm.Plan)
		{
			$returnInfo.Plan = [MarketPlacePlan]::new()
			$returnInfo.Plan.Name = $existingVm.Plan.Name
			$returnInfo.Plan.Publilisher = $existingVm.Plan.Publisher
			$returnInfo.Plan.Product = $existingVm.Plan.Product
		}
		
		if($existingVm.OSProfile.WindowsConfiguration)
		{
			$returnInfo.OsType = "windows"
		}
		else
		{
			$returnInfo.OsType = "linux"
		}
		
		return $returnInfo
	}


}
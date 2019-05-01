

class MoveConfiguration {
	$SubscriptionId 
	$ResourceGroupName 
	$VirtualMachine 
	$VirtualMachineOs 

	$DestinationSubscriptionId 
	$DestinationResourceGroup 
	$VirtualNetworkName 


	static [MoveConfiguration] LoadConfiguration([string]$configurationFile)
	{
		$configurationObject = Get-Content -Path $configurationFile -raw | ConvertFrom-Json
		$configuration = @{}
		$configurationObject.psobject.properties | Foreach { $configuration[$_.Name] = $_.Value }
		
		[MoveConfiguration]$returnConfig = [MoveConfiguration]::new()
		$returnConfig.SubscriptionId = $configuration['SubscriptionId']
		$returnConfig.ResourceGroupName = $configuration['ResourceGroup']
		$returnConfig.VirtualMachine = $configuration['VirtualMachine']

		$returnConfig.DestinationSubscriptionId = $configuration['DestinationSubscriptionId']
		$returnConfig.DestinationResourceGroup = $configuration['DestinationResourceGroup']
		$returnConfig.VirtualNetworkName = $configuration['DestinationVirtualNetworkName']

		return $returnConfig
	}		

}
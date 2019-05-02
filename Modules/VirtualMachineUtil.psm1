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
	CLass representing the MarketPlace information associated with a VM.
#>
class MarketPlacePlan {
	[string]$Name
	[string]$Publilisher 
	[string]$Product 
}

<#
	Class representing the details of a Virtual Machine.
#>
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

<#
	Class to collect Virtual Machine information.
#>
class VirtualMachineUtils{

	<#
		GetVmInfo
		
		Retrieves VirtualMachine specifics from Azure
		
		Parameters:
			resourceGroup - The resource group the VM lives in.
			virtualMachineName - The name of the virtual machine.
								
		Returns:
			Instance of VirtualMachineInfo
	#>
	static [VirtualMachineInfo] GetVmInfo([string]$resourceGroup, [string]$virtualMachineName) 
	{
		[VirtualMachineInfo] $returnInfo = [VirtualMachineInfo]::new()
		$existingVM = Get-AzureRmVM -ResourceGroupName $resourceGroup -Name $virtualMachineName
		
		$returnInfo.ResourceGroup = $resourceGroup
		$returnInfo.MachineName = $virtualMachineName
		$returnInfo.DiskName = $existingVm.StorageProfile.OsDisk.Name
		$returnInfo.Sku = $existingVm.HardwareProfile.VmSize
		$returnInfo.Region = $existingVm.Location

		if($existingVm.StorageProfile.OsDisk.DiskSizeGB)
		{
			# Night of 5/1/2019 starting coming back null
			$returnInfo.DiskSize = $existingVm.StorageProfile.OsDisk.DiskSizeGB.ToString()
		}
		else
		{
			Write-Host("WARNING: VM Configuration is missing OsDisk.DiskSizeGB value, default to 127")
			$returnInfo.DiskSize = "127"
		}

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
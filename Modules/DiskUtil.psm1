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
class DiskInformation {
	[string]$Name
	[string]$ResourceGroup
	[string]$Region
	[string]$SubscriptionId
	[string]$StorageType
	[string]$Id
}

class DiskUtils {

	<#
		GetDiskInfo
		
		Retrieves Disk specifics from Azure
		
		Parameters:
			resourceGroup - The resource group the VM lives in.
			virtualMachineName - The name of the virtual machine.
								
		Returns:
			Instance of VirtualMachineInfo
	#>
	static [DiskInformation] GetDiskInfo([string]$resourceGroup, [string]$diskName)
	{
		[DiskInformation] $returnInfo = [DiskInformation]::new()
		$disk = Get-AzureRmDisk -ResourceGroupName $resourceGroup -DiskName $diskName

		$returnInfo.Name = $diskName
		$returnInfo.ResourceGroup = $resourceGroup
		$returnInfo.Region = $disk.Location
		$returnInfo.StorageType = $disk.Sku.Name
		$returnInfo.Id = $disk.Id

		return $returnInfo
	}

}
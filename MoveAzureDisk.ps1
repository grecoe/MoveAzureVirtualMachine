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
	This script utilizes a few modules to accomplish the goal of copying a Diskfrom one subscription to another. However,
	the script also works if you are just moving a disk from one resource group to another in the same subscription.
#>	


Using module .\Modules\Configuration.psm1
Using module .\Modules\VirtualMachineUtil.psm1
Using module .\Modules\Utilities.psm1
Using module .\Modules\DiskUtil.psm1

Write-Host('********** CONFIGURATION')
$config = [MoveDiskConfiguration]::LoadConfiguration('.\MoveDiskConfig.json')
Write-Host(($config | ConvertTo-Json))
Write-Host('')

foreach($diskName in $config.DiskName)
{
	Write-Host($diskName)

	Write-Host('********** SOURCE SUBSCRIPTION')
	Select-AzureRMSubscription -SubscriptionId $config.SubscriptionId

	Write-Host('********** EXISTING DISK')
	$info = [DiskUtils]::GetDiskInfo($config.ResourceGroupName, $diskName)
	$info.SubscriptionId = $config.SubscriptionId
	Write-Host(($info | ConvertTo-Json))
	Write-Host('')
	Write-Host('DONE')

	Write-Host('********** CREATE SNAPSHOT')
	$snapshot = CreateDiskSnapshot -diskInfo $info
	Write-Host('DONE')


	Write-Host('********** CREATE DISK FROM SNAPSHOT')
	$managedDisk = CreateManagedDiskFromSnapshot2 -diskInfo $info -snapshotId $snapshot.Id
	Write-Host('DONE')

	[MoveConfiguration]$moveConfig = [MoveConfiguration]::new()
	$moveConfig.SubscriptionId = $config.SubscriptionId
	$moveConfig.ResourceGroupName = $config.ResourceGroupName
	$moveConfig.DestinationSubscriptionId = $config.DestinationSubscriptionId
	$moveConfig.DestinationResourceGroup = $config.DestinationResourceGroup
	[VirtualMachineInfo] $vmInfo = [VirtualMachineInfo]::new()
	$vmInfo.Region = $info.Region

	Write-Host('********** CHECK FOR DESTINATION RESOURCE GROUP')
	CreateDestinationResourceGroup -config $moveConfig -vmInfo $vmInfo
	Write-Host('DONE')

	Write-Host('********** MOVE DISK')
	MoveDisk -config $moveConfig -diskId $managedDisk.Id
	Write-Host('DONE')
	
	Write-Host('********** REMOVE SNAPSHOT')
	Remove-AzureRMResource -ResourceId $snapshot.Id -Force
	Write-Host('DONE')
}

Write-Host('************ DONE')

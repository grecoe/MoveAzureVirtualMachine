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
	This script utilizes a few modules to accomplish the goal of copying a VM from one subscription to another. However,
	the script also works if you are just moving a VM from one resource group to another in the same subscription.
	
	The original VM will not be altered in any way. A snapshot of the os disk of the source VM is created. From that accomplish
	managed disk is generated then moved from the source location to the destination location. Once moved, all of the infrastructure
	for the new VM is generated (except the VNET). The resulting VM will be named the same as the originating VM, but with different 
	network settings. 
#>	


Using module .\Modules\Configuration.psm1
Using module .\Modules\VirtualMachineUtil.psm1
Using module .\Modules\Utilities.psm1

# There is likely no need to change this value, so unless there is an error, leave it
# alone. 
$storageType = 'Premium_LRS'

Write-Host('********** CONFIGURATION')
$config = [MoveConfiguration]::LoadConfiguration('.\MoveVMConfig.json')
Write-Host(($config | ConvertTo-Json))
Write-Host('')


Write-Host('********** SOURCE SUBSCRIPTION')
Select-AzureRMSubscription -SubscriptionId $config.SubscriptionId

Write-Host('********** EXISTING VIRTUAL MACHINE')
$info = [VirtualMachineUtils]::GetVmInfo($config.ResourceGroupName,$config.VirtualMachine)
Write-Host(($info | ConvertTo-Json))
Write-Host('')

Write-Host('********** CREATE SNAPSHOT')
$snapshot = CreateOsDiskSnapshot -vmInfo $info
Write-Host('DONE')

Write-Host('********** CREATE DISK FROM SNAPSHOT')
$managedDisk = CreateManagedDiskFromSnapshot -vmInfo $info -storageType $storageType -snapshotId $snapshot.Id
Write-Host('DONE')

Write-Host('********** CHECK FOR DESTINATION RESOURCE GROUP')
CreateDestinationResourceGroup -config $config -vmInfo $info
Write-Host('DONE')

Write-Host('********** MOVE DISK')
MoveDisk -config $config -diskId $managedDisk.Id
Write-Host('DONE')

# Now move over to the destination resource group
Write-Host('********** DESTINATION SUBSCRIPTION')
Select-AzureRMSubscription -SubscriptionId $config.DestinationSubscriptionId

Write-Host('********** CHECKING FOR VNET')
CreateVNET -config $config -vmInfo $info
Write-Host('DONE')

Write-Host('********** CREATE NEW VM')
CreateVirtualMachine -config $config -vmInfo $info -diskName $managedDisk.Name
Write-Host('DONE')
	

Write-Host('************ DONE')
#Write-Host(($snapshot | ConvertTo-Json))
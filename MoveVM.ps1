using module .\Modules\Configuration.psm1
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

Write-Host('********** MOVE DISK')
MoveDisk -config $config -diskId $managedDisk.Id
Write-Host('DONE')

# Now move over to the destination resource group
Write-Host('********** DESTINATION SUBSCRIPTION')
Select-AzureRMSubscription -SubscriptionId $config.DestinationSubscriptionId

Write-Host('********** CREATE NEW VM')
CreateVirtualMachine -config $config -vmInfo $info -diskName $managedDisk.Name
Write-Host('DONE')
	

Write-Host('************ DONE')
#Write-Host(($snapshot | ConvertTo-Json))
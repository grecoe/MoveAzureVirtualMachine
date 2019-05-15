# Moving Virtual Machines or Disks Between Azure Subscriptions
<sub>Author: Daniel Grecoe, A Microsoft employee</sub>

Moving virtrual machines created from Marketplace (i.e. DSVM) between subscriptions is not something you can accomplish with the Azure Portal. It requires a bit of work to get the parts in place correctly. 

Further, your VM might have additional disks attached to it. While the scripts will not attach all of the disks to your new VM, you can move them to the new location as well. 

There are two scripts that can accomplish this:

## Use Cases ##
1. Copy a Virtual Machine from one subscription to another.
2. Copy a Virtual Machine within a subscription.
3. Copy a Disk from one subscription to another.
4. Copy a Disk within a subscription.

## Prerequisites
There are a few things you must ensure have occured before running these scripts:

* Ensure you have the latest version of PowerShell. You can determine the version and how to update it using [this](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-windows-powershell?view=powershell-6) link. 
* Ensure you have the latest version of AzureRM modules by following [these](https://www.powershellgallery.com/packages/AzureRM/6.13.1) instructions. 
* Ensure you have the latest Azure CLI by following [these](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) instructions.
* Ensure you have performed an ***az login*** and ***Login-AzureRMAccount***. Depending on your configuraiton, you may already be logged in when you start. 

# Move a Virtual Machine
To move a virtual machine you will need to configure the ***MoveVMConfig.json*** file. When completed, you will then need to run teh ***MoveVM.ps1*** Powershell script. 

During this process, a copy of the virtual machine is created in a destination subscription. The original machine is not affected.


### What next? 
- Finish reading this section.
- Identify a Virtual Machine you want to move and to where.
- Optionally create the destination resource group and virtual network. If these are NOT created, they will be created for you on your behalf.
- Modify the ***MoveVMConfig.json*** file with your settings.
- Run the ***MoveVM.ps1*** script.


## Configuration Requirements
The file ***MoveVMConfig.json*** has several settings that you, the user, will have to collect and replace before calling the ***MoveVM.ps1*** script.

|Parameter|Description|
|-------------------|----------------------|
|SOURCE_SUBSCRIPTION_ID|The subscription ID where the Virtual Machine resides in now.|
|SOURCE_SUBSCRIPTION_RESOURCE_GROUP|The Azure Resource Group that contains the Virtual Machine to move.|
|SOURCE_MACHINE|The name of the Virtual Machine in the above Azure Resource Group|
|DESTINATION_SUBSCRIPTION_ID|The subscription ID where the VM will be re-constituted. If copying to the same subscription, this value will be equal to SOURCE_SUBSCRIPTION_ID|
|DESTINATION_SUBSCRIPTION_RESOURCE_GROUP|The Azure Resource Group that will hold the copied Virtual Machine <sup>1</sup>|
|DESTINATION_SUBSCRIPTION_VIRTUAL_NETWORK|The Azure Virtual Network to attach to the copied Virtual Machine <sup>2</sup>|

<sup>1</sup> If this resource group exists in the subscription, it is used. Otherwise it is created for you in the same region that the source Virtual Machine resides. If you have created it already, it should also be in the same region as the source Virtual Machine.

<sup>2</sup> If this VNET exists (resource checked by name only in the destination resource group) it is used. If it does not exist it is created with a single default subnet with the address space of 172.30.25.0/24. If created on your behalf, it should be in the same region as the source Virtual Machine and you may need to modify the address space. 


# Move a Disk
To move a disk you will need to configure the ***MoveDiskConfig.json*** file. When completed, you will then need to run teh ***MoveAzureDisk.ps1*** Powershell script. 


### What next? 
- Finish reading this section.
- Identify a Disk you want to move and to where.
- Optionally create the destination resource group. If the resource gropu is NOT created, it will be created for you on your behalf.
- Modify the ***MoveDiskConfig.json*** file with your settings.
- Run the ***MoveAzureDisk.ps1*** script.


## Configuration Requirements
The file ***MoveDiskConfig.json*** has several settings that you, the user, will have to collect and replace before calling the ***MoveAzureDisk.ps1*** script.

|Parameter|Description|
|-------------------|----------------------|
|SOURCE_SUBSCRIPTION_ID|The subscription ID where the Virtual Machine resides in now.|
|SOURCE_SUBSCRIPTION_RESOURCE_GROUP|The Azure Resource Group that contains the Virtual Machine to move.|
|DISK_NAME|The name of the Disk =in the above Azure Resource Group|
|DESTINATION_SUBSCRIPTION_ID|The subscription ID where the VM will be re-constituted. If copying to the same subscription, this value will be equal to SOURCE_SUBSCRIPTION_ID|
|DESTINATION_SUBSCRIPTION_RESOURCE_GROUP|The Azure Resource Group that will hold the copied Virtual Machine <sup>1</sup>|

<sup>1</sup> If this resource group exists in the subscription, it is used. Otherwise it is created for you in the same region that the source Virtual Machine resides. If you have created it already, it should also be in the same region as the source Virtual Machine.





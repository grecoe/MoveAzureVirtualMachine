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
	This file contains the class that loads the configuraiton file from disk. This information is vital to determining where
	the source VM is and the destination. The rest of the information is collected from the VM that is being copied.
#>


class MoveConfiguration {
	$SubscriptionId 
	$ResourceGroupName 
	$VirtualMachine 

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
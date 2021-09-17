# Connect to vCenter Servers.  Hint: Look at -SaveCreentials and/or *-VICredentialStoreItem to avoid login prompts
$sourceVC = Connect-VIServer 'vc036.example.com'
$destVC   = Connect-VIServer 'vc1.example.com'

# Short Name of the template VM.  This is an attempt to future proof the script to make edits easier.
$vmShortName = 'Win10-1909'

# List of primary Source VM.  It'll use the naming convention MainTemplate-<name from above>, but can be adjusted if needed.
# This is where all updates/patches would be committed. 
$primarySource = "MainTemplate_$vmShortName"

# Todays Date in ISO format.  This will be used in cloned VM names & snapshot names.
$dateString = (Get-Date).ToString('yyyy-MM-dd')

# The following two sections will focus on making ready to use clones of the base template, one per environment.
# Local VC: The VC that contains the 'MainTemplate' needs less tasks as we can clone directly & then snapshot.
$objSourceVM = Get-VM $primarySource 
$thisNewVM = $objSourceVM | New-VM -Name "VDI-$($vmShortName)_$dateString" -Host $objSourceVM.VMHost
$thisNewVM | New-Snapshot -Name "VDI Base Image $dateString"

# Remote VC: The remote vCenter requires that we make a local clone, then move the VM to reach the destination.
# Once the temp copy is moved/renamed, we'll again create a snapshot.
$tempVMName = "tempmove-VDI-$($vmShortName)"
$objSourceVM = Get-VM $primarySource 
$thisNewVM = $objSourceVM | New-VM -Name $tempVMName -Host $objSourceVM.VMHost
$splatMoveVM = @{
	VM                = $thisNewVM
	NetworkAdapter    = (Get-NetworkAdapter -VM $thisNewVM -Server $sourceVC)
	PortGroup         = (Get-VirtualPortGroup -Name 'VLAN10' -Server $destVC)
	Destination       = (Get-VMHost 'test-esx-33.lab.enterpriseadmins.org' -Server $destVC)
	Datastore         = (Get-Datastore 'test-esx-33_nvme' -Server $destVC)
}
Move-VM @splatMoveVM

Get-VM $tempVMName -Server $destVC | 
Set-VM -Name "VDI-$($vmShortName)_$dateString" -Confirm:$false | 
New-Snapshot -Name "VDI Base Image $dateString"

# Super Basic Report; this will include all VMs with some common tools properties, outputing to CSV
Get-VM | 
  Select-Object Name, @{N='ToolsStatus';E={$_.guest.state}}, 
    @{N='ToolsVersion';E={$_.guest.ToolsVersion}}, 
    @{N='upgradePolicy';E={$_.ExtensionData.Config.Tools.ToolsUpgradePolicy}} |
  Export-Csv d:\tmp\currentRunningVmToolsReport.csv -notypeinformation

# Check for updates; this will import the CSV from above, and add the same common tools properties as new columns that are prefixed with the current date/time.  The file will be saved with the new date in the file name.
$newOutput = @()
$newOutputDate = (Get-Date).ToString('yyyy-MM-dd hhmm')
$listOfVms = Import-Csv d:\tmp\currentRunningVmToolsReport.csv
foreach ($vm in $listOfVms) {
  $thisVM = Get-VM $vm.Name
  if ( ($thisVM | Measure-Object).Count -eq 1 ) {
  $newOutput += $vm | Select-Object *, @{N="$newOutputDate ToolsStatus";E={$thisVM.guest.state}},
    @{N="$newOutputDate ToolsVersion";E={$thisVM.guest.ToolsVersion}}, 
    @{N="$newOutputDate upgradePolicy";E={$thisVM.ExtensionData.Config.Tools.ToolsUpgradePolicy}}
  } else { # this is what happens if the VM count doesn't equal 1
  write-warning "The VM $($vm.name) returned $($($thisVM | Measure-Object).Count) records"
  } # end if statement
} # end foreach loop
$newOutput | Export-Csv "d:\tmp\$newOutputDate runningVmToolsReport.csv" -notypeinformation



# https://kb.vmware.com/s/article/1010048
# From resolution, step #3, set ToolsUpgradePolicy to UpgradeAtPowerCycle
Foreach ($v in (Import-Csv D:\tmp\myListOfDevVMs.csv)) {  # changed this line to account for input coming from CSV
  $vm = Get-VM $v.Name | Get-View  # changed this line to account for input coming from CSV
  $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
  $vmConfigSpec.Tools = New-Object VMware.Vim.ToolsConfigInfo
  $vmConfigSpec.Tools.ToolsUpgradePolicy = "UpgradeAtPowerCycle"
  $vm.ReconfigVM($vmConfigSpec)
}

# https://kb.vmware.com/s/article/1010048
# From resolution, after note at the end of the article, set ToolsUpgradePolicy to manual
Foreach ($v in (Import-Csv D:\tmp\myListOfDevVMs.csv)) {  # changed this line to account for input coming from CSV
  $vm = Get-VM $v.Name | Get-View  # changed this line to account for input coming from CSV
  $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
  $vmConfigSpec.Tools = New-Object VMware.Vim.ToolsConfigInfo
  $vmConfigSpec.Tools.ToolsUpgradePolicy = "manual"
  $vm.ReconfigVM($vmConfigSpec)
}

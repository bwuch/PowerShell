$vmHash = Get-VM | Select-Object ID, Name, @{N='Cluster';E={$_.VMHost.Parent}} | Group-Object ID -AsHashTable

(Get-Cluster).ExtensionData.Configuration.DasVmConfig | Select-Object @{N='Cluster';E={ $vmHash["$($_.Key)"].Cluster }}, @{N='Name';E={ $vmHash["$($_.Key)"].Name }}, 
@{N='VmRestartPriority';E={$_.DasSettings.RestartPriority}}, 
@{N='VmStorageProtectionForPDL';E={$_.DasSettings.VmComponentProtectionSettings.VmStorageProtectionForPDL}},
@{N='VmStorageProtectionForAPD';E={$_.DasSettings.VmComponentProtectionSettings.VmStorageProtectionForAPD}}, 
@{N='ApdVmFailoverDelaySeconds';E={$_.DasSettings.VmComponentProtectionSettings.VmTerminateDelayForAPDSec}}, 
@{N='ApdResposeRecovery';E={$_.DasSettings.VmComponentProtectionSettings.VmReactionOnAPDCleared}}

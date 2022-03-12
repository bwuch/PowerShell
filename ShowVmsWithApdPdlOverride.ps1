$vmHash = Get-VM | Select-Object ID, Name, @{N='Cluster';E={$_.VMHost.Parent}} | Group-Object ID -AsHashTable

(Get-Cluster).ExtensionData.ConfigurationEx.DasVmConfig | Select-Object @{N='Cluster';E={ $vmHash["$($_.Key)"].Cluster }}, @{N='Name';E={ $vmHash["$($_.Key)"].Name }}, @{N='VmStorageProtectionForAPD';E={$_.DasSettings.VmComponentProtectionSettings.VmStorageProtectionForAPD}}, @{N='VmStorageProtectionForPDL';E={$_.DasSettings.VmComponentProtectionSettings.VmStorageProtectionForPDL}}

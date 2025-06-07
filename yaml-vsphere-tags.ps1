<#
This script assumes a text files stored at D:\tmp\h375-yaml.txt with the content listed below

AMER_DC_VMS:
- name: it-app-q03
  capability: App
  data_class: Class-4
  server_type: TBD
  solution: TBD
- name: it-db-d07
  capability: DB
  data_class: TBD
  solution: IT
  server_type: Management_Server
#>

# The following code will read that yaml file using the powershell-yaml module, and then see if there are any vSphere Virtual Machines listed in the yaml file which no longer exist as VMs.
# read our yaml file
$yaml = Get-Content D:\tmp\h375-yaml.txt -Raw
$obj = ConvertFrom-Yaml $yaml -Ordered -AllDocuments

# List Names that are in the YAML file but are not in current list of VM names
$obj.AMER_DC_VMS.name |?{$_ -notin (Get-VM).Name}

########################################
# The following code will find any vSphere VMs having a tag from a defined list of tags.
# If any VMs from that list are not in the yaml file, we we append them to the end of the file.

$orderedTagList = 'capability','data_class','server_type','solution'

# read our yaml file
$yaml = Get-Content D:\tmp\h375-yaml.txt -Raw
$obj = ConvertFrom-Yaml $yaml -Ordered -AllDocuments

# convert our 'object' to a hashtable. Key is VM name, value is the yaml item
$currentManagedTags = [ordered]@{}
foreach ($vm in $obj.AMER_DC_VMS) {
    $currentManagedTags[$vm.name] = $vm
}

# Get all the VMs with tags
$tagAssignment = Get-Cluster 'Cluster250' | Get-VM | Get-TagAssignment -Category $orderedTagList | Group-Object -Property Entity -AsHashTable -AsString

# lets loop through all the VMs we don't already have in yaml
foreach ($thisVMTags in ($tagAssignment.GetEnumerator() | ?{$_.Name -notin $obj.AMER_DC_VMS.name} | Sort-Object Name) ) {
  "Looking at VM $($thisVMTags.Name)"
  $thisVMTagsHT = $thisVMTags.Value.Tag | Group-Object -Property Category -AsHashTable -AsString
  $newVM = [ordered]@{
    name    = $thisVMTags.Name
  } # end start of new VM for yaml file

  foreach ($thisManagedTag in $orderedTagList) {
    $newVM.Add($thisManagedTag, $thisVMTagsHT[$thisManagedTag].Name ?? 'TBD')
  } # end loop of managed tags

  $currentManagedTags.Add( $thisVMTags.Name , $newVM )
} # end loop of tagged VMs


# lets update our object with existing + new VMs
$obj.AMER_DC_VMS = $currentManagedTags.Values

# lets turn that back to yaml
$newYaml = $obj | ConvertTo-Yaml

# write it to a file
$newYaml | Out-File -FilePath "D:\tmp\updated_vms.yaml"

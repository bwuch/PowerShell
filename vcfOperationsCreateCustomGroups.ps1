# Login to the API
$acquireTokenAuth = Invoke-RestMethod -Uri 'https://ops.example.com/suite-api/api/auth/token/acquire' -body (@{ username='admin'; password='VMware1!' } | ConvertTo-Json) -Method Post -ContentType 'application/json' -Headers @{accept='application/json'}

# Create a header containing above auth key
$headers = @{accept='application/json'; Authorization="OpsToken $($acquireTokenAuth.token)"}

# Get list of all groups
$groups = Invoke-RestMethod -Uri 'https://ops.example.com/suite-api/api/resources/groups' -ContentType 'application/json' -Headers $headers

# filter the list of custom groups to only contain those belonging to the custom group type we created
$existingOpsGroupNames = ($groups.groups | ?{$_.resourceKey.resourceKindKey -eq 'h263-folderGroup'} | select-object -ExpandProperty resourceKey).name

# Get a list of existing vSphere Folder Names.  We can add additional logic here, including only finding only recently created groups.  More details on filter criteria can be found in swagger UI or from the JSON results of $vmfolders (filter client side).
$vmfolders = Invoke-RestMethod -Uri 'https://ops.example.com/suite-api/api/resources?page=0&pageSize=2000&resourceKind=VMFolder' -ContentType 'application/json' -Headers $headers
$vSphereFolderNames = $vmfolders.resourceList.resourceKey.Name | Select-Object -Unique | ?{$_ -notin 'Discovered virtual machine','vCLS','Templates' -AND $_ -notmatch 'Horizon |^Clone|^vdi|^z_'} | Sort-Object

# Create a loop to go through each folder that exists in vCenter but not in Ops.  Build a Json body to post to ops to create one group per iteration.
foreach ($newGroup in ($vSphereFolderNames | ?{$_ -notin $existingOpsGroupNames})) {
   "will create $newGroup group"
   $newGroupJson = @{ 
      resourceKey=@{ name=$newGroup; adapterKindKey='Container'; resourceKindKey='h263-folderGroup'}
      autoResolveMembership=$true
      membershipDefinition=@{
         rules=@(
            @{ resourceKindKey=@{resourceKind='VirtualMachine'; adapterKind='VMware' } 
               propertyConditionRules=@(
                  @{key='summary|parentFolder'; stringValue=$newGroup; compareOperator='EQ' }
               )
            },
            @{ resourceKindKey=@{resourceKind='VirtualMachine'; adapterKind='VMware' } 
               resourceTagConditionRules=@(
                  @{category='application'; stringValue=$newGroup; compareOperator='EQ' }
               )
            }
         )
      }
   } | ConvertTo-Json -Depth 5

   $newGroupPost = Invoke-RestMethod -Uri 'https://ops.example.com/suite-api/api/resources/groups' -Method Post -body $newGroupJson -ContentType 'application/json' -Headers $headers
   "  New Group: $newGroup created with ID $($newGroupPost.id)"
} # end foreach group loop
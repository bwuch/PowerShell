# connect to vCenter, all of them if we can
connect-viserver vc1.example.com,vc2.example.com -user administrator@vsphere.local -password VMware1!

# Get interesting vmhost properties.  May create a warning as I used Get-EsxCli v1 instead of the newer v2.
$myResults = Get-VMHost -State:Connected | Select-Object Name, @{N='HardwareUUID';E={$_.extensionData.summary.hardware.uuid}}, @{N='SystemUUID';E={(Get-EsxCli -VMHost $_).system.uuid.get()}}, @{N='Parent Name';E={$_.parent.name}}, Version

# Group our results by UUID and if we have any duplicates list out just those rows
# This will list hosts potentially impacted by KB 84349
$myResults |Group-Object -Property SystemUUID |?{$_.Count -gt 1} | Select-Object -ExpandProperty Group

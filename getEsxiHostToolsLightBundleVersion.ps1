# From time to time we need to see the version of the VMware tools that is present on an ESXi host.  The following command will use Get-EsxCli to query for installed VIBs and return the version for tools-light.
Get-VMHost | Sort-Object Name | Select-Object Name, @{N='HostToolsVer';E={(($_|Get-EsxCli -V2).software.vib.list.invoke()|?{$_.Name -eq 'tools-light'}).Version}}

Connect-NsxtServer -Server server.f.q.d.n -User admin -Password VMware1!VMware1!

$profiles = Get-NsxtService -Name com.vmware.nsx.ns_profiles.attributes
$profiles.list().results.ns_attributes.attributes_data |?{$_.key -eq 'DOMAIN_NAME'} | select @{N='DomainName';E={[string]($_.Value)}} | sort-object DomainName |out-file nsxt3domains.txt

# file: vrops_service_check.ps1
# last modified 2016-04-29 1:35pm Eastern
# found during cleanup of temp files, saving to git.

Function Throw-ErrorMessage ([string]$errorEncountered) {
	#write a log, send an email, etc
	Write-Warning "$(Get-Date) $errorEncountered"
}

$vCenter = "192.168.127.180"
$vROps = "192.168.127.184"
$timeWindowMinutes = 10
$errorState = $false

$viConnection = Connect-VIServer $vCenter -user 'administrator@vsphere.local' -password 'VMware1!'
if (!$viConnection.isConnected) {
	Throw-ErrorMessage "Unable to connect to vCenter: $vCenter"
	$errorState = $true
}

$omConnection = Connect-OMServer $vROps -user 'admin' -password 'VMware1!'
if (!$omConnection.isConnected) {
	Throw-ErrorMessage "Unable to connect to vROps instance: $vROps"
	$errorState = $true
}

if ($errorState) {
	write-warning "An Error was encountered somewhere above."
} else {
	Get-VMHost -State:Connected | sort-object Name | select -first 2 | %{
		$thisStat = Get-OMStat -Resource $($_.Name) -key 'cpu:0|usage_average' -From (get-date).addminutes(-$timeWindowMinutes)
		$thisStatCount = ($thisStat | Measure-Object).count
		if ( $thisStatCount -lt 1 ) {
			Throw-ErrorMessage "vROps node $vROps returned no data for $vCenter \ $($_.Name)"
		} else {
			"vROps node $vROps returned $thisStatCount entries for $vCenter \ $($_.Name)"
		}# end measure counts
	} # end host loop
} # end error check

Disconnect-VIServer * -confirm:$false
Disconnect-OMServer * -confirm:$false

$thispage = Invoke-WebRequest -Uri 'https://docs.vmware.com/en/VMware-vSphere/7.0/rn/vsphere-esxi-70u3c-release-notes.html'

$myResults = @()
$cveList = $thispage.ParsedHtml.body.innerText |Select-String -Pattern 'CVE-\d{4}-\d{4,}' -AllMatches | ForEach-Object {$_.matches.value} | Select-Object -Unique | Sort-Object 
if ($cveList) {
  $cveList | ForEach-Object {
    $thisCVE = Invoke-WebRequest -Uri "https://nvd.nist.gov/vuln/detail/$_"
    $myResults += [pscustomobject]@{
      URL   = "https://nvd.nist.gov/vuln/detail/$_"
      CVE   = $_
      CVSS  = try { ($thisCVE.ParsedHtml.body.innerText.split("`n") | Where-Object {$_ -match 'base score: '} | Select-Object -First 1).Replace('Base Score:  ','').Trim() } catch { 'Unknown/Error' }
    } # end custom object 
  }
} else {
  'No CVEs found for given URL.'
}

$myResults | Sort-Object CVSS -Descending

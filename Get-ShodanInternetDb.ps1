Function Get-ShodanInternetDb {
  param(
    [Parameter(Mandatory=$true, Position=0)][string]$ipaddress
  )
  try {
    return (ConvertFrom-Json (Invoke-WebRequest -URI "https://internetdb.shodan.io/$ipaddress"))
  } catch {
    write-error $_
  } # end catch
} # end function

# Get Shodan InternetDB results from a /24 network, must be public addresses, not the 10.10.10.0/24 example below.
$myResults = @()
1..254 | %{
  $myResults += Get-ShodanInternetDb "10.10.10.$_"
}

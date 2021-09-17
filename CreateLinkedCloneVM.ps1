$linkedClone = @{
  LinkedClone		= $true
  Name			= 'bwuch003'
  VM			= 'bwuchner_win19-2'
  ReferenceSnapshot	= 'WindowsUpToDate2'
  OSCustomizationSpec 	= 'bwuchner_win19'
  Notes			= 'Createdas linked clone with customization spec'
  ResourcePool		= 'All Flash Cluster'
}
New-VM @linkedClone | Start-VM

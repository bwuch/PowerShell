# Part 1: https://enterpriseadmins.org/blog/scripting/get-vcenter-scheduled-tasks-with-powercli-part-1/
Function Get-VIScheduledTasks {
PARAM ( [switch]$Full )
if ($Full) {
# Note: When returning the full View of each Scheduled Task, all date times are in UTC
(Get-View ScheduledTaskManager).ScheduledTask | %{ (Get-View $_).Info }
} else {
# By default, lets only return common headers and convert all date/times to local values
(Get-View ScheduledTaskManager).ScheduledTask | %{ (Get-View $_ -Property Info).Info } |
Select-Object Name, Description, Enabled, Notification, LastModifiedUser, State, Entity,
@{N="EntityName";E={ (Get-View $_.Entity -Property Name).Name }},
@{N="LastModifiedTime";E={$_.LastModifiedTime.ToLocalTime()}},
@{N="NextRunTime";E={$_.NextRunTime.ToLocalTime()}},
@{N="PrevRunTime";E={$_.LastModifiedTime.ToLocalTime()}},
@{N="ActionName";E={$_.Action.Name}}
}
}

Function Get-VMScheduledSnapshots {
Get-VIScheduledTasks | ?{$_.ActionName -eq 'CreateSnapshot_Task'} |
Select-Object @{N="VMName";E={$_.EntityName}}, Name, NextRunTime, Notification
}


# Part 2: https://enterpriseadmins.org/blog/scripting/new-vcenter-scheduled-tasks-with-powercli-part-2/
Function New-VMScheduledSnapshot {
PARAM (
[string]$vmName,
[string]$runTime,
[string]$notifyEmail=$null,
[string]$taskName="$vmName Scheduled Snapshot"
)

# Verify we found a single VM
$vm = (get-view -viewtype virtualmachine -property Name -Filter @{"Name"="^$($vmName)$"}).MoRef
if (($vm | Measure-Object).Count -ne 1 ) { "Unable to locate a specific VM $vmName"; break }

# Validate datetime value and convert to UTC
try { $castRunTime = ([datetime]$runTime).ToUniversalTime() } catch { "Unable to convert runtime parameter to date time value"; break }
if ( [datetime]$runTime -lt (Get-Date) ) { "Single run tasks can not be scheduled to run in the past. Please adjust start time and try again."; break }

# Verify the scheduled task name is not already in use
if ( (Get-VIScheduledTasks | ?{$_.Name -eq $taskName } | Measure-Object).Count -eq 1 ) { "Task Name `"$taskName`" already exists. Please try again and specify the taskname parameter"; break }

$spec = New-Object VMware.Vim.ScheduledTaskSpec
$spec.name = $taskName
$spec.description = "Snapshot of $vmName scheduled for $runTime"
$spec.enabled = $true
if ( $notifyEmail ) {$spec.notification = $notifyEmail}
($spec.scheduler = New-Object VMware.Vim.OnceTaskScheduler).runAt = $castRunTime
($spec.action = New-Object VMware.Vim.MethodAction).Name = "CreateSnapshot_Task"
$spec.action.argument = New-Object VMware.Vim.MethodActionArgument[] (4)
($spec.action.argument[0] = New-Object VMware.Vim.MethodActionArgument).Value = "$vmName scheduled snapshot"
($spec.action.argument[1] = New-Object VMware.Vim.MethodActionArgument).Value = "Snapshot created using $taskName"
($spec.action.argument[2] = New-Object VMware.Vim.MethodActionArgument).Value = $false # Snapshot memory
($spec.action.argument[3] = New-Object VMware.Vim.MethodActionArgument).Value = $false # quiesce guest file system (requires VMware Tools)

[Void](Get-View -Id 'ScheduledTaskManager-ScheduledTaskManager').CreateScheduledTask($vm, $spec)
Get-VMScheduledSnapshots | ?{$_.Name -eq $taskName }
}


# Part 3: https://enterpriseadmins.org/blog/scripting/remove-vcenter-scheduled-tasks-with-powercli-part-3/
Function Remove-VIScheduledTask {
PARAM ([string]$taskName)
(Get-View -Id ((Get-VIScheduledTasks -Full | ?{$_.Name -eq $taskName}).ScheduledTask)).RemoveScheduledTask()
}
# Example Usage:
# Get-VMScheduledSnapshots | ?{$_.NextRunTime -eq $null} | %{ Remove-VIScheduledTask $_.Name }

# TriggerWindowsUpdatesByScheduledTask
Powershell solution to create scripts on a list of machines which create a scheduled task that triggers another script that runs the update. It doesn't require the WindowsUpdate PowerShell module which simplifies the implementation in case of machines that don't have internet access.

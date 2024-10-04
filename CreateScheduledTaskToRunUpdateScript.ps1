# Get the current year and month
$year = (Get-Date).Year
$month = (Get-Date).Month

# Define the log file path
$logFilePath = "C:\ProgramData\Updates\InstallUpdateSchedTask$year$month.log"

# Define the action to run the PowerShell script
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\ProgramData\Updates\InstallWindowsUpdates.ps1"

# Define the trigger to run the task every Saturday at 8 AM
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Saturday -At 8:00AM

# Define the principal to run the task with system rights
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Define the settings for the task
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Create the scheduled task
try {
    Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings -TaskName "InstallUpdates" -Description "Runs the InstallWindowsUpdates.ps1 script every Saturday at 8 AM with system rights"
    Add-Content -Path $logFilePath -Value "[$(Get-Date)] Successfully created scheduled task 'InstallUpdates'"
} catch {
    Add-Content -Path $logFilePath -Value "[$(Get-Date)] Failed to create scheduled task 'InstallUpdates'. Error: $_"
}



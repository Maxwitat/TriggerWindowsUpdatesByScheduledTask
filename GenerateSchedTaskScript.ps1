# GenerateUpdateScript
# Define the remote machines
$remoteMachines = @("anveo20.buehnen-gruppe.local",
    "svr1",	
	"svr2",	
	"svr3"
)

# Define the script content
$scriptContent = @'
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
'@

# Define the log file path
$logFilePath = "C:\ProgramData\Updates\SchedTaskInstallation.log"

# Create the log directory if it doesn't exist
if (-not (Test-Path -Path "C:\ProgramData\Updates")) {
    New-Item -ItemType Directory -Path "C:\ProgramData\Updates"
}

# Function to log messages
function Log-Message {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFilePath -Value $logMessage
    Write-Host $logMessage
}

# Log the start of the script creation process
Log-Message "Starting script creation process on remote machines."

# Create the script file on each remote machine
foreach ($machine in $remoteMachines) {
    try {
        Log-Message "Creating script on $machine."
        Invoke-Command -ComputerName $machine -ScriptBlock {
            param ($content)
            $scriptPath = "C:\ProgramData\Updates\CreateSchedTask.ps1"
            if (-not (Test-Path -Path "C:\ProgramData\Updates")) {
                New-Item -ItemType Directory -Path "C:\ProgramData\Updates"
            }
            Set-Content -Path $scriptPath -Value $content
        } -ArgumentList $scriptContent -ErrorAction Stop
        Log-Message "Successfully created script on $machine."
    } catch {
        Log-Message "Failed to create script on $machine. Error: $_"
    }
}

Log-Message "Script creation process completed."

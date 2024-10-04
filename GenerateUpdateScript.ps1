﻿# GenerateUpdateScript
# Define the remote machines
$remoteMachines = @("machine1.sysmanlab.local",
    "machine2.sysmanlab.local",	
	"machine3.sysmanlab.local"
)

# Define the script content
$scriptContent = @'
#---------------------------------------------------------------------------------------
#
# Trigger Installation of Windows Updates
# The script doesn't require the Powershell module for Windows updates
# It log to C:\ProgramData\Updates
# Version 1.0.0, Frank Maxwitat, 04.10.2024 
#
#---------------------------------------------------------------------------------------

Function Get-PendingRebootStatus 
{
#     Author: theSysadminChanne

    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0
        )]
    [string[]]  $ComputerName = $env:COMPUTERNAME
    )

    BEGIN {}

    PROCESS {
        Foreach ($Computer in $ComputerName) {
            Try {
                $PendingReboot = $false

                $HKLM = [UInt32] "0x80000002"
                $WMI_Reg = [WMIClass] "\\$Computer\root\default:StdRegProv"

                if ($WMI_Reg) {
                    if (($WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\")).sNames -contains 'RebootPending') {$PendingReboot = $true}
                    if (($WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")).sNames -contains 'RebootRequired') {$PendingReboot = $true}

                    #Checking for SCCM namespace
                    $SCCM_Namespace = Get-WmiObject -Namespace ROOT\CCM\ClientSDK -List -ComputerName $Computer -ErrorAction Ignore
                    if ($SCCM_Namespace) {
                        if (([WmiClass]"\\$Computer\ROOT\CCM\ClientSDK:CCM_ClientUtilities").DetermineIfRebootPending().RebootPending -eq $true) {$PendingReboot = $true}
                    }

                    if ($PendingReboot -eq $true) {
                        [PSCustomObject]@{
                            ComputerName   = $Computer.ToUpper()
                            PendingReboot  = $true
                        }
                      } else {
                        [PSCustomObject]@{
                            ComputerName   = $Computer.ToUpper()
                            PendingReboot  = $false
                        }
                    }
                }
            } catch {
                Write-Error $_.Exception.Message
            } finally {
                #Clearing Variables
                $WMI_Reg        = $null
                $SCCM_Namespace = $null
            }
        }
    }
    END {}
}

$logFilePath = "C:\ProgramData\Updates\WindowsUpdateInfo$(Get-Date -Format 'yyyyMM').log"

if (-not (Test-Path -Path "C:\ProgramData\Updates")) {
    New-Item -ItemType Directory -Path "C:\ProgramData\Updates"
}

function Log-Message {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFilePath -Value $logMessage
}

Log-Message "Starting Windows Update installation process."

$updateSession = New-Object -ComObject Microsoft.Update.Session
$updateSearcher = $updateSession.CreateUpdateSearcher()
$searchResult = $updateSearcher.Search("IsAssigned=1")

if ($searchResult.Updates.Count -eq 0) {
    Log-Message "No assigned updates found."
} else {
    Log-Message "$($searchResult.Updates.Count) assigned updates found."

    $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
    foreach ($update in $searchResult.Updates) {
        $updatesToInstall.Add($update) | Out-Null
    }

    $updateInstaller = $updateSession.CreateUpdateInstaller()
    $updateInstaller.Updates = $updatesToInstall
    $installationResult = $updateInstaller.Install()

    foreach ($update in $installationResult.ResultCode) {
        Log-Message "Update installation result: $update"
    }

    Log-Message "Windows Update installation process completed."

    if(Get-PendingRebootStatus -ComputerName $env:ComputerName)
    {
        Log-Message "Reboot required - restarting now"
        Restart-Computer -force
    }
}
'@

# Define the log file path
$logFilePath = "C:\ProgramData\Updates\TriggerUpdateInstallation.log"

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
            $scriptPath = "C:\ProgramData\Updates\InstallWindowsUpdates.ps1"
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

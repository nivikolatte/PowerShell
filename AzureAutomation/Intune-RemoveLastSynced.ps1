<#
.SYNOPSIS
This script identifies and removes devices of a specified OS type that have not synced with Intune for a specified number of days.

.DESCRIPTION
This script identifies devices that have not synced with Intune for a specified number of days and optionally removes them from Intune.
It retrieves devices from Microsoft Graph API, filters them based on OS type and LastSyncDateTime, and can perform removal actions.

This script was developed with assistance from GitHub Copilot to optimize Azure Automation workflows.

.PARAMETER tenantId
The Azure AD tenant ID.

.PARAMETER clientId
The application (client) ID of the app registration.

.PARAMETER OS
The operating system to filter devices by. Valid values are "Linux", "Windows", "macOS", or "All".
Linux is recommended for targeting Linux devices.

.PARAMETER InactiveDays
The number of days since the last sync to consider a device inactive.

.PARAMETER RunMode
The mode to run the script in:
- "WhatIf": Shows what would be removed without taking action
- "Remove": Performs actual device removal

.PARAMETER Force
When set to true, bypasses confirmation prompts for device removal.

.NOTES
SECURITY NOTE: This script retrieves the client secret from an Azure Automation encrypted variable named "ClientSecret".
You must create this variable in your Automation Account before running the script.

CAUTION: This script can permanently remove devices from Intune. Use with care.

AUTHOR: Created and edited with GitHub Copilot
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$tenantId,
    
    [Parameter(Mandatory=$true)]
    [string]$clientId,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("Linux", "Windows", "macOS", "All")]
    [string]$OS,
    
    [Parameter(Mandatory=$true)]
    [int]$InactiveDays,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("WhatIf", "Remove")]
    [string]$RunMode,
    
    [Parameter(Mandatory=$true)]
    [bool]$Force
)

# Determine if we're in WhatIf mode
$whatIfMode = ($RunMode -eq "WhatIf")

if ($whatIfMode) {
    Write-Output "Running in WHATIF mode - no devices will be removed"
} else {
    Write-Output "Running in REMOVAL mode - devices WILL be removed!"
}

if ($Force) {
    Write-Output "Force mode enabled - no confirmation will be required"
}

# Get the client secret from Automation Variables
try {
    $clientSecret = Get-AutomationVariable -Name 'ClientSecret'
    if ([string]::IsNullOrEmpty($clientSecret)) {
        throw "ClientSecret automation variable is empty"
    }
} catch {
    Write-Error "Failed to retrieve ClientSecret from Automation Variables: $_"
    Write-Error "Make sure you've created an encrypted Automation Variable named 'ClientSecret' in your Automation Account."
    exit 1
}

# Calculate threshold date
$thresholdDate = (Get-Date).AddDays(-$InactiveDays).ToString("yyyy-MM-ddTHH:mm:ssZ")
Write-Output "Looking for inactive $OS devices since: $thresholdDate"

# Get access token
try {
    $tokenBody = @{
        grant_type    = "client_credentials"
        client_id     = $clientId
        client_secret = $clientSecret
        scope         = "https://graph.microsoft.com/.default"
    }
    $tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Body $tokenBody
    $headers = @{ Authorization = "Bearer $($tokenResponse.access_token)" }
    Write-Output "Successfully authenticated with Microsoft Graph API"
} catch {
    Write-Error "Authentication failed: $_"
    Write-Error "Verify that your tenantId, clientId, and ClientSecret are correct and that the app has the required permissions."
    exit 1
}

# Set filter based on operating system parameter
$filter = if ($OS -eq "All") { "" } else { "operatingSystem eq '$OS'" }
$filterParam = if ($filter) { "`$filter=$filter&" } else { "" }

# Get devices with specific fields using query parameters
# Include id field which is needed for deletion
$select = "id,deviceName,lastSyncDateTime,operatingSystem,osVersion"
$url = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?${filterParam}`$select=$select"

try {
    Write-Output "Retrieving devices from Microsoft Intune..."
    
    $allDevices = @()
    do {
        $response = Invoke-RestMethod -Method Get -Uri $url -Headers $headers
        $allDevices += $response.value
        $url = $response.'@odata.nextLink'
    } while ($url) # Handle pagination
    
    Write-Output "Retrieved $($allDevices.Count) total devices"
    
    # Filter inactive devices
    $inactiveDevices = $allDevices | Where-Object { 
        [DateTime]$_.lastSyncDateTime -lt $thresholdDate
    } | Sort-Object lastSyncDateTime
    
    # Output results
    if ($inactiveDevices.Count -eq 0) {
        Write-Output "No inactive $OS devices found. No action needed."
        exit 0
    } else {
        Write-Output "Found $($inactiveDevices.Count) inactive $OS devices:"
        
        # Create a formatted table for better readability in runbook output
        $formattedResults = $inactiveDevices | ForEach-Object {
            [PSCustomObject]@{
                DeviceID = $_.id
                DeviceName = $_.deviceName
                OS = "$($_.operatingSystem) $($_.osVersion)"
                LastSync = $_.lastSyncDateTime
                DaysSinceSync = [math]::Round(((Get-Date) - [DateTime]$_.lastSyncDateTime).TotalDays, 1)
            }
        }
        
        # Output the results in a readable format
        $formattedResults | Format-Table -Property DeviceName, OS, LastSync, DaysSinceSync -AutoSize | Out-String | Write-Output
        
        # Output device count by OS for summary
        $osSummary = $inactiveDevices | Group-Object -Property operatingSystem | 
                     Select-Object @{Name='OS';Expression={$_.Name}}, @{Name='Count';Expression={$_.Count}}
        
        Write-Output "`nSummary by OS:"
        $osSummary | ForEach-Object {
            Write-Output "$($_.OS): $($_.Count) devices"
        }
        
        # Proceed with removal if not in WhatIf mode
        if (-not $whatIfMode) {
            # Confirm removal unless Force is specified
            $proceedWithRemoval = $Force
            
            if (-not $Force) {
                # In Azure Automation, we can't prompt interactively, so we'll use a variable
                $confirmationVariable = Get-AutomationVariable -Name 'ConfirmDeviceRemoval' -ErrorAction SilentlyContinue
                if ($confirmationVariable -eq 'Yes') {
                    $proceedWithRemoval = $true
                    Write-Output "Proceeding with removal based on ConfirmDeviceRemoval variable."
                } else {
                    Write-Output "Removal not confirmed. Set the ConfirmDeviceRemoval Automation variable to 'Yes' to proceed with removal."
                    Write-Output "Alternatively, run the script with Force=true to bypass confirmation."
                    exit 0
                }
            }
            
            if ($proceedWithRemoval) {
                Write-Output "`nRemoving $($inactiveDevices.Count) inactive devices..."
                
                $successCount = 0
                $failureCount = 0
                
                foreach ($device in $inactiveDevices) {
                    try {
                        $deviceId = $device.id
                        $deviceName = $device.deviceName
                        
                        Write-Output "Removing device: $deviceName (ID: $deviceId)..."
                        
                        # Delete the device using Microsoft Graph API
                        $deleteUrl = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$deviceId"
                        Invoke-RestMethod -Method Delete -Uri $deleteUrl -Headers $headers
                        
                        Write-Output "Successfully removed device: $deviceName"
                        $successCount++
                    } catch {
                        Write-Error "Failed to remove device $($device.deviceName): $_"
                        $failureCount++
                    }
                }
                
                Write-Output "`nRemoval Summary:"
                Write-Output "- Successfully removed: $successCount devices"
                Write-Output "- Failed to remove: $failureCount devices"
            }
        } else {
            Write-Output "`nWHATIF MODE: No devices were removed."
            Write-Output "To remove these devices, run with RunMode='Remove'"
        }
    }
} catch {
    Write-Error "Failed to retrieve or process devices: $_"
    exit 1
}

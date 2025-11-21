<#
.SYNOPSIS
    Tag inactive devices in Microsoft Defender - Azure Runbook with Variables
.DESCRIPTION
    Retrieves devices from Defender API and tags inactive devices
    Uses Azure Automation Variables for secure credential storage
.PARAMETER DaysInactive
    Minimum days inactive to tag (0 = all inactive)
.PARAMETER MaxDaysInactive
    Maximum days inactive to tag (default: 9999)
.PARAMETER TagName
    Tag to apply (default: company:asset-tag:Inactive)
.PARAMETER IncludeStale
    Include devices inactive 365+ days (default: true)
.NOTES
    Required Variables in Automation Account:
    - DefenderTenantId (encrypted)
    - DefenderAppId (encrypted)
    - DefenderAppSecret (encrypted)
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$DaysInactive = 0,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxDaysInactive = 9999,
    
    [Parameter(Mandatory=$false)]
    [string]$TagName = "company:asset-tag:Inactive",
    
    [Parameter(Mandatory=$false)]
    [bool]$IncludeStale = $true
)

$ErrorActionPreference = "Stop"
$startTime = Get-Date

Write-Output "============================================"
Write-Output "Defender Device Tagging - Azure Runbook"
Write-Output "Started: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output "============================================"
Write-Output ""

# Get credentials from Automation Variables
Write-Output "[1/6] Retrieving credentials from Automation Variables..."
try {
    $TenantId = Get-AutomationVariable -Name 'DefenderTenantId'
    $AppId = Get-AutomationVariable -Name 'DefenderAppId'
    $AppSecret = Get-AutomationVariable -Name 'DefenderAppSecret'
    
    if (-not $TenantId -or -not $AppId -or -not $AppSecret) {
        throw "One or more required variables are missing or empty"
    }
    
    Write-Output "  Retrieved credentials successfully"
} catch {
    Write-Error "Failed to retrieve Automation Variables: $($_.Exception.Message)"
    Write-Error "Required variables: DefenderTenantId, DefenderAppId, DefenderAppSecret"
    throw
}

# Authenticate
Write-Output ""
Write-Output "[2/6] Authenticating with Defender API..."
try {
    $authBody = @{
        Grant_Type    = "client_credentials"
        Scope         = "https://api.securitycenter.microsoft.com/.default"
        Client_Id     = $AppId
        Client_Secret = $AppSecret
    }
    
    $authResponse = Invoke-RestMethod -Method Post `
        -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
        -Body $authBody `
        -ContentType "application/x-www-form-urlencoded"
    
    $headers = @{
        'Authorization' = "Bearer $($authResponse.access_token)"
        'Content-Type' = 'application/json'
    }
    
    Write-Output "  Authenticated successfully"
    Write-Output "  Token expires: $($authResponse.expires_in) seconds"
} catch {
    Write-Error "Authentication failed: $($_.Exception.Message)"
    throw
}

# Retrieve all devices
Write-Output ""
Write-Output "[3/6] Retrieving devices from Defender API..."
$allDevices = [System.Collections.ArrayList]::new()
$nextLink = "https://api.securitycenter.microsoft.com/api/machines"
$pageCount = 0

try {
    do {
        $pageCount++
        $response = Invoke-RestMethod -Method Get -Uri $nextLink -Headers $headers
        [void]$allDevices.AddRange($response.value)
        $nextLink = $response.'@odata.nextLink'
        
        if ($pageCount % 5 -eq 0) {
            Write-Output "  Retrieved $($allDevices.Count) devices..."
        }
    } while ($nextLink)
    
    Write-Output "  Total devices: $($allDevices.Count)"
} catch {
    Write-Error "Failed to retrieve devices: $($_.Exception.Message)"
    throw
}

# Analyze devices
Write-Output ""
Write-Output "[4/6] Analyzing device health status..."

$allInactive = $allDevices | Where-Object { $_.healthStatus -eq 'Inactive' }

$breakdown = @{
    Recent = ($allInactive | Where-Object { $_.lastSeen -and ((Get-Date) - [DateTime]$_.lastSeen).TotalDays -le 30 }).Count
    MediumTerm = ($allInactive | Where-Object { $_.lastSeen -and ((Get-Date) - [DateTime]$_.lastSeen).TotalDays -gt 30 -and ((Get-Date) - [DateTime]$_.lastSeen).TotalDays -le 90 }).Count
    LongTerm = ($allInactive | Where-Object { $_.lastSeen -and ((Get-Date) - [DateTime]$_.lastSeen).TotalDays -gt 90 -and ((Get-Date) - [DateTime]$_.lastSeen).TotalDays -le 365 }).Count
    VeryStale = ($allInactive | Where-Object { $_.lastSeen -and ((Get-Date) - [DateTime]$_.lastSeen).TotalDays -gt 365 }).Count
    NoLastSeen = ($allInactive | Where-Object { -not $_.lastSeen }).Count
}

Write-Output "  Total inactive: $($allInactive.Count)"
Write-Output "    0-30 days:    $($breakdown.Recent)"
Write-Output "    31-90 days:   $($breakdown.MediumTerm)"
Write-Output "    91-365 days:  $($breakdown.LongTerm)"
Write-Output "    365+ days:    $($breakdown.VeryStale)"
Write-Output "    No lastSeen:  $($breakdown.NoLastSeen)"

# Filter devices to tag
$inactiveDevices = $allInactive | Where-Object {
    if ($_.machineTags -contains $TagName) { return $false }
    
    if (-not $_.lastSeen) {
        return $IncludeStale
    }
    
    $daysSince = ((Get-Date) - [DateTime]$_.lastSeen).TotalDays
    
    $withinMinimum = ($DaysInactive -eq 0) -or ($daysSince -ge $DaysInactive)
    $withinMaximum = ($daysSince -le $MaxDaysInactive)
    
    if ($daysSince -gt 365 -and -not $IncludeStale) {
        return $false
    }
    
    return $withinMinimum -and $withinMaximum
}

$devicesToTag = @($inactiveDevices.id)

Write-Output ""
Write-Output "[5/6] Filtering results..."
Write-Output "  Matching filter: $($inactiveDevices.Count)"
Write-Output "  Already tagged: $($allInactive.Count - $inactiveDevices.Count)"
Write-Output "  To tag: $($devicesToTag.Count)"

if ($devicesToTag.Count -eq 0) {
    Write-Output ""
    Write-Output "No devices to tag. Exiting."
    $duration = (Get-Date) - $startTime
    Write-Output "Duration: $($duration.ToString('mm\:ss'))"
    exit 0
}

# Tag devices in batches
Write-Output ""
Write-Output "[6/6] Tagging devices..."
Write-Output "  Tag: $TagName"
Write-Output "  Batch size: 500 devices"

$batchSize = 500
$successCount = 0
$failCount = 0
$totalBatches = [Math]::Ceiling($devicesToTag.Count / $batchSize)

for ($i = 0; $i -lt $devicesToTag.Count; $i += $batchSize) {
    $currentBatch = [Math]::Floor($i / $batchSize) + 1
    $batchEnd = [Math]::Min($i + $batchSize - 1, $devicesToTag.Count - 1)
    $batch = $devicesToTag[$i..$batchEnd]
    
    $tagBody = @{
        Value = $TagName
        Action = "Add"
        MachineIds = $batch
    } | ConvertTo-Json -Compress
    
    try {
        Invoke-RestMethod -Method Post `
            -Uri "https://api.securitycenter.microsoft.com/api/machines/AddOrRemoveTagForMultipleMachines" `
            -Headers $headers `
            -Body $tagBody | Out-Null
        
        $successCount += $batch.Count
        Write-Output "  Batch $currentBatch/$totalBatches - Success ($successCount/$($devicesToTag.Count))"
        
    } catch {
        $failCount += $batch.Count
        
        if ($_.Exception.Response.StatusCode -eq 429) {
            Write-Output "  Batch $currentBatch/$totalBatches - Rate limited, waiting 60s..."
            Start-Sleep -Seconds 60
            
            try {
                Invoke-RestMethod -Method Post `
                    -Uri "https://api.securitycenter.microsoft.com/api/machines/AddOrRemoveTagForMultipleMachines" `
                    -Headers $headers `
                    -Body $tagBody | Out-Null
                
                $successCount += $batch.Count
                $failCount -= $batch.Count
                Write-Output "  Batch $currentBatch/$totalBatches - Retry success"
            } catch {
                Write-Output "  Batch $currentBatch/$totalBatches - Retry failed: $($_.Exception.Message)"
            }
        } else {
            Write-Output "  Batch $currentBatch/$totalBatches - Failed: $($_.Exception.Message)"
        }
    }
    
    Start-Sleep -Milliseconds 500
}

# Summary
$duration = (Get-Date) - $startTime
$successRate = if ($devicesToTag.Count -gt 0) { [Math]::Round(($successCount / $devicesToTag.Count) * 100, 2) } else { 0 }

Write-Output ""
Write-Output "============================================"
Write-Output "COMPLETE"
Write-Output "============================================"
Write-Output "Devices tagged: $successCount/$($devicesToTag.Count) ($successRate%)"
Write-Output "Failed: $failCount"
Write-Output "Duration: $($duration.ToString('mm\:ss'))"
Write-Output "Completed: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output "============================================"

<#
.SYNOPSIS
    Tag Defender devices by Azure Subscription
    DefenderTenantId , DefenderAppId, DefenderAppSecret varaibles needs to be created in Azure Automation Account
.PARAMETER SubscriptionIds
    Comma-separated Azure Subscription IDs
.PARAMETER TagName
    Tag to apply
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionIds = "",
    
    [Parameter(Mandatory=$false)]
    [string]$TagName = ""
)

$ErrorActionPreference = "Stop"

# Parse subscriptions
$subscriptionList = $SubscriptionIds -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }

if ($subscriptionList.Count -eq 0 -or [string]::IsNullOrWhiteSpace($TagName)) {
    Write-Error "SubscriptionIds and TagName are required"
    exit 1
}

# Get credentials
$TenantId = Get-AutomationVariable -Name 'DefenderTenantId'
$AppId = Get-AutomationVariable -Name 'DefenderAppId'
$AppSecret = Get-AutomationVariable -Name 'DefenderAppSecret'

# Authenticate
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

# Get all devices
$allDevices = [System.Collections.ArrayList]::new()
$nextLink = "https://api.securitycenter.microsoft.com/api/machines"

do {
    $response = Invoke-RestMethod -Method Get -Uri $nextLink -Headers $headers
    [void]$allDevices.AddRange($response.value)
    $nextLink = $response.'@odata.nextLink'
} while ($nextLink)

# Filter by subscription
$matchingDevices = $allDevices | Where-Object { 
    $_.vmMetadata -and 
    $_.vmMetadata.subscriptionId -and
    $subscriptionList -contains $_.vmMetadata.subscriptionId
}

# Filter already tagged
$devicesToTag = $matchingDevices | Where-Object { 
    $_.machineTags -notcontains $TagName 
}

Write-Output "Total: $($allDevices.Count) | Matched: $($matchingDevices.Count) | To tag: $($devicesToTag.Count)"

if ($devicesToTag.Count -eq 0) {
    Write-Output "Nothing to tag"
    exit 0
}

# Tag devices
$deviceIds = @($devicesToTag.id)
$batchSize = 500
$successCount = 0

for ($i = 0; $i -lt $deviceIds.Count; $i += $batchSize) {
    $batchEnd = [Math]::Min($i + $batchSize - 1, $deviceIds.Count - 1)
    $batch = $deviceIds[$i..$batchEnd]
    
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
        
    } catch {
        if ($_.Exception.Response.StatusCode -eq 429) {
            Start-Sleep -Seconds 60
            Invoke-RestMethod -Method Post `
                -Uri "https://api.securitycenter.microsoft.com/api/machines/AddOrRemoveTagForMultipleMachines" `
                -Headers $headers `
                -Body $tagBody | Out-Null
            $successCount += $batch.Count
        }
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Output "Tagged: $successCount/$($deviceIds.Count)"

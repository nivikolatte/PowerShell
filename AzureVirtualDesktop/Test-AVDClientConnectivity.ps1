# ============================================================================
# Azure Virtual Desktop Client Connectivity Test Script
# ============================================================================
# Purpose: Tests outbound connectivity from client machines to Azure Virtual Desktop services
# Use Case: Verify if corporate firewall allows AVD connections from physical machines
# Author: Nivi Kolatte (with GitHub Copilot assistance)
# Version: 3.0
# Date: June 13, 2025
# 
# DISCLAIMER:
#   This script is provided "AS IS" with no warranties, express or implied.
#   Use at your own risk. Test thoroughly before using in production.
#   The author assumes no responsibility for any issues or damages.
# 
# USAGE:
#   powershell -ExecutionPolicy Bypass -File Test-AVDClientConnectivity.ps1
#   Test-AVDClientConnectivity.ps1 -SkipOptional -OutputPath "C:\Reports"
#
# TESTS:
#   - DNS resolution for critical AVD endpoints
#   - TCP connectivity on port 443 (HTTPS)
#   - HTTPS/SSL handshake validation
#   - Private Link configuration detection
# ============================================================================

param(
    [switch]$SkipOptional,
    [string]$OutputPath = $env:TEMP
)

# Configuration: Critical URLs for Azure Virtual Desktop client connectivity
$AvdEndpoints = @{
    "Core AVD Services" = @(
        "rdweb.wvd.microsoft.com",      # Web access to workspace
        "rdgateway.wvd.microsoft.com",  # RDP gateway for connections
        "rdbroker.wvd.microsoft.com"    # Connection broker service
    )
    
    "Authentication Services" = @(
        "login.microsoftonline.com",    # Microsoft authentication
        "logincdn.msauth.net",          # Authentication CDN
        "login.live.com"                # Microsoft account sign-in
    )
    
    "Client Services" = @(
        "go.microsoft.com",             # Microsoft redirects
        "aka.ms",                       # Microsoft URL shortener
        "learn.microsoft.com",          # Documentation links
        "privacy.microsoft.com"         # Privacy policy
    )
    
    "Application Services" = @(
        "graph.microsoft.com",          # Microsoft Graph API
        "windows.cloud.microsoft",      # Windows Cloud services
        "windows365.microsoft.com",     # Windows 365 integration
        "ecs.office.com"                # Office connection center
    )
    
    "Certificate Validation" = @(
        "oneocsp.microsoft.com",        # Certificate revocation
        "www.microsoft.com"             # Certificate validation
    )
    
    "Optional Services" = @(
        "*.cdn.office.net",             # Client updates (wildcard)
        "privatelink.wvd.microsoft.com" # Private Link DNS (if enabled)
    )
}

# ====================
# SCRIPT INITIALIZATION
# ====================

Write-Host "Azure Virtual Desktop Client Connectivity Test" -ForegroundColor Cyan
Write-Host "Testing connectivity to AVD services..." -ForegroundColor Yellow
Write-Host ""

# Flatten endpoints for testing
$AllUrls = @()
foreach ($category in $AvdEndpoints.Keys) {
    if ($SkipOptional -and $category -eq "Optional Services") {
        continue
    }
    $AllUrls += $AvdEndpoints[$category]
}

Write-Host "Total endpoints to test: $($AllUrls.Count)" -ForegroundColor Green
Write-Host ""

# ====================
# PRIVATE LINK DETECTION
# ====================

function Test-PrivateLinkConfiguration {
    Write-Host "Checking for Private Link configuration..." -ForegroundColor Yellow
    
    try {
        $privateEndpoints = Resolve-DnsName "privatelink.wvd.microsoft.com" -ErrorAction SilentlyContinue 2>$null
        if ($null -eq $privateEndpoints -or $privateEndpoints.Count -eq 0) {
            Write-Host "  Private Link DNS not configured - testing public endpoints" -ForegroundColor Cyan
            return $false
        } else {
            Write-Host "  Private Link DNS detected - testing both public and private endpoints" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "  Private Link DNS not configured - testing public endpoints" -ForegroundColor Cyan
        return $false
    }
}

$privateLinkEnabled = Test-PrivateLinkConfiguration
Write-Host ""

# ====================
# CONNECTIVITY TESTING FUNCTIONS
# ====================

function Test-DnsResolution {
    param([string]$Hostname)
    
    try {
        $resolved = [System.Net.Dns]::GetHostAddresses($Hostname)
        return @{
            Success = $true
            IPAddresses = $resolved.IPAddressToString
            Message = "Success - IP(s): $($resolved.IPAddressToString -join ', ')"
        }
    } catch {
        return @{
            Success = $false
            IPAddresses = @()
            Message = "Failed - $($_.Exception.Message)"
        }
    }
}

function Test-TcpConnectivity {
    param(
        [string]$Hostname,
        [int]$Port = 443,
        [int]$TimeoutMs = 5000
    )
    
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    try {
        $asyncResult = $tcpClient.BeginConnect($Hostname, $Port, $null, $null)
        $wait = $asyncResult.AsyncWaitHandle.WaitOne($TimeoutMs, $false)
        
        if ($wait -and $tcpClient.Connected) {
            $tcpClient.EndConnect($asyncResult)
            return @{
                Success = $true
                Message = "Success"
            }
        } else {
            return @{
                Success = $false
                Message = "Failed (Timeout)"
            }
        }
    } catch {
        return @{
            Success = $false
            Message = "Failed - $($_.Exception.Message)"
        }
    } finally {
        if ($tcpClient.Connected) {
            $tcpClient.Close()
        }
        $tcpClient.Dispose()
    }
}

function Test-HttpsConnectivity {
    param(
        [string]$Hostname,
        [int]$TimeoutMs = 10000
    )
    
    try {
        $webRequest = [System.Net.WebRequest]::Create("https://$Hostname")
        $webRequest.Timeout = $TimeoutMs
        $webRequest.Method = "HEAD"
        $response = $webRequest.GetResponse()
        $statusCode = [int]$response.StatusCode
        $response.Close()
        
        return @{
            Success = $true
            Message = "Success (Status: $statusCode)"
        }
    } catch {
        return @{
            Success = $false
            Message = "Failed - $($_.Exception.Message)"
        }
    }
}

# ====================
# MAIN TESTING LOOP
# ====================

$results = @()

foreach ($url in $AllUrls) {
    Write-Host "Testing: $url" -ForegroundColor White
    
    # Skip wildcard URLs (they can't be tested directly)
    if ($url.StartsWith("*")) {
        Write-Host "  Skipping wildcard URL - manually verify firewall allows *.domain.com" -ForegroundColor Yellow
        continue
    }
    
    # Parse URL and port
    if ($url -match "^(.*):(\d+)$") {
        $hostname = $matches[1]
        $port = [int]$matches[2]
    } else {
        $hostname = $url
        $port = 443
    }

    # Initialize result object
    $result = [PSCustomObject]@{
        Hostname = $hostname
        Port = $port
        DNSResolution = "Failed"
        IPAddresses = @()
        TCPConnectivity = "Failed"
        HTTPSConnectivity = "Not Tested"
    }

    # Test DNS resolution
    $dnsTest = Test-DnsResolution -Hostname $hostname
    if ($dnsTest.Success) {
        $result.DNSResolution = "Success"
        $result.IPAddresses = $dnsTest.IPAddresses
        Write-Host "  DNS Resolution: $($dnsTest.Message)" -ForegroundColor Green
        
        # Test TCP connectivity
        $tcpTest = Test-TcpConnectivity -Hostname $hostname -Port $port
        if ($tcpTest.Success) {
            $result.TCPConnectivity = "Success"
            Write-Host "  TCP connectivity to port ${port}: $($tcpTest.Message)" -ForegroundColor Green
            
            # Test HTTPS connectivity for port 443
            if ($port -eq 443) {
                $httpsTest = Test-HttpsConnectivity -Hostname $hostname
                $result.HTTPSConnectivity = $httpsTest.Message
                $color = if ($httpsTest.Success) { "Green" } else { "Yellow" }
                Write-Host "  HTTPS connectivity: $($httpsTest.Message)" -ForegroundColor $color
            }
        } else {
            Write-Host "  TCP connectivity to port ${port}: $($tcpTest.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  DNS Resolution: $($dnsTest.Message)" -ForegroundColor Red
    }
    
    $results += $result
    Write-Host ""
}

# ====================
# RESULTS ANALYSIS
# ====================

# ====================
# RESULTS ANALYSIS
# ====================

function Get-ConnectivitySummary {
    param($TestResults, $PrivateLinkEnabled)
    
    # Filter out expected Private Link failures when not enabled
    $filteredResults = $TestResults
    if (-not $PrivateLinkEnabled) {
        $filteredResults = $TestResults | Where-Object { $_.Hostname -ne "privatelink.wvd.microsoft.com" }
    }
    
    $successCount = ($filteredResults | Where-Object { $_.DNSResolution -eq "Success" -and $_.TCPConnectivity -eq "Success" }).Count
    $totalCount = $filteredResults.Count
    
    return @{
        SuccessCount = $successCount
        TotalCount = $totalCount
        FilteredResults = $filteredResults
        IsSuccess = ($successCount -eq $totalCount)
    }
}

function Show-FailureDetails {
    param($FilteredResults)
    
    $failedDNS = $FilteredResults | Where-Object { $_.DNSResolution -eq "Failed" }
    $failedTCP = $FilteredResults | Where-Object { $_.DNSResolution -eq "Success" -and $_.TCPConnectivity -eq "Failed" }

    if ($failedDNS.Count -gt 0) {
        Write-Host "DNS Resolution Failures:" -ForegroundColor Red
        $failedDNS | ForEach-Object { Write-Host "  - $($_.Hostname)" -ForegroundColor Red }
        Write-Host ""
    }

    if ($failedTCP.Count -gt 0) {
        Write-Host "TCP Connectivity Failures:" -ForegroundColor Red
        $failedTCP | ForEach-Object { Write-Host "  - $($_.Hostname):$($_.Port)" -ForegroundColor Red }
        Write-Host ""
    }
}

function Show-Recommendations {
    param($HasFailures, $PrivateLinkEnabled)
    
    if ($HasFailures) {
        Write-Host "Firewall Configuration Required:" -ForegroundColor Yellow
        Write-Host "  1. Allow outbound HTTPS (443) to failed domains" -ForegroundColor White
        Write-Host "  2. Verify DNS resolution for failed endpoints" -ForegroundColor White
        Write-Host "  3. Check proxy server configuration" -ForegroundColor White
        Write-Host "  4. Contact network administrator for firewall allowlisting" -ForegroundColor White
        
        if ($PrivateLinkEnabled) {
            Write-Host ""
            Write-Host "Private Link Configuration:" -ForegroundColor Magenta
            Write-Host "  • Ensure VPN/ExpressRoute connectivity to Azure VNet" -ForegroundColor White
            Write-Host "  • Verify private DNS zone configuration" -ForegroundColor White
        }
    } else {
        Write-Host "SUCCESS: All Azure Virtual Desktop endpoints are accessible!" -ForegroundColor Green
        Write-Host "Corporate firewall configuration appears correct for AVD." -ForegroundColor Green
    }
}

# Generate and display summary
Write-Host "=== CONNECTIVITY TEST SUMMARY ===" -ForegroundColor Cyan

$summary = Get-ConnectivitySummary -TestResults $results -PrivateLinkEnabled $privateLinkEnabled
$statusColor = if ($summary.IsSuccess) { "Green" } else { "Yellow" }

Write-Host "Overall Status: $($summary.SuccessCount)/$($summary.TotalCount) endpoints accessible" -ForegroundColor $statusColor
Write-Host ""

Show-FailureDetails -FilteredResults $summary.FilteredResults
Show-Recommendations -HasFailures (-not $summary.IsSuccess) -PrivateLinkEnabled $privateLinkEnabled

# ====================
# EXPORT RESULTS
# ====================

# Export results to CSV
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$exportPath = Join-Path $OutputPath "AVD_Connectivity_Results_$timestamp.csv"
$results | Export-Csv -Path $exportPath -NoTypeInformation
Write-Host ""
Write-Host "Results exported to: $exportPath" -ForegroundColor Cyan

Write-Host ""
Write-Host "For Azure Virtual Desktop networking requirements:" -ForegroundColor Cyan
Write-Host "https://learn.microsoft.com/azure/virtual-desktop/required-fqdn-endpoint" -ForegroundColor Blue

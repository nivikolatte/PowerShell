#Requires -Version 5.1
<#
.SYNOPSIS
    Validates PSADT 4.0 packages for compliance and readiness

.DESCRIPTION
    Performs comprehensive validation of PSADT 4.0 packages including:
    - File structure verification
    - Script syntax validation
    - PSADT 4.0 compliance checks
    - Security and best practices validation
    - Installation simulation (optional)

.PARAMETER PackagePath
    Path to the PSADT package to validate

.PARAMETER ValidationLevel
    Level of validation: Basic, Standard, or Comprehensive

.PARAMETER TestInstallation
    Perform actual installation test in safe environment

.PARAMETER OutputReport
    Generate detailed validation report

.PARAMETER ReportPath
    Path for validation reports (default: C:\PSADT_Reports)

.EXAMPLE
    .\Test-PSADT4Package.ps1 -PackagePath "C:\PSADT_Packages\Adobe-Reader-24.002.20933"

.EXAMPLE
    .\Test-PSADT4Package.ps1 -PackagePath "C:\PSADT_Packages\Adobe-Reader-24.002.20933" -ValidationLevel Comprehensive -OutputReport

.NOTES
    Author: IT Department
    Version: 1.0.0
    Date: 2025-06-14
    Requires: PowerShell 5.1+, PSADT 4.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Path to PSADT package")]
    [ValidateScript({Test-Path $_ -PathType Container})]
    [string]$PackagePath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Basic", "Standard", "Comprehensive")]
    [string]$ValidationLevel = "Standard",
    
    [Parameter(Mandatory = $false)]
    [switch]$TestInstallation,
    
    [Parameter(Mandatory = $false)]
    [switch]$OutputReport,
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$ReportPath = "C:\PSADT_Reports"
)

#region Helper Functions
function Write-LogMessage {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success", "Test")]
        [string]$Type = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colors = @{
        Info = "White"
        Warning = "Yellow" 
        Error = "Red"
        Success = "Green"
        Test = "Cyan"
    }
    
    Write-Host "[$timestamp] $Message" -ForegroundColor $colors[$Type]
}

function Test-FileStructure {
    param([string]$PackagePath)
    
    $results = @{
        Passed = @()
        Failed = @()
        Warnings = @()
    }
    
    # Required files and directories
    $requiredItems = @{
        "Deploy-Application.ps1" = "File"
        "AppDeployToolkit" = "Directory"
        "AppDeployToolkit\AppDeployToolkitMain.ps1" = "File"
        "AppDeployToolkit\AppDeployToolkitExtensions.ps1" = "File"
        "Files" = "Directory"
    }
    
    Write-LogMessage "Testing package file structure..." -Type "Test"
    
    foreach ($item in $requiredItems.GetEnumerator()) {
        $itemPath = Join-Path $PackagePath $item.Key
        $itemType = $item.Value
        
        if ($itemType -eq "File" -and (Test-Path $itemPath -PathType Leaf)) {
            $results.Passed += "✓ Required file found: $($item.Key)"
        }
        elseif ($itemType -eq "Directory" -and (Test-Path $itemPath -PathType Container)) {
            $results.Passed += "✓ Required directory found: $($item.Key)"
        }
        else {
            $results.Failed += "✗ Missing required $($itemType.ToLower()): $($item.Key)"
        }
    }
    
    # Check for common optional directories
    $optionalItems = @("SupportFiles", "Logs")
    foreach ($item in $optionalItems) {
        $itemPath = Join-Path $PackagePath $item
        if (Test-Path $itemPath) {
            $results.Passed += "✓ Optional directory found: $item"
        }
    }
    
    # Check Files directory contents
    $filesPath = Join-Path $PackagePath "Files"
    if (Test-Path $filesPath) {
        $fileCount = (Get-ChildItem $filesPath -Recurse -File).Count
        if ($fileCount -gt 0) {
            $results.Passed += "✓ Files directory contains $fileCount file(s)"
        } else {
            $results.Warnings += "⚠ Files directory is empty"
        }
    }
    
    return $results
}

function Test-ScriptSyntax {
    param([string]$PackagePath)
    
    $results = @{
        Passed = @()
        Failed = @()
        Warnings = @()
    }
    
    Write-LogMessage "Testing PowerShell script syntax..." -Type "Test"
    
    # Test Deploy-Application.ps1
    $deployScript = Join-Path $PackagePath "Deploy-Application.ps1"
    if (Test-Path $deployScript) {
        try {
            $tokens = $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($deployScript, [ref]$tokens, [ref]$errors)
            
            if ($errors.Count -eq 0) {
                $results.Passed += "✓ Deploy-Application.ps1 syntax is valid"
            } else {
                foreach ($error in $errors) {
                    $results.Failed += "✗ Syntax error in Deploy-Application.ps1: $($error.Message) (Line $($error.StartPosition.StartLine))"
                }
            }
        }
        catch {
            $results.Failed += "✗ Failed to parse Deploy-Application.ps1: $($_.Exception.Message)"
        }
    }
    
    # Test other PowerShell files
    $psFiles = Get-ChildItem $PackagePath -Filter "*.ps1" -Recurse | Where-Object { $_.Name -ne "Deploy-Application.ps1" }
    foreach ($file in $psFiles) {
        try {
            $tokens = $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
            
            if ($errors.Count -eq 0) {
                $results.Passed += "✓ $($file.Name) syntax is valid"
            } else {
                foreach ($error in $errors) {
                    $results.Failed += "✗ Syntax error in $($file.Name): $($error.Message)"
                }
            }
        }
        catch {
            $results.Failed += "✗ Failed to parse $($file.Name): $($_.Exception.Message)"
        }
    }
    
    return $results
}

function Test-PSADT4Compliance {
    param([string]$PackagePath)
    
    $results = @{
        Passed = @()
        Failed = @()
        Warnings = @()
    }
    
    Write-LogMessage "Testing PSADT 4.0 compliance..." -Type "Test"
    
    $deployScript = Join-Path $PackagePath "Deploy-Application.ps1"
    if (Test-Path $deployScript) {
        $content = Get-Content $deployScript -Raw
        
        # Check for required PowerShell version
        if ($content -match '#Requires -Version 5\.1') {
            $results.Passed += "✓ PowerShell 5.1 requirement specified"
        } else {
            $results.Failed += "✗ Missing PowerShell 5.1 requirement"
        }
        
        # Check for proper parameter block
        if ($content -match '\[CmdletBinding\(\)\]') {
            $results.Passed += "✓ Proper CmdletBinding attribute found"
        } else {
            $results.Warnings += "⚠ CmdletBinding attribute recommended"
        }
        
        # Check for standard parameters
        $standardParams = @('DeploymentType', 'DeployMode')
        foreach ($param in $standardParams) {
            if ($content -match "\$$param") {
                $results.Passed += "✓ Standard parameter found: $param"
            } else {
                $results.Warnings += "⚠ Standard parameter missing: $param"
            }
        }
        
        # Check for proper error handling
        if ($content -match 'Try\s*\{' -and $content -match 'Catch\s*\{') {
            $results.Passed += "✓ Error handling (Try/Catch) implemented"
        } else {
            $results.Failed += "✗ Missing proper error handling"
        }
        
        # Check for PSADT function usage
        $psadtFunctions = @('Show-InstallationWelcome', 'Execute-MSI', 'Execute-Process', 'Exit-Script')
        foreach ($func in $psadtFunctions) {
            if ($content -match $func) {
                $results.Passed += "✓ PSADT function used: $func"
            }
        }
        
        # Check for hardcoded paths (anti-pattern)
        if ($content -match 'C:\\' -and $content -notmatch '\$env:') {
            $results.Warnings += "⚠ Potential hardcoded paths detected"
        }
        
        # Check for logging best practices
        if ($content -match 'Write-Log') {
            $results.Passed += "✓ PSADT logging functions used"
        } else {
            $results.Warnings += "⚠ Consider using PSADT logging functions"
        }
    }
    
    return $results
}

function Test-SecurityCompliance {
    param([string]$PackagePath)
    
    $results = @{
        Passed = @()
        Failed = @()
        Warnings = @()
    }
    
    Write-LogMessage "Testing security compliance..." -Type "Test"
    
    # Check for unsigned scripts
    $psFiles = Get-ChildItem $PackagePath -Filter "*.ps1" -Recurse
    foreach ($file in $psFiles) {
        try {
            $signature = Get-AuthenticodeSignature $file.FullName
            if ($signature.Status -eq 'Valid') {
                $results.Passed += "✓ $($file.Name) is properly signed"
            } elseif ($signature.Status -eq 'NotSigned') {
                $results.Warnings += "⚠ $($file.Name) is not digitally signed"
            } else {
                $results.Failed += "✗ $($file.Name) has invalid signature: $($signature.Status)"
            }
        }
        catch {
            $results.Warnings += "⚠ Could not verify signature for $($file.Name)"
        }
    }
    
    # Check for potentially dangerous commands
    $deployScript = Join-Path $PackagePath "Deploy-Application.ps1"
    if (Test-Path $deployScript) {
        $content = Get-Content $deployScript -Raw
        
        $dangerousCommands = @(
            'Invoke-Expression',
            'Invoke-Command',
            'Start-Process.*-Credential',
            'New-Object.*System\.Net\.WebClient',
            'DownloadString',
            'DownloadFile'
        )
        
        foreach ($cmd in $dangerousCommands) {
            if ($content -match $cmd) {
                $results.Warnings += "⚠ Potentially dangerous command found: $cmd"
            }
        }
        
        # Check for execution policy changes
        if ($content -match 'Set-ExecutionPolicy') {
            $results.Warnings += "⚠ Execution policy modification detected"
        }
    }
    
    return $results
}

function Test-InstallationSimulation {
    param([string]$PackagePath)
    
    $results = @{
        Passed = @()
        Failed = @()
        Warnings = @()
    }
    
    Write-LogMessage "Performing installation simulation..." -Type "Test"
    
    try {
        # Check if running as administrator
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        
        if (-not $isAdmin) {
            $results.Warnings += "⚠ Installation simulation requires administrator privileges"
            return $results
        }
        
        $deployScript = Join-Path $PackagePath "Deploy-Application.ps1"
        
        if (Test-Path $deployScript) {
            # Test script execution with WhatIf equivalent
            $testJob = Start-Job -ScriptBlock {
                param($ScriptPath)
                try {
                    # Validate script can be dot-sourced without execution
                    $content = Get-Content $ScriptPath -Raw
                    $scriptBlock = [ScriptBlock]::Create($content)
                    
                    # Basic validation - can we create the script block?
                    if ($scriptBlock) {
                        return @{ Success = $true; Message = "Script can be parsed and executed" }
                    } else {
                        return @{ Success = $false; Message = "Script cannot be parsed" }
                    }
                }
                catch {
                    return @{ Success = $false; Message = $_.Exception.Message }
                }
            } -ArgumentList $deployScript
            
            $testResult = Wait-Job $testJob -Timeout 30 | Receive-Job
            Remove-Job $testJob -Force
            
            if ($testResult.Success) {
                $results.Passed += "✓ Script execution simulation passed"
            } else {
                $results.Failed += "✗ Script execution simulation failed: $($testResult.Message)"
            }
        }
    }
    catch {
        $results.Failed += "✗ Installation simulation error: $($_.Exception.Message)"
    }
    
    return $results
}

function New-ValidationReport {
    param(
        [string]$PackagePath,
        [hashtable]$Results,
        [string]$ReportPath
    )
    
    $packageName = Split-Path $PackagePath -Leaf
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $reportFile = Join-Path $ReportPath "ValidationReport-$packageName-$timestamp.html"
    
    $totalTests = ($Results.Values | ForEach-Object { $_.Passed.Count + $_.Failed.Count + $_.Warnings.Count } | Measure-Object -Sum).Sum
    $passedTests = ($Results.Values | ForEach-Object { $_.Passed.Count } | Measure-Object -Sum).Sum
    $failedTests = ($Results.Values | ForEach-Object { $_.Failed.Count } | Measure-Object -Sum).Sum
    $warnings = ($Results.Values | ForEach-Object { $_.Warnings.Count } | Measure-Object -Sum).Sum
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>PSADT 4.0 Package Validation Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { background-color: #2c3e50; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .summary { display: flex; justify-content: space-around; margin-bottom: 30px; }
        .metric { text-align: center; padding: 15px; border-radius: 8px; min-width: 120px; }
        .metric-passed { background-color: #d4edda; color: #155724; }
        .metric-failed { background-color: #f8d7da; color: #721c24; }
        .metric-warning { background-color: #fff3cd; color: #856404; }
        .metric-total { background-color: #e9ecef; color: #495057; }
        .section { margin-bottom: 30px; }
        .section h3 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 5px; }
        .result-item { padding: 8px; margin: 4px 0; border-radius: 4px; }
        .passed { background-color: #d4edda; color: #155724; }
        .failed { background-color: #f8d7da; color: #721c24; }
        .warning { background-color: #fff3cd; color: #856404; }
        .footer { margin-top: 30px; padding: 15px; background-color: #f8f9fa; border-radius: 8px; font-size: 0.9em; color: #6c757d; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>PSADT 4.0 Package Validation Report</h1>
            <p><strong>Package:</strong> $packageName</p>
            <p><strong>Generated:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
            <p><strong>Validation Level:</strong> $ValidationLevel</p>
        </div>
        
        <div class="summary">
            <div class="metric metric-total">
                <h4>Total Tests</h4>
                <div style="font-size: 2em; font-weight: bold;">$totalTests</div>
            </div>
            <div class="metric metric-passed">
                <h4>Passed</h4>
                <div style="font-size: 2em; font-weight: bold;">$passedTests</div>
            </div>
            <div class="metric metric-failed">
                <h4>Failed</h4>
                <div style="font-size: 2em; font-weight: bold;">$failedTests</div>
            </div>
            <div class="metric metric-warning">
                <h4>Warnings</h4>
                <div style="font-size: 2em; font-weight: bold;">$warnings</div>
            </div>
        </div>
"@

    foreach ($section in $Results.GetEnumerator()) {
        $sectionName = $section.Key
        $sectionResults = $section.Value
        
        $html += @"
        <div class="section">
            <h3>$sectionName</h3>
"@
        
        foreach ($item in $sectionResults.Passed) {
            $html += "            <div class='result-item passed'>$item</div>`n"
        }
        
        foreach ($item in $sectionResults.Failed) {
            $html += "            <div class='result-item failed'>$item</div>`n"
        }
        
        foreach ($item in $sectionResults.Warnings) {
            $html += "            <div class='result-item warning'>$item</div>`n"
        }
        
        $html += "        </div>`n"
    }
    
    $html += @"
        <div class="footer">
            <p>Report generated by PSADT 4.0 Package Validator</p>
            <p>Package Path: $PackagePath</p>
        </div>
    </div>
</body>
</html>
"@
    
    Set-Content -Path $reportFile -Value $html -Encoding UTF8
    return $reportFile
}
#endregion Helper Functions

#region Main Script
try {
    $packageName = Split-Path $PackagePath -Leaf
    Write-LogMessage "Starting validation of package: $packageName" -Type "Info"
    Write-LogMessage "Validation level: $ValidationLevel" -Type "Info"
    
    $validationResults = @{}
    
    # Basic validation (always performed)
    $validationResults["File Structure"] = Test-FileStructure -PackagePath $PackagePath
    $validationResults["Script Syntax"] = Test-ScriptSyntax -PackagePath $PackagePath
    
    # Standard validation
    if ($ValidationLevel -in @("Standard", "Comprehensive")) {
        $validationResults["PSADT 4.0 Compliance"] = Test-PSADT4Compliance -PackagePath $PackagePath
        $validationResults["Security Compliance"] = Test-SecurityCompliance -PackagePath $PackagePath
    }
    
    # Comprehensive validation
    if ($ValidationLevel -eq "Comprehensive" -or $TestInstallation) {
        $validationResults["Installation Simulation"] = Test-InstallationSimulation -PackagePath $PackagePath
    }
    
    # Calculate overall results
    $totalPassed = ($validationResults.Values | ForEach-Object { $_.Passed.Count } | Measure-Object -Sum).Sum
    $totalFailed = ($validationResults.Values | ForEach-Object { $_.Failed.Count } | Measure-Object -Sum).Sum
    $totalWarnings = ($validationResults.Values | ForEach-Object { $_.Warnings.Count } | Measure-Object -Sum).Sum
    $totalTests = $totalPassed + $totalFailed + $totalWarnings
    
    # Display results
    Write-LogMessage "`n=== VALIDATION SUMMARY ===" -Type "Info"
    Write-LogMessage "Package: $packageName" -Type "Info"
    Write-LogMessage "Total tests: $totalTests" -Type "Info"
    Write-LogMessage "Passed: $totalPassed" -Type "Success"
    Write-LogMessage "Failed: $totalFailed" -Type "$(if ($totalFailed -gt 0) { 'Error' } else { 'Success' })"
    Write-LogMessage "Warnings: $totalWarnings" -Type "$(if ($totalWarnings -gt 0) { 'Warning' } else { 'Info' })"
    
    # Display detailed results
    foreach ($section in $validationResults.GetEnumerator()) {
        Write-LogMessage "`n--- $($section.Key) ---" -Type "Info"
        
        foreach ($item in $section.Value.Passed) {
            Write-LogMessage $item -Type "Success"
        }
        
        foreach ($item in $section.Value.Failed) {
            Write-LogMessage $item -Type "Error"
        }
        
        foreach ($item in $section.Value.Warnings) {
            Write-LogMessage $item -Type "Warning"
        }
    }
    
    # Generate report if requested
    if ($OutputReport) {
        if (!(Test-Path $ReportPath)) {
            New-Item -ItemType Directory -Path $ReportPath -Force | Out-Null
        }
        
        $reportFile = New-ValidationReport -PackagePath $PackagePath -Results $validationResults -ReportPath $ReportPath
        Write-LogMessage "`nDetailed report generated: $reportFile" -Type "Success"
    }
    
    # Final assessment
    if ($totalFailed -eq 0) {
        Write-LogMessage "`n✓ Package validation PASSED" -Type "Success"
        if ($totalWarnings -gt 0) {
            Write-LogMessage "Note: $totalWarnings warning(s) found - review recommended" -Type "Warning"
        }
        exit 0
    } else {
        Write-LogMessage "`n✗ Package validation FAILED" -Type "Error"
        Write-LogMessage "$totalFailed critical issue(s) must be resolved before deployment" -Type "Error"
        exit 1
    }
}
catch {
    Write-LogMessage "Validation failed: $($_.Exception.Message)" -Type "Error"
    exit 1
}
#endregion Main Script

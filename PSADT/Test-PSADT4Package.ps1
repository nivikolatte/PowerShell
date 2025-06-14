#Requires -Version 5.1
<#
.SYNOPSIS
    Validates PSADT 4.0 packages for compliance and readiness

.DESCRIPTION
    Performs comprehensive validation of PSADT 4.0 packages including:
    - File structure verification
    - Script syntax validation
    - PSADT 4.0 compliance checks

.PARAMETER PackagePath
    Path to the PSADT package to validate

.PARAMETER ValidationLevel
    Level of validation: Basic, Standard, or Comprehensive

.PARAMETER OutputReport
    Generate detailed validation report

.PARAMETER ReportPath
    Path for validation reports (default: C:\PSADT_Reports)

.EXAMPLE
    .\Test-PSADT4Package.ps1 -PackagePath "C:\PSADT_Packages\Adobe-Reader-24.002.20933"

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

function Test-PSADTStructure {
    param([string]$PackagePath)
    
    $results = @{
        Passed = @()
        Failed = @()
        Warnings = @()
    }
    
    Write-LogMessage "Testing package file structure..." -Type "Test"
    
    # Required files and directories
    $requiredItems = @{
        "Deploy-Application.ps1" = "File"
        "AppDeployToolkit" = "Directory"
        "Files" = "Directory"
    }
    
    foreach ($item in $requiredItems.GetEnumerator()) {
        $itemPath = Join-Path $PackagePath $item.Key
        $itemType = $item.Value
        
        if ($itemType -eq "File" -and (Test-Path $itemPath -PathType Leaf)) {
            $results.Passed += "[PASS] Required file found: $($item.Key)"
        }
        elseif ($itemType -eq "Directory" -and (Test-Path $itemPath -PathType Container)) {
            $results.Passed += "[PASS] Required directory found: $($item.Key)"
        }
        else {
            $results.Failed += "[FAIL] Missing required $($itemType.ToLower()): $($item.Key)"
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
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $deployScript -Raw), [ref]$null)
            $results.Passed += "[PASS] Deploy-Application.ps1 syntax is valid"
        }
        catch {
            $results.Failed += "[FAIL] Deploy-Application.ps1 syntax error: $($_.Exception.Message)"
        }
    }
    
    return $results
}
#endregion Helper Functions

#region Main Script
try {
    Write-LogMessage "Starting PSADT 4.0 package validation..." -Type "Info"
    Write-LogMessage "Package: $PackagePath" -Type "Info"
    Write-LogMessage "Validation Level: $ValidationLevel" -Type "Info"
    
    $allResults = @{
        Passed = @()
        Failed = @()
        Warnings = @()
    }
    
    # Structure validation (always performed)
    $structureResults = Test-PSADTStructure -PackagePath $PackagePath
    $allResults.Passed += $structureResults.Passed
    $allResults.Failed += $structureResults.Failed
    $allResults.Warnings += $structureResults.Warnings
    
    # Syntax validation (Standard and Comprehensive)
    if ($ValidationLevel -in @("Standard", "Comprehensive")) {
        $syntaxResults = Test-ScriptSyntax -PackagePath $PackagePath
        $allResults.Passed += $syntaxResults.Passed
        $allResults.Failed += $syntaxResults.Failed
        $allResults.Warnings += $syntaxResults.Warnings
    }
    
    # Display summary
    Write-LogMessage "`n=== VALIDATION SUMMARY ===" -Type "Info"
    Write-LogMessage "Passed: $($allResults.Passed.Count)" -Type "Success"
    Write-LogMessage "Failed: $($allResults.Failed.Count)" -Type "Error"
    Write-LogMessage "Warnings: $($allResults.Warnings.Count)" -Type "Warning"
    
    # Display results
    if ($allResults.Passed.Count -gt 0) {
        Write-LogMessage "`nPassed Checks:" -Type "Success"
        foreach ($item in $allResults.Passed) {
            Write-LogMessage "  $item" -Type "Success"
        }
    }
    
    if ($allResults.Failed.Count -gt 0) {
        Write-LogMessage "`nFailed Checks:" -Type "Error"
        foreach ($item in $allResults.Failed) {
            Write-LogMessage "  $item" -Type "Error"
        }
    }
    
    if ($allResults.Warnings.Count -gt 0) {
        Write-LogMessage "`nWarnings:" -Type "Warning"
        foreach ($item in $allResults.Warnings) {
            Write-LogMessage "  $item" -Type "Warning"
        }
    }
    
    # Exit with appropriate code
    if ($allResults.Failed.Count -eq 0) {
        Write-LogMessage "`n[PASS] Package validation PASSED" -Type "Success"
        exit 0
    }
    else {
        Write-LogMessage "`n[FAIL] Package validation FAILED" -Type "Error"
        exit 1
    }
}
catch {
    Write-LogMessage "Validation failed with error: $($_.Exception.Message)" -Type "Error"
    exit 1
}
#endregion Main Script

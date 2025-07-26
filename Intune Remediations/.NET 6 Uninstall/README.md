# .NET 6 Runtime Removal - Winget-Only Intune Guide

## Overview
Pure winget-based approach to detect and remove .NET 6 runtime components via Intune Proactive Remediation. Includes automatic winget path detection for SYSTEM context.

## Files (Winget Folder)
- `Detection.ps1` (45 lines) - Detects .NET 6 via winget only
- `Remediation.ps1` (35 lines) - Removes .NET 6 via winget only

## How It Works
**Auto-detects winget**: Finds winget in system or user locations automatically
**SYSTEM context support**: Adds winget to PATH when running as SYSTEM account
**Winget-only**: No file system fallback - requires winget to function

## Target Components
- Microsoft.DotNet.Runtime.6
- Microsoft.DotNet.AspNetCore.6  
- Microsoft.DotNet.DesktopRuntime.6

## Quick Setup for Intune

### 1. Create Proactive Remediation
- **Name**: `.NET 6 Runtime Removal (Hybrid)`
- **Location**: Endpoint Manager → Reports → Endpoint analytics → Proactive remediations

### 2. Upload Scripts
| Setting | Value |
|---------|-------|
| **Detection script** | `Winget/Detection.ps1` |
| **Remediation script** | `Winget/Remediation.ps1` |
| **Run as System** | Yes ✅ (Now works properly!) |
| **64-bit PowerShell** | Yes |

## Advantages
✅ Clean winget-only approach  
✅ Auto-detects winget location  
✅ Works in SYSTEM context (auto-adds winget to PATH)  
✅ No messy file system operations  

## Requirements  
❌ **Requires winget to be installed** - will fail if winget unavailable  
❌ **Only removes winget-managed packages** - won't touch manually installed .NET  

## ⚠️ IMPORTANT WARNINGS - Potential Future Issues

### Before Deployment:
❌ **Application Impact**: Apps dependent on .NET 6 will stop working  
❌ **Partial Removal**: Only removes winget-managed packages (not manual installs)  
❌ **Reinstallation Risk**: Some apps may automatically reinstall .NET 6  
❌ **SDK Dependencies**: May break development environments using .NET 6 SDKs  

### Recommended Pre-Deployment Steps:
1. **Inventory applications** that use .NET 6 runtime
2. **Test in isolated environment** with representative applications
3. **Plan communication** to users about potential app failures
4. **Consider phased rollout** to small groups first
5. **Have rollback plan** ready (reinstall .NET 6 if needed)

### Monitoring After Deployment:
- Monitor helpdesk tickets for application failures
- Check if .NET 6 gets automatically reinstalled
- Verify critical business applications still function

## ⚠️ SYSTEM Context Solution
**Problem Solved**: Scripts automatically find winget in either system-wide or user locations and add it to PATH for current session. Based on solution from [ScriptingHouse.com](https://www.scriptinghouse.com/2024/03/resolving-winget-not-recognized-error-when-running-with-the-system-account.html)

## Quick Test Commands
```powershell
# Test detection
.\Detection.ps1

# Test remediation (if needed)
.\Remediation.ps1
```

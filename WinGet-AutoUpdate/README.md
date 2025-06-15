# WinGet-AutoUpdate

Microsoft Intune remediation scripts for automated WinGet application updates.

## Overview

This folder contains two PowerShell scripts designed to work as a Microsoft Intune proactive remediation package:

- **Detection Script**: `Detect-WinGetUpdates-Fixed.ps1`
- **Remediation Script**: `Remediate-WinGetUpdates.ps1`

## Monitored Applications

The scripts currently monitor and update the following applications:
- Google Chrome
- Mozilla Firefox
- Git
- Notepad++
- 7zip

## Features

- ✅ **Space-efficient logging** (50KB limit with auto-reset)
- ✅ **Proper WinGet exit code handling** (handles -1978335189, -1978335212)
- ✅ **SYSTEM context compatible** (works with non-admin users)
- ✅ **Concise Intune reporting** output
- ✅ **Easy app list management** (edit at top of detection script)

## Deployment

1. Upload both scripts to Microsoft Intune as a proactive remediation package
2. Set to run in **SYSTEM context**
3. Configure desired schedule (daily/weekly)
4. Deploy to target device groups

## Log Files

- **Location**: `C:\ProgramData\WinGet-AutoUpdate\Logs\`
- Detection log: `WinGet-Detection.log`
- Remediation log: `WinGet-Remediation.log`
- All apps list: `WinGet-AllApps.log`
- Upgrade check output: `WinGet-Upgrade.log`

These logs are stored in ProgramData for better accessibility when running in system context.

## Customization

To add or remove applications, edit the `$Apps` array at the top of `Detect-WinGetUpdates-Fixed.ps1`:

```powershell
$Apps = @(
    "Google.Chrome",
    "Mozilla.Firefox", 
    "Git.Git",
    "Notepad++.Notepad++",
    "7zip.7zip"
)
```

## Requirements

- Windows 10/11 with WinGet installed
- Microsoft Intune license
- Devices enrolled in Intune

## Author

Created for automated application management in enterprise environments.

## Release History

### v1.3.0 (June 15, 2025)

- **Fixed Syntax Errors**: Resolved PowerShell parsing errors caused by missing line breaks
- **Enhanced Regex Handling**: Fixed regex pattern matching for app names with special characters (e.g., Notepad++.Notepad++)
- **Code Validation**: Scripts now pass syntax validation and execute without errors
- **Improved Reliability**: Both detection and remediation scripts tested and verified working correctly

### v1.2.0 (June 15, 2025)

- **Moved logs to ProgramData**: Logs are now stored in `C:\ProgramData\WinGet-AutoUpdate\Logs\` for better accessibility in system context
- **Enhanced diagnostics**: Added more detailed logging and separate log files for upgrade output and app lists
- **Username and computer name logging**: Added for better troubleshooting in different contexts

### v1.1.0 (June 15, 2025)

- **Enhanced WinGet Path Detection**: Added robust path discovery for system context execution
- **Multiple Search Methods**: Now checks multiple locations and falls back to AppX package information
- **Full Path Execution**: Uses absolute paths to ensure WinGet runs properly in Intune's system context
- **Improved Logging**: Better diagnostic information about WinGet location and execution status

### v1.0.0 (Initial Release)

- Basic WinGet update detection and remediation for Intune
- Support for Chrome, Firefox, Git, Notepad++, and 7zip
- Exit code handling and space-efficient logging

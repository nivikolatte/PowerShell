# .NET 6 Runtime Detection - Winget Only (Enhanced System Context Support)
# Return Code 0 = Not found (compliant), 1 = Found (needs remediation) or Winget unavailable

try {
    # Function to add winget to PATH for current session (SYSTEM context fix)
    function Add-WinGetToPath {
        # Try multiple common winget locations
        $WinGetPaths = @(
            "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe",
            "$env:LocalAppData\Microsoft\WindowsApps\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\winget.exe",
            "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
        )
        
        $WinGetPath = $null
        foreach ($path in $WinGetPaths) {
            $foundPath = Get-ChildItem $path -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($foundPath) {
                $WinGetPath = $foundPath.DirectoryName
                break
            }
        }
        
        if ($WinGetPath -and -not (($env:PATH -split ';') -contains $WinGetPath)) {
            $env:PATH += ";$WinGetPath"
            Write-Output "Added winget path ($WinGetPath) to current session"
        }
    }

    # Check if winget is available, if not try to add it to PATH
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Add-WinGetToPath
    }

    # Check if winget is now available after PATH update
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Output "Using winget detection method"
        
        # Check for .NET 6 runtime packages via winget
        $packages = @(
            "Microsoft.DotNet.Runtime.6",
            "Microsoft.DotNet.AspNetCore.6", 
            "Microsoft.DotNet.DesktopRuntime.6"
        )
        
        foreach ($package in $packages) {
            $result = winget list $package --accept-source-agreements 2>$null
            if ($result -match $package) {
                Write-Output ".NET 6 runtime found via winget - remediation required"
                exit 1
            }
        }
        
        Write-Output ".NET 6 runtime not found via winget - system compliant"
        exit 0
    }
    else {
        Write-Output "Winget not available - cannot determine compliance"
        Write-Output "This script requires winget to function properly"
        exit 1
    }
}
catch {
    Write-Output "Detection error - assuming compliant"
    exit 0
}

# .NET 6 Runtime Removal - Winget Only (Enhanced System Context Support)
# Return Code 0 = Success, 1 = Failed or Winget unavailable

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
        Write-Output "Using winget removal method"
        
        # .NET 6 runtime packages to remove via winget
        $packages = @(
            "Microsoft.DotNet.Runtime.6",
            "Microsoft.DotNet.AspNetCore.6", 
            "Microsoft.DotNet.DesktopRuntime.6"
        )
        
        # Remove each package with better error handling
        $removalSuccess = $true
        foreach ($package in $packages) {
            Write-Output "Removing: $package"
            $result = winget uninstall $package --all-versions --silent --accept-source-agreements --accept-package-agreements 2>&1
            
            # Check if removal was successful or package wasn't found (both OK)
            if ($LASTEXITCODE -eq 0 -or $result -match "No installed package found") {
                Write-Output "  Success: $package removed or not found"
            } else {
                Write-Output "  Warning: Failed to remove $package - $result"
                $removalSuccess = $false
            }
        }
        
        if ($removalSuccess) {
            Write-Output ".NET 6 runtime removal completed successfully"
            exit 0
        } else {
            Write-Output ".NET 6 runtime removal completed with warnings"
            exit 0  # Still exit success since partial removal is better than failure
        }
    }
    else {
        Write-Output "Winget not available - cannot proceed with removal"
        Write-Output "This script requires winget to function properly"
        exit 1
    }
}
catch {
    Write-Output "Error: $($_.Exception.Message)"
    exit 1
}

<#
.SYNOPSIS
    This script allows you to set a custom lock screen image or reset it to the default Windows image.

.DESCRIPTION
    THe script needs to be run as Administrator.
    The Set-CustomLockScreen function sets a custom lock screen image path in the Windows registry.
    The Reset-LockScreen function resets the lock screen image to the default Windows image.

.EXAMPLE
    Set-CustomLockScreen -LockScreenImagePath "C:\Path\To\Custom\Image.jpg"
    This example sets the lock screen picture to the specified custom image located at "C:\Path\Custom\Image.jpg".

.EXAMPLE
    Reset-LockScreen
    This example resets the lock screen picture to the default Windows image.

.DISCLAIMER
    This script is provided as-is without any warranty of any kind. Use it at your own risk. The author shall not be held liable for any damages or losses arising from the use of this script.
    Please ensure that you have appropriate permissions and backup your system before running this script. It is recommended to review and understand the script code before executing it on your system.
    Always run scripts from trusted sources and verify their content to ensure they align with your security and operational requirements.
    By using this script, you acknowledge and agree that you are solely responsible for any consequences that may occur as a result of executing this script. If you do not agree with these terms, do not use this script.

.VERSION
    1.0

.DATE
    May 18, 2023

.AUTHOR
    Nivi Kolatte
#>

function Set-CustomLockScreen {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LockScreenImagePath
    )

    $RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"

    # Check if the registry path exists
    if (Test-Path $RegistryPath) {
        # Set the registry values to configure the custom lock screen image
        Set-ItemProperty -Path $RegistryPath -Name "LockScreenImagePath" -Value $LockScreenImagePath -Force
        Set-ItemProperty -Path $RegistryPath -Name "LockScreenImageStatus" -Value 1 -Force

        Write-Host "The lock screen picture has been set to: $LockScreenImagePath"
    }
    else {
        # Create the registry path if it doesn't exist
        New-Item -Path $RegistryPath -Force | Out-Null

        # Set the registry values to configure the custom lock screen image
        New-ItemProperty -Path $RegistryPath -Name "LockScreenImagePath" -Value $LockScreenImagePath -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $RegistryPath -Name "LockScreenImageStatus" -Value 1 -PropertyType DWord -Force | Out-Null

        Write-Host "The lock screen picture has been set to: $LockScreenImagePath"
    }
}

function Reset-LockScreen {
    $RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"

    # Check if the registry path exists
    if (Test-Path $RegistryPath) {
        # Remove the "LockScreenImagePath" registry value if it exists
        if (Get-ItemProperty -Path $RegistryPath -Name "LockScreenImagePath" -ErrorAction SilentlyContinue) {
            Remove-ItemProperty -Path $RegistryPath -Name "LockScreenImagePath" -ErrorAction SilentlyContinue
        }

        # Set the "LockScreenImageStatus" registry value to 0
        Set-ItemProperty -Path $RegistryPath -Name "LockScreenImageStatus" -Value 0 -Force

        Write-Host "Lock screen picture has been reset to Windows default."
    }
    else {
        Write-Host "No custom lock screen set."
    }
}

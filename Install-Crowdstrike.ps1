<#
.SYNOPSIS
This script installs CrowdStrike agent and performs additional actions based on Active Directory information.

.DESCRIPTION
The script sets the execution policy to Bypass, creates a log file with the current date, checks if the CrowdStrike agent is already installed, retrieves computer and Active Directory information, copies necessary files if needed, and executes the CrowdStrike installer. It logs all the actions to the specified log file.

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.NOTES
- The script requires administrative privileges to set the execution policy and install software.
- Ensure that the necessary network shares and paths are accessible.
- This script is provided as-is without any warranties or guarantees.

.DISCLAIMER
    This script is provided as-is without any warranty of any kind. Use it at your own risk. The author shall not be held liable for any damages or losses arising from the use of this script.
    Please ensure that you have appropriate permissions and backup your system before running this script. It is recommended to review and understand the script code before executing it on your system.
    Always run scripts from trusted sources and verify their content to ensure they align with your security and operational requirements.
    By using this script, you acknowledge and agree that you are solely responsible for any consequences that may occur as a result of executing this script. If you do not agree with these terms, do not use this script.

.VERSION
    1.0

.EXAMPLE
PS C:\> .\InstallCrowdstrike.ps1
Runs the script to install CrowdStrike agent and perform additional actions.

#>

# Define the transcript file path and name with the current date
$transcriptFilePath = "C:\InstallCrowdstrike\InstallTranscript_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Define the log file path and name with the current date
$logFilePath = "C:\InstallCrowdstrike\InstallLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Start transcript logging
Start-Transcript -Path $transcriptFilePath -NoClobber

# Store the original execution policy to restore it later
$originalExecutionPolicy = Get-ExecutionPolicy -Scope Process

# Set the execution policy to Bypass
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Function to write log entries to the log file
function Write-Log($message) {
    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $message"
    $logEntry | Out-File -FilePath $logFilePath -Append
}

# Create the InstallCrowdstrike directory if it doesn't exist
$installDirectory = "C:\InstallCrowdstrike"
if (!(Test-Path -Path $installDirectory)) {
    New-Item -Path $installDirectory -ItemType Directory -Force
}

# Checking if CrowdStrike agent is already installed
$csAgentStatus = & sc.exe query csagent

if ($LASTEXITCODE -eq 1060) {
    Write-Log "CrowdStrike is not installed."

    # Get the computer name of the client machine
    $computerName = $env:COMPUTERNAME

    # Create a new DirectoryEntry object for the RootDSE to retrieve the default naming context
    $rootDSE = New-Object System.DirectoryServices.DirectoryEntry("LDAP://RootDSE")
    $defaultNamingContext = $rootDSE.Properties["defaultNamingContext"].Value

    # Create a DirectorySearcher object to perform the search in Active Directory
    $adSearcher = New-Object System.DirectoryServices.DirectorySearcher
    $adSearcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$defaultNamingContext")

    # Set the filter to find computer objects with a name that matches the client machine's computer name
    $adSearcher.Filter = "(&(objectClass=computer)(name=$computerName))"

    # Add the properties to load for the search results
    $adSearcher.PropertiesToLoad.Add("distinguishedName")

    # Execute the search and retrieve the first matching result
    $adResult = $adSearcher.FindOne()

    if ($adResult) {
        # Extract the distinguished name from the search result
        $dn = $adResult.Properties["distinguishedName"][0]

        # Remove the CN value from the DN
        $dnWithoutCN = $dn -replace "^CN=[^,]+,", ""

        # Output the retrieved DN and OU information
        Write-Log "DN: $dn"
        Write-Log "OU: $dnWithoutCN"

        # Set the proper Access_Broaker and Access_CID based on OU details
        if ($dnWithoutCN -eq "OU=EL,OU=USA,DC=abc,DC=local") {
            $Access_Broaker = "GREECE.ABC.COM"
            $Access_CID = "6168EA1"
        }
        elseif ($dnWithoutCN -eq "OU=CA,OU=USA,DC=abc,DC=local") {
            $Access_Broaker = "BRAZIL.ABC.COM"
            $Access_CID = "61-B1"
        }
        elseif ($dnWithoutCN -eq "OU=NY,OU=USA,DC=abc,DC=local") {
            $Access_Broaker = "NY.ABC.COM"
            $Access_CID = "63FF"
        }
        else {
            # No matching OU found
            Write-Log "No matching OU found."
            # Stop transcript logging
            Stop-Transcript
            Set-ExecutionPolicy -Scope Process -ExecutionPolicy $originalExecutionPolicy -Force
            exit
        }

        # Checking if the CrowdStrike installer exists in the install directory
        $ZA_Access_Path = "$installDirectory\WindowsSensor.LionLanner.exe"
        if (!(Test-Path -Path $ZA_Access_Path)) {
            # Copying files to InstallCrowdstrike directory
            $copyJob = Copy-Item -Path "\\abc.local\scripts\CrowdStrike\*.exe" -Destination $installDirectory -Force -PassThru

            # Waiting for the copy operation to complete
            Wait-Item -Path $ZA_Access_Path
        }

        # Running the command without bypassing execution policy
        Write-Log "Executing CrowdStrike installer."
        & $ZA_Access_Path "APP_PROXYNAME=$Access_Broaker" "APP_PROXYPORT=53128" "/install" "/quiet" "/norestart" "CID=$Access_CID"
    }
    else {
        # If the computer object is not found, display an error message
        Write-Log "Unable to find the computer object in Active Directory."
    }
}
else {
    Write-Log "CrowdStrike is already installed. Exiting the script."
}

# Stop transcript logging
Stop-Transcript

# Reset the execution policy back to the original value
Set-ExecutionPolicy -Scope Process -ExecutionPolicy $originalExecutionPolicy -Force

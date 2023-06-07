<#
.SYNOPSIS
    This script allows you to get the DN and OU details from a domain joined machine from he client machine instead of the Active Directory. Useful when creating scripts based on the OU logic.

.DESCRIPTION
    THe script needs to be run as Administrator.
    
.DISCLAIMER
    This script is provided as-is without any warranty of any kind. Use it at your own risk. The author shall not be held liable for any damages or losses arising from the use of this script.
    Please ensure that you have appropriate permissions and backup your system before running this script. It is recommended to review and understand the script code before executing it on your system.
    Always run scripts from trusted sources and verify their content to ensure they align with your security and operational requirements.
    By using this script, you acknowledge and agree that you are solely responsible for any consequences that may occur as a result of executing this script. If you do not agree with these terms, do not use this script.

.VERSION
    1.0

.DATE
    June 07, 2023

.AUTHOR
    Nivi Kolatte
#>

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
$adSearcher.PropertiesToLoad.Add("canonicalName")

# Execute the search and retrieve the first matching result
$adResult = $adSearcher.FindOne()

if ($adResult) {
    # Extract the distinguished name and canonical name from the search result
    $dn = $adResult.Properties["distinguishedName"][0]
    $ou = $adResult.Properties["canonicalName"][0]

    # Output the retrieved DN and OU information
    Write-Output "DN: $dn"
    Write-Output "OU: $ou"
} else {
    # If the computer object is not found, display an error message
    Write-Output "Unable to find the computer object in Active Directory."
}
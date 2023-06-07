<#
.SYNOPSIS
Transforms GPO XML data into a CSV file.

.DESCRIPTION
This script reads XML files from a specified folder, extracts GPO (Group Policy Object) information, and transforms it into a CSV file. The script extracts GPO name, computer and user enabled status, and links to SOM (Scope of Management) information. It creates a CSV file with the transformed data for further analysis or reporting.

.PARAMETER folderPath
The path to the folder containing the GPO XML files.

.PARAMETER outputPath
The path to the output CSV file where the transformed data will be saved.

.EXAMPLE
Transform-GPOXMLData -folderPath "C:\GPOXMLExport" -outputPath "C:\Dump\TransformedData.csv"

This example runs the script to transform the GPO XML data from the "C:\GPOXMLExport" folder and saves the transformed data to the "C:\Dump\TransformedData.csv" file.

.NOTES
- The script requires XML files in the specified folder to process.
- The script assumes a specific XML structure for GPO data extraction.
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$folderPath,

    [Parameter(Mandatory=$true)]
    [string]$outputPath
)

# Get all XML files in the folder
$xmlFiles = Get-ChildItem -Path $folderPath -Filter "*.xml"

$output = @()

foreach ($xmlFile in $xmlFiles) {
    $xmlString = Get-Content -Path $xmlFile.FullName -Raw
    $xml = [xml]$xmlString

    # Extract GPO information
    $gpoName = $xml.GPO.Name

    # Extract Computer information
    $computerEnabled = if ($xml.GPO.Computer -and $xml.GPO.Computer.Enabled) { $xml.GPO.Computer.Enabled } else { "" }

    # Extract User information
    $userEnabled = if ($xml.GPO.User -and $xml.GPO.User.Enabled) { $xml.GPO.User.Enabled } else { "" }

    # Extract LinksTo information
    if ($xml.GPO.LinksTo) {
        foreach ($linkTo in $xml.GPO.LinksTo) {
            $linksToSOMName = $linkTo.SOMName
            $linksToEnabled = if ($linkTo.Enabled) { $linkTo.Enabled } else { "" }
            $linksToNoOverride = if ($linkTo.NoOverride) { $linkTo.NoOverride } else { "" }
            $linksToSOMPath = if ($linkTo.SOMPath) { $linkTo.SOMPath } else { "" }

            # Create an object with the extracted information
            $outputObject = [PSCustomObject]@{
                'XML File' = $xmlFile.Name
                'GPO Name' = $gpoName
                'Computer Enabled' = $computerEnabled
                'User Enabled' = $userEnabled
                'Links To SOM Name' = $linksToSOMName
                'Links To SOM Path' = $linksToSOMPath
                'Links To Enabled' = $linksToEnabled
                'Links To No Override' = $linksToNoOverride
            }

            # Add the object to the output array
            $output += $outputObject
        }
    }
    else {
        # Create an object with the extracted information (when LinksTo is missing)
        $outputObject = [PSCustomObject]@{
            'XML File' = $xmlFile.Name
            'GPO Name' = $gpoName
            'Computer Enabled' = $computerEnabled
            'User Enabled' = $userEnabled
            'Links To SOM Name' = ""
            'Links To SOM Path' = ""
            'Links To Enabled' = ""
            'Links To No Override' = ""
        }

        # Add the object to the output array
        $output += $outputObject
    }
}

# Export the output array to a CSV file
$output | Export-Csv -Path $outputPath -NoTypeInformation

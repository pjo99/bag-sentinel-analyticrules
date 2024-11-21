
# pjo - Bag
#region Functions
<#
.SYNOPSIS
pjo - loop rekursiv durch Verzeichnisse und ermittelt die Version der YAML Dateien (Die Version steht im YAML File als Property 'version:')

.DESCRIPTION
- Funktion Get-YamlFileVersions

.PARAMETER [parameter1]
root Directory (Pflichtfeld)

.PARAMETER [parameter2]
File Endung ( *.yaml - Defaultwert)

.EXAMPLE
$rootDirectory = "C:\Git_PRIV\bag-sentinel-analyticrules"
$versions = Get-YamlFileVersions -rootDirectory $rootDirectory
$versions
$versions.Count
.OUTPUTS
Custom Powershell Object
.NOTES
- Version: 1.0
#>
function Get-YamlFileVersions {
    param (
        [Parameter(Mandatory=$true)]
        [string]$rootDirectory,
        [string]$filePattern = "*.yaml"
    )

    # Get all YAML files in the directory and subdirectories
    $yamlFiles = Get-ChildItem -Path $rootDirectory -Include $filePattern -Recurse -File

    # Initialize a list to hold each custom object
    $YamlObjects = New-Object System.Collections.Generic.List[Object]

    # Loop through each YAML file
    foreach ($file in $yamlFiles) {
        # Attempt to find lines containing 'Version:' in each file
        $versionLines = Select-String -Path $file.FullName -Pattern "^version:.*$" -CaseSensitive

        $customObject = New-Object PSObject -Property @{
            FileName = $file.FullName
            Version  = if ($versionLines) { $versionLines.Matches.Value.TrimStart("version:").Trim() } else { "Not Found" }
        }

        # Add the custom object to the list
        $YamlObjects.Add($customObject)
    }

    return $YamlObjects
}
<#
.SYNOPSIS
pjo - Vergleicht die Output Objekte von Compare-MultipleYamlFileVersions - via zwei Hastables

.DESCRIPTION
- Funktion Compare-MultipleYamlFileVersions

.PARAMETER [parameter1]
Object Collection 1 (Pflichtfeld)

.PARAMETER [parameter2]
Object Collection 2 (Pflichtfeld)

.EXAMPLE
$comparisonResults = Compare-MultipleYamlFileVersions -Collection1 $BagVersions -Collection2 $AzureVersions
$comparisonResults | ForEach-Object { Write-Host $_ }

.OUTPUTS
Custom Powershell Object

.NOTES
- Version: 1.0
#>
function Compare-YamlFileVersions {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Collection1,

        [Parameter(Mandatory = $true)]
        [PSObject[]]$Collection2
    )

    # Creating a hashtable for each collection based on FileName as the key
    $hash1 = @{}
    $hash2 = @{}
    foreach ($item in $Collection1) {
        # $hash1[$item.FileName] = $item.Version
        $hash1[[System.IO.Path]::GetFileName($item.FileName)] = $item.Version
    }
    foreach ($item in $Collection2) {
        # hash2[$item.FileName] = $item.Version
         $hash2[[System.IO.Path]::GetFileName($item.FileName)] = $item.Version
    }

    # Compare versions for matching FileNames
    $results = New-Object System.Collections.ArrayList

    foreach ($key in $hash1.Keys) {
        if ($hash2.ContainsKey($key)) {
            # Compare versions
            $version1 = $hash1[$key]
            $version2 = $hash2[$key]
            if ($version1 -eq $version2) {
                $result = "FileName: $key - Both versions are the same: $version1"
            } elseif ($version1 -eq "Not Found" -or $version2 -eq "Not Found") {
                $result = "FileName: $key - One of the versions is not defined."
            } else {
                $result = "FileName: $key - Version difference: Collection1: $version1, Collection2: $version2"
            }
            [void]$results.Add($result)
        } else {
            [void]$results.Add("FileName: $key - Only in Collection1 with Version: $hash1[$key]")
        }
    }

    # Check for files only in Collection2
    foreach ($key in $hash2.Keys) {
        if (-not $hash1.ContainsKey($key)) {
            [void]$results.Add("FileName: $key - Only in Collection2 with Version: $hash2[$key]")
        }
    }

    return $results
}
#endregion Functions

# Bag Rules
$rootDirectory = "C:\Temp\YamlCompare\Bag"
$BagVersions = Get-YamlFileVersions -rootDirectory $rootDirectory

# Azure Rules
$rootDirectory = "C:\Temp\YamlCompare\Azure"
$AzureVersions = Get-YamlFileVersions -rootDirectory $rootDirectory

$comparisonResults = Compare-YamlFileVersions -Collection1 $BagVersions -Collection2 $AzureVersions

$comparisonResults | ForEach-Object { Write-Host $_ -ForegroundColor Green}

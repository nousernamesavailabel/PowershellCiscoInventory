# Load .NET assemblies for HttpClient and SSL handling
Add-Type -TypeDefinition @"
using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Cryptography.X509Certificates;
using System.Net.Security;
using System.Text;
public class TrustAllCertsHandler : HttpClientHandler {
    public TrustAllCertsHandler() {
        this.ServerCertificateCustomValidationCallback = (message, cert, chain, errors) => true;
    }
}
"@ -Language CSharp

# Enable TLS 1.2 for secure connections
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Prompt for username and password securely
$Credential = Get-Credential -Message "Enter Cisco device credentials"

# Extract username and password
$Username = $Credential.UserName
$Password = $Credential.GetNetworkCredential().Password

# Encode credentials for Basic Auth (same as Python)
$AuthBytes = [Text.Encoding]::ASCII.GetBytes("$Username`:$Password")
$Base64Auth = [Convert]::ToBase64String($AuthBytes)

# Read inventory.csv file
$inventoryFile = "inventory.csv"
if (!(Test-Path $inventoryFile)) {
    Write-Host "Error: Inventory file '$inventoryFile' not found!" -ForegroundColor Red
    exit
}

$hosts = Import-Csv -Path $inventoryFile | Select-Object -ExpandProperty host

if ($hosts.Count -eq 0) {
    Write-Host "Error: No hosts found in '$inventoryFile'!" -ForegroundColor Red
    exit
}

# Generate a timestamped results file name (format: inventory_results_YYYYMMDD_HHmmss.csv)
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputFile = "inventory_results_$timestamp.csv"

# Initialize HttpClient with SSL certificate validation disabled
$handler = New-Object TrustAllCertsHandler
$client = New-Object System.Net.Http.HttpClient($handler)

# Set headers
$client.DefaultRequestHeaders.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Basic", $Base64Auth)
$client.DefaultRequestHeaders.Accept.Add("application/yang-data+json")

# Function to retrieve data from REST API with error handling
function Get-DeviceData($deviceIP, $name, $url) {
    try {
        $response = $client.GetStringAsync($url).Result
        if (-not $response) {
            throw "No response received."
        }
        $jsonData = $response | ConvertFrom-Json
        return $jsonData.PSObject.Properties.Value
    } catch {
        Write-Host "Warning: Unable to fetch `${name}` from `${deviceIP}` ($($_.Exception.Message))" -ForegroundColor Yellow
        return "UNREACHABLE"
    }
}

# Prepare CSV output data
$csvData = @()

# Print table header
$header = "| {0,-15} | {1,-15} | {2,-12} | {3,-15} |" -f "Device", "Hostname", "OS Version", "Serial Number"
$separator = "-" * $header.Length
Write-Host $separator
Write-Host $header
Write-Host $separator

# Loop through each host and fetch device data
foreach ($deviceIP in $hosts) {
    # Define RESTCONF API URLs for each host
    $baseURL = "https://$deviceIP/restconf/data/Cisco-IOS-XE-native:native"
    $endpoints = @{
        "Hostname"      = "$baseURL/hostname"
        "OS Version"    = "$baseURL/version"
        "Serial Number" = "$baseURL/license/udi/sn"
    }

    # Fetch data with proper error handling
    $deviceData = @{}
    foreach ($key in $endpoints.Keys) {
        $deviceData[$key] = Get-DeviceData $deviceIP $key $endpoints[$key]
    }

    # Print device data in table format (Handles unreachable devices)
    Write-Host ("| {0,-15} | {1,-15} | {2,-12} | {3,-15} |" -f `
        $deviceIP, `
        $deviceData["Hostname"], `
        $deviceData["OS Version"], `
        $deviceData["Serial Number"]
    )
    Write-Host $separator

    # Add data to CSV output
    $csvData += [PSCustomObject]@{
        Device        = $deviceIP
        Hostname      = $deviceData["Hostname"]
        OS_Version    = $deviceData["OS Version"]
        Serial_Number = $deviceData["Serial Number"]
    }
}

# Export results to CSV with timestamp
$csvData | Export-Csv -Path $outputFile -NoTypeInformation

Write-Host "Results saved to '$outputFile'" -ForegroundColor Green

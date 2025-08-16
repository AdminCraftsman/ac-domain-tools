<#
.SYNOPSIS
    Queries WHOIS info for a list of domains from a CSV and exports the results to a CSV.

.DESCRIPTION
    Reads a CSV file containing a list of domains (one per row, column name "Domain"), 
    queries WHOIS info for each using Get-DomainWhoIsInfo.ps1, and exports the parsed results to a specified CSV.

.PARAMETER InputCsv
    Path to the input CSV file containing domains.

.PARAMETER OutputCsv
    Path to the output CSV file for WHOIS results.

.EXAMPLE
    .\Export-DomainWhoisInfo.ps1 -InputCsv .\domains.csv -OutputCsv .\whois-results.csv
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$InputCsv,
    [Parameter(Mandatory = $true)]
    [string]$OutputCsv,
    [parameter(Mandatory = $false)]
    [switch]$IncludeRawText
)

# Import domains from CSV (expects a column named 'Domain')
$domains = Import-Csv -Path $InputCsv

$results = @()
$results +=         [PSCustomObject]@{
            Domain          = $null
            Registrar       = $null
            ExpiryDate      = $null
            CreationDate    = $null
            UpdatedDate     = $null
            RegistrantName  = $null
            RegistrantEmail = $null
            AdminName       = $null
            AdminEmail      = $null
            TechName        = $null
            TechEmail       = $null
            NameServer      = $null
        }

$results += foreach ($row in $domains) {
    $domain = $row.Domain
    if (-not $domain) { continue }
    try {
        Write-Host "Querying WHOIS for $domain..."
        if($IncludeRawText) {
            $whoisInfo = .\Get-DomainWhoIsInfo.ps1 -Domain $domain -IncludeRawText
        }
        else {
            $whoisInfo = .\Get-DomainWhoIsInfo.ps1 -Domain $domain
        }
        # Add the domain to the result object for clarity
        $whoisInfo | Add-Member -NotePropertyName Domain -NotePropertyValue $domain -Force
        $whoisInfo
    }
    catch {
        Write-Warning "Failed to get WHOIS info for $($domain): $_"
        [PSCustomObject]@{
            Domain          = $domain
            Registrar       = $null
            ExpiryDate      = $null
            CreationDate    = $null
            UpdatedDate     = $null
            RegistrantName  = $null
            RegistrantEmail = $null
            AdminName       = $null
            AdminEmail      = $null
            TechName        = $null
            TechEmail       = $null
            NameServer      = $null
        }
    }
}

$results | Export-Csv -Path $OutputCsv -NoTypeInformation

Write-Host "Export complete: $OutputCsv"
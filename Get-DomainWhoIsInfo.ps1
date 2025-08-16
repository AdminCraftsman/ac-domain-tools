<#
.SYNOPSIS
    Retrieves and parses WHOIS information for a specified domain.

.DESCRIPTION
    This script queries the appropriate WHOIS server for a given domain, retrieves the raw WHOIS data, 
    and parses common fields such as registrar, expiry date, creation date, and contact information.

.NOTES
    Name: Get-DomainWhoIsInfo
    Author: Brandon Fingerhut
    Version: 0.1
    Modify Date: 2025-08-16
    Required Modules: 
        - BW.Utils.BindZoneFile (https://github.com/realslacker/BW.Utils.BindZoneFile)

    References:
    - https://arstechnica.com/gadgets/2020/08/understanding-dns-anatomy-of-a-bind-zone-file/
    - https://developers.cloudflare.com/api/operations/dns-records-for-a-zone-create-dns-record

#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Domain,
    [parameter(Mandatory = $false)]
    [switch]$IncludeRawText
)

function Get-Whois {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Domain,
        [string]$WhoisServer
    )

    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient($WhoisServer, 43)
        $stream = $tcpClient.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream)
        $writer.AutoFlush = $true
        $writer.WriteLine($Domain)
        $reader = New-Object System.IO.StreamReader($stream)
        $response = $reader.ReadToEnd()
        $reader.Close()
        $writer.Close()
        $tcpClient.Close()
        return $response
    }
    catch {
        Write-Error "Failed to query WHOIS server $WhoisServer for $Domain. $_"
    }
}

function Get-WhoisRecord {
    param([Parameter(Mandatory = $true)][string]$Domain)

    # Step 1: Get TLD WHOIS server from IANA
    $tld = ($Domain -split '\.')[-1]
    $ianaResponse = Get-Whois -Domain $tld -WhoisServer "whois.iana.org"

    if ($ianaResponse -match "whois:\s+(?<server>\S+)") {
        $whoisServer = $Matches.server
    }
    else {
        throw "Could not find WHOIS server for TLD: $tld"
    }

    Write-Verbose "Using WHOIS server: $whoisServer"

    # Step 2: Query the actual WHOIS server
    $whoisResponse = Get-Whois -Domain $Domain -WhoisServer $whoisServer
    return $whoisResponse
}

function Convert-WhoisToObject {
    param([string]$WhoisText)

    $result = [ordered]@{}

    # Common fields (not standardized – regex matches may need tweaking per TLD)
    if ($WhoisText -match "Domain Name:\s*(?<v>.+)") { $result["DomainName"] = $Matches.v.Trim() }
    if ($WhoisText -match "Registrar:\s*(?<v>.+)") { $result["Registrar"] = $Matches.v.Trim() }
    if ($WhoisText -match "Registry Expiry Date:\s*(?<v>.+)") { $result["ExpiryDate"] = $Matches.v.Trim() }
    if ($WhoisText -match "Creation Date:\s*(?<v>.+)") { $result["CreationDate"] = $Matches.v.Trim() }
    if ($WhoisText -match "Updated Date:\s*(?<v>.+)") { $result["UpdatedDate"] = $Matches.v.Trim() }
    if ($WhoisText -match "Registrant Name:\s*(?<v>.+)") { $result["RegistrantName"] = $Matches.v.Trim() }
    if ($WhoisText -match "Registrant Email:\s*(?<v>.+)") { $result["RegistrantEmail"] = $Matches.v.Trim() }
    if ($WhoisText -match "Admin Name:\s*(?<v>.+)") { $result["AdminName"] = $Matches.v.Trim() }
    if ($WhoisText -match "Admin Email:\s*(?<v>.+)") { $result["AdminEmail"] = $Matches.v.Trim() }
    if ($WhoisText -match "Tech Name:\s*(?<v>.+)") { $result["TechName"] = $Matches.v.Trim() }
    if ($WhoisText -match "Tech Email:\s*(?<v>.+)") { $result["TechEmail"] = $Matches.v.Trim() }
    if ($WhoisText -match "Name Server:\s*(?<v>.+)") { $result["NameServer"] = $Matches.v.Trim() }
    if ($WhoisText -match "Registry Expiry Date:\s*(?<v>.+)") { $result["ExpiryDate"] = $Matches.v.Trim() }

    <#
    if ($WhoisText -match "Domain Status:\s*(?<v>.+)") { 
        $result["Status"] = ($WhoisText | Select-String "Domain Status:").Line -replace "Domain Status:\s*", "" 
    }
    
    if ($WhoisText -match "Name Server:\s*(?<v>.+)") { 
        $result["NameServers"] = ($WhoisText | Select-String "Name Server:").Line -replace "Name Server:\s*", "" 
    }
    #>
    
    if($IncludeRawText) {
        $result["RawText"] = $WhoisText
    }

    return [PSCustomObject]$result
}

$response = Get-WhoisRecord -Domain $Domain
$parsed = Convert-WhoisToObject $response

return $parsed
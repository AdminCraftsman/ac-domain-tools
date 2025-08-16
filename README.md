# ac-domain-tools
AdminCraftsman - Domain Tools

## Overview

This repository contains PowerShell scripts for querying and exporting WHOIS information for domains.

## Scripts

### Get-DomainWhoIsInfo.ps1

Retrieves and parses WHOIS information for a specified domain.  
- Queries the appropriate WHOIS server for a given domain.
- Parses common fields such as registrar, expiry date, creation date, and contact information.
- Can optionally include the raw WHOIS text in the output.

### Export-DomainWhoisInfo.ps1

Queries WHOIS info for a list of domains from a CSV and exports the results to a CSV file.  
- Reads a CSV file containing a list of domains (expects a column named `Domain`).
- Uses `Get-DomainWhoIsInfo.ps1` to retrieve WHOIS info for each domain.
- Exports the parsed results to a specified output CSV file.
- Can optionally include the raw WHOIS text in the export.

## Example Usage

```powershell
# Export WHOIS info for domains listed in [domains.csv](http://_vscodecontentref_/0) to whois-results.csv
[Export-DomainWhoisInfo.ps1](http://_vscodecontentref_/1) -InputCsv [domains.csv](http://_vscodecontentref_/2) -OutputCsv .\whois-results.csv
```

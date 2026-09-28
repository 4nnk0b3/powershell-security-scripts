#requires -Version 5.1
<#
.SYNOPSIS
    Performs a lightweight Windows security baseline audit.

.DESCRIPTION
    Collects a few defensive security indicators from a Windows workstation/server:
    - Operating system information
    - Microsoft Defender status (when available)
    - Windows Firewall profile status
    - Remote Desktop configuration
    - SMBv1 feature state (when available)
    - Members of the local Administrators group

    The script does not make changes to the system. Results are displayed on screen
    and can optionally be exported to JSON.

.PARAMETER OutputPath
    Optional path for a JSON report.

.EXAMPLE
    .\Invoke-SecurityBaselineAudit.ps1

.EXAMPLE
    .\Invoke-SecurityBaselineAudit.ps1 -OutputPath .\reports\security-audit.json
#>

[CmdletBinding()]
param(
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

function Add-Check {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Details
    )

    [PSCustomObject]@{
        Check   = $Name
        Status  = $Status
        Details = $Details
    }
}

$results = [System.Collections.Generic.List[object]]::new()

# Operating system
$os = Get-CimInstance Win32_OperatingSystem
if ($os) {
    $results.Add((Add-Check -Name "Operating System" -Status "INFO" `
        -Details "$($os.Caption) | Version $($os.Version) | Build $($os.BuildNumber)"))
}

# Microsoft Defender
$defender = Get-MpComputerStatus
if ($defender) {
    $status = if ($defender.RealTimeProtectionEnabled -and $defender.AntivirusEnabled) {
        "PASS"
    } else {
        "REVIEW"
    }

    $details = "AntivirusEnabled=$($defender.AntivirusEnabled); RealTimeProtectionEnabled=$($defender.RealTimeProtectionEnabled); OnAccessProtectionEnabled=$($defender.OnAccessProtectionEnabled)"
    $results.Add((Add-Check -Name "Microsoft Defender" -Status $status -Details $details))
}
else {
    $results.Add((Add-Check -Name "Microsoft Defender" -Status "N/A" `
        -Details "Microsoft Defender cmdlets were not available on this system."))
}

# Windows Firewall
$firewallProfiles = Get-NetFirewallProfile
if ($firewallProfiles) {
    foreach ($profile in $firewallProfiles) {
        $status = if ($profile.Enabled) { "PASS" } else { "REVIEW" }
        $results.Add((Add-Check -Name "Windows Firewall - $($profile.Name)" `
            -Status $status -Details "Enabled=$($profile.Enabled)"))
    }
}
else {
    $results.Add((Add-Check -Name "Windows Firewall" -Status "N/A" `
        -Details "Firewall profile information was not available."))
}

# Remote Desktop
$rdpValue = Get-ItemPropertyValue `
    -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" `
    -Name "fDenyTSConnections"

if ($null -ne $rdpValue) {
    $rdpEnabled = ($rdpValue -eq 0)
    $status = if ($rdpEnabled) { "REVIEW" } else { "PASS" }
    $details = if ($rdpEnabled) { "Remote Desktop is enabled." } else { "Remote Desktop is disabled." }

    $results.Add((Add-Check -Name "Remote Desktop" -Status $status -Details $details))
}
else {
    $results.Add((Add-Check -Name "Remote Desktop" -Status "N/A" `
        -Details "RDP configuration could not be read."))
}

# SMBv1
$smb1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
if ($smb1) {
    $status = if ($smb1.State -eq "Enabled") { "REVIEW" } else { "PASS" }
    $results.Add((Add-Check -Name "SMBv1" -Status $status -Details "State=$($smb1.State)"))
}
else {
    $results.Add((Add-Check -Name "SMBv1" -Status "N/A" `
        -Details "Windows optional feature information was not available."))
}

# Local Administrators
$adminMembers = @()
try {
    $adminMembers = Get-LocalGroupMember -Group "Administrators" | Select-Object -ExpandProperty Name
}
catch {
    $adminMembers = @()
}

if ($adminMembers.Count -gt 0) {
    $results.Add((Add-Check -Name "Local Administrators" -Status "INFO" `
        -Details ($adminMembers -join "; ")))
}
else {
    $results.Add((Add-Check -Name "Local Administrators" -Status "N/A" `
        -Details "Could not enumerate the local Administrators group."))
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host ""
Write-Host "Windows Security Baseline Audit" -ForegroundColor Cyan
Write-Host "Generated: $timestamp"
Write-Host "Computer : $env:COMPUTERNAME"
Write-Host ""

$results | Format-Table -AutoSize

if ($OutputPath) {
    $parent = Split-Path -Parent $OutputPath
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -Path $parent -ItemType Directory -Force | Out-Null
    }

    $report = [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        GeneratedAt  = $timestamp
        Checks       = $results
    }

    $report | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "JSON report saved to: $OutputPath" -ForegroundColor Green
}

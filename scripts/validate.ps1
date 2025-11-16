#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validation script for CACA Splunk app

.DESCRIPTION
    Performs comprehensive validation checks on the Splunk app including:
    - Configuration file syntax
    - Version consistency
    - XML validation
    - JSON validation
    - Lookup table definitions
    - Package structure
    - Security checks

.PARAMETER Quick
    Run only quick validation checks (skip AppInspect)

.PARAMETER Verbose
    Show detailed output

.EXAMPLE
    .\validate.ps1

.EXAMPLE
    .\validate.ps1 -Quick -Verbose
#>

param(
    [switch]$Quick,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$script:ErrorCount = 0
$script:WarningCount = 0

# Colors for output
function Write-Success { param($Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Failure { param($Message) Write-Host "✗ $Message" -ForegroundColor Red; $script:ErrorCount++ }
function Write-Warning { param($Message) Write-Host "⚠ $Message" -ForegroundColor Yellow; $script:WarningCount++ }
function Write-Info { param($Message) Write-Host "ℹ $Message" -ForegroundColor Cyan }
function Write-Step { param($Message) Write-Host "`n=== $Message ===" -ForegroundColor Magenta }

# Get script directory (repo root)
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  CACA Splunk App Validation                                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# ============================================================================
# 1. Check Required Files
# ============================================================================
Write-Step "Checking Required Files"

$RequiredFiles = @(
    "app.manifest",
    "default/app.conf",
    "README.md",
    "LICENSE",
    "metadata/default.meta"
)

foreach ($file in $RequiredFiles) {
    if (Test-Path $file) {
        if ($Verbose) { Write-Success "Found: $file" }
    } else {
        Write-Failure "Missing required file: $file"
    }
}

if (-not $Verbose -and $script:ErrorCount -eq 0) {
    Write-Success "All required files present"
}

# ============================================================================
# 2. Validate JSON Files
# ============================================================================
Write-Step "Validating JSON Files"

try {
    $manifest = Get-Content "app.manifest" -Raw | ConvertFrom-Json
    Write-Success "app.manifest is valid JSON"

    $manifestVersion = $manifest.info.id.version
    $manifestId = $manifest.info.id.name

    if ($Verbose) {
        Write-Info "  Version: $manifestVersion"
        Write-Info "  App ID: $manifestId"
    }
} catch {
    Write-Failure "app.manifest is invalid JSON: $_"
}

# ============================================================================
# 3. Validate XML Files
# ============================================================================
Write-Step "Validating XML Files"

$xmlFiles = Get-ChildItem -Path "default/data/ui" -Filter "*.xml" -Recurse -ErrorAction SilentlyContinue

if ($xmlFiles) {
    foreach ($xmlFile in $xmlFiles) {
        try {
            [xml]$xml = Get-Content $xmlFile.FullName
            if ($Verbose) { Write-Success "$($xmlFile.Name) is valid XML" }
        } catch {
            Write-Failure "$($xmlFile.Name) is invalid XML: $_"
        }
    }

    if (-not $Verbose -and $script:ErrorCount -eq 0) {
        Write-Success "All $($xmlFiles.Count) XML files are valid"
    }
} else {
    Write-Warning "No XML files found"
}

# ============================================================================
# 4. Check Version Consistency
# ============================================================================
Write-Step "Checking Version Consistency"

try {
    $appConf = Get-Content "default/app.conf" -Raw

    if ($appConf -match 'version\s*=\s*(.+)') {
        $appConfVersion = $Matches[1].Trim()

        if ($manifestVersion -eq $appConfVersion) {
            Write-Success "Version is consistent: $manifestVersion"
        } else {
            Write-Failure "Version mismatch - app.manifest: $manifestVersion, app.conf: $appConfVersion"
        }
    } else {
        Write-Failure "Could not find version in app.conf"
    }
} catch {
    Write-Failure "Error checking version: $_"
}

# ============================================================================
# 5. Check App ID Consistency
# ============================================================================
Write-Step "Checking App ID Consistency"

try {
    if ($appConf -match 'id\s*=\s*(.+)') {
        $appConfId = $Matches[1].Trim()

        if ($manifestId -eq $appConfId) {
            Write-Success "App ID is consistent: $manifestId"
        } else {
            Write-Failure "App ID mismatch - app.manifest: $manifestId, app.conf: $appConfId"
        }
    } else {
        Write-Failure "Could not find package id in app.conf"
    }
} catch {
    Write-Failure "Error checking app ID: $_"
}

# ============================================================================
# 6. Validate .conf File Syntax
# ============================================================================
Write-Step "Validating Configuration Files"

$confFiles = Get-ChildItem -Path "default" -Filter "*.conf" -ErrorAction SilentlyContinue

foreach ($confFile in $confFiles) {
    $lineNum = 0
    $inStanza = $false
    $hasErrors = $false

    Get-Content $confFile.FullName | ForEach-Object {
        $lineNum++
        $line = $_.Trim()

        # Skip empty lines and comments
        if (-not $line -or $line.StartsWith("#")) {
            return
        }

        # Check for stanza headers
        if ($line -match '^\[.+\]$') {
            $inStanza = $true
            return
        }

        # Check for key=value pairs
        if ($inStanza -and $line -match '=') {
            $parts = $line -split '=', 2
            if (-not $parts[0].Trim()) {
                Write-Failure "$($confFile.Name):$lineNum - Empty key in key=value pair"
                $hasErrors = $true
            }
        }
    }

    if (-not $hasErrors) {
        if ($Verbose) { Write-Success "$($confFile.Name) syntax is valid" }
    }
}

if (-not $Verbose -and $script:ErrorCount -eq 0) {
    Write-Success "All $($confFiles.Count) .conf files have valid syntax"
}

# ============================================================================
# 7. Check for Sensitive Data
# ============================================================================
Write-Step "Scanning for Sensitive Data"

$sensitivePatterns = @{
    'password\s*=\s*\S+' = 'hardcoded password'
    'token\s*=\s*\S+' = 'hardcoded token'
    'api[_-]?key\s*=\s*\S+' = 'hardcoded API key'
    'secret\s*=\s*\S+' = 'hardcoded secret'
}

$foundSensitive = $false
foreach ($confFile in $confFiles) {
    $lineNum = 0
    Get-Content $confFile.FullName | ForEach-Object {
        $lineNum++
        $line = $_

        if ($line.Trim().StartsWith("#")) { return }

        foreach ($pattern in $sensitivePatterns.Keys) {
            if ($line -match $pattern) {
                Write-Warning "$($confFile.Name):$lineNum - Potential $($sensitivePatterns[$pattern])"
                $foundSensitive = $true
            }
        }
    }
}

if (-not $foundSensitive) {
    Write-Success "No obvious sensitive data detected"
}

# ============================================================================
# 8. Validate Lookup Tables
# ============================================================================
Write-Step "Validating Lookup Tables"

if (Test-Path "default/transforms.conf") {
    $transformsConf = Get-Content "default/transforms.conf" -Raw
    $lookupDefs = [regex]::Matches($transformsConf, '^\[([^\]]+)\]', [System.Text.RegularExpressions.RegexOptions]::Multiline)

    $foundIssues = $false
    foreach ($match in $lookupDefs) {
        $lookupName = $match.Groups[1].Value

        # Check if CSV exists (basic check)
        $csvFile = "lookups/$lookupName.csv"
        if (-not (Test-Path $csvFile)) {
            # Try without suffix
            $csvFile = "lookups/$($lookupName -replace '_lookup$','').csv"
            if (-not (Test-Path $csvFile)) {
                Write-Warning "Lookup '$lookupName' may not have corresponding CSV file"
                $foundIssues = $true
            }
        }
    }

    if (-not $foundIssues) {
        Write-Success "Validated $($lookupDefs.Count) lookup definitions"
    }
} else {
    Write-Info "No transforms.conf found (lookups not used)"
}

# ============================================================================
# 9. Check Package Structure
# ============================================================================
Write-Step "Checking Package Structure"

$unwantedPatterns = @(
    ".git",
    "__pycache__",
    "*.pyc",
    "*.swp",
    "*.swo",
    ".DS_Store"
)

$foundUnwanted = $false
foreach ($pattern in $unwantedPatterns) {
    $found = Get-ChildItem -Path . -Filter $pattern -Recurse -Force -ErrorAction SilentlyContinue
    if ($found) {
        Write-Warning "Found unwanted files matching pattern: $pattern"
        $foundUnwanted = $true
    }
}

# Check local/ directory
if (Test-Path "local") {
    $localFiles = Get-ChildItem -Path "local" -ErrorAction SilentlyContinue
    if ($localFiles) {
        Write-Warning "local/ directory exists and is not empty (should not be in version control)"
    }
}

if (-not $foundUnwanted) {
    Write-Success "Package structure is clean"
}

# ============================================================================
# 10. Check .gitignore
# ============================================================================
Write-Step "Checking .gitignore Coverage"

$shouldIgnore = @("local/", "*.pyc", "__pycache__/", ".DS_Store", "*.log")

if (Test-Path ".gitignore") {
    $gitignore = Get-Content ".gitignore" -Raw
    $missing = @()

    foreach ($pattern in $shouldIgnore) {
        if ($gitignore -notmatch [regex]::Escape($pattern)) {
            $missing += $pattern
        }
    }

    if ($missing.Count -gt 0) {
        Write-Warning ".gitignore missing recommended patterns: $($missing -join ', ')"
    } else {
        Write-Success ".gitignore covers recommended patterns"
    }
} else {
    Write-Warning "No .gitignore file found"
}

# ============================================================================
# 11. Run Splunk AppInspect (if not Quick mode)
# ============================================================================
if (-not $Quick) {
    Write-Step "Checking for Splunk AppInspect"

    $appInspect = Get-Command splunk-appinspect -ErrorAction SilentlyContinue

    if ($appInspect) {
        Write-Info "Running Splunk AppInspect (this may take a minute)..."

        try {
            # Create temporary package directory
            $packageDir = Join-Path $env:TEMP "caca-package-$(Get-Date -Format 'yyyyMMddHHmmss')"
            New-Item -ItemType Directory -Path $packageDir -Force | Out-Null

            # Copy files (exclude dev files)
            $excludes = @('.git*', 'local', 'devnotes', '*.pyc', '__pycache__', '.DS_Store')

            Get-ChildItem -Path $RepoRoot | Where-Object {
                $item = $_
                -not ($excludes | Where-Object { $item.Name -like $_ })
            } | Copy-Item -Destination $packageDir -Recurse -Force

            # Run AppInspect
            $reportFile = Join-Path $RepoRoot "appinspect_report.json"
            & splunk-appinspect inspect $packageDir --mode precert --included-tags cloud --output-file $reportFile 2>&1 | Out-Null

            if (Test-Path $reportFile) {
                $report = Get-Content $reportFile -Raw | ConvertFrom-Json
                $summary = $report.summary

                Write-Info "`nAppInspect Summary:"
                Write-Host "  Failures: $($summary.failure)" -ForegroundColor $(if ($summary.failure -gt 0) { "Red" } else { "Green" })
                Write-Host "  Errors: $($summary.error)" -ForegroundColor $(if ($summary.error -gt 0) { "Red" } else { "Green" })
                Write-Host "  Warnings: $($summary.warning)" -ForegroundColor $(if ($summary.warning -gt 0) { "Yellow" } else { "Green" })

                if ($summary.failure -gt 0 -or $summary.error -gt 0) {
                    Write-Failure "AppInspect found failures or errors"
                } else {
                    Write-Success "AppInspect passed"
                }
            }

            # Cleanup
            Remove-Item $packageDir -Recurse -Force -ErrorAction SilentlyContinue

        } catch {
            Write-Warning "AppInspect failed to run: $_"
        }
    } else {
        Write-Info "Splunk AppInspect not installed (install with: pip install splunk-appinspect)"
        Write-Info "Skipping AppInspect validation. Use -Quick flag to skip this check."
    }
}

# ============================================================================
# Summary
# ============================================================================
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Validation Summary                                        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

if ($script:ErrorCount -eq 0 -and $script:WarningCount -eq 0) {
    Write-Host "🎉 All checks passed! App is ready for packaging." -ForegroundColor Green
    exit 0
} elseif ($script:ErrorCount -eq 0) {
    Write-Host "✓ No errors found, but there are $script:WarningCount warning(s)." -ForegroundColor Yellow
    Write-Host "  Review warnings above before packaging." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "✗ Found $script:ErrorCount error(s) and $script:WarningCount warning(s)." -ForegroundColor Red
    Write-Host "  Fix errors before packaging the app." -ForegroundColor Red
    exit 1
}

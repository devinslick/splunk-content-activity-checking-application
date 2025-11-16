# CI/CD and Validation Setup

This directory contains validation and CI/CD tooling for the CACA Splunk app.

## Files

### `validate.ps1`
PowerShell validation script for local development on Windows.

**Usage:**
```powershell
# Run full validation (including AppInspect if available)
.\scripts\validate.ps1

# Run quick validation (skip AppInspect)
.\scripts\validate.ps1 -Quick

# Run with verbose output
.\scripts\validate.ps1 -Verbose
```

**Checks performed:**
- Required files exist
- JSON/XML syntax validation
- Version consistency (app.manifest vs app.conf)
- App ID consistency
- .conf file syntax
- Sensitive data scanning
- Lookup table validation
- Package structure
- .gitignore coverage
- Splunk AppInspect (optional)

### `validate.sh` (Future)
Bash equivalent for Linux/macOS users. Not yet implemented.

## GitHub Actions

Validation also runs automatically on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Manual workflow dispatch

See `.github/workflows/validate.yml` for workflow configuration.

## Pre-commit Hooks

Install pre-commit hooks for automatic validation before commits:

```powershell
# Install pre-commit
pip install pre-commit

# Install hooks in repository
pre-commit install

# Run manually on all files
pre-commit run --all-files
```

See `.pre-commit-config.yaml` for hook configuration.

## Splunk AppInspect

For best results, install the official Splunk AppInspect tool:

```powershell
pip install splunk-appinspect
```

This enables:
- Splunkbase compliance checking
- Cloud compatibility validation
- Security vulnerability scanning
- Best practices validation

## Exit Codes

- `0` - All checks passed (or warnings only)
- `1` - Errors found, fix required

## Troubleshooting

**AppInspect not found:**
Install with `pip install splunk-appinspect` or use `-Quick` flag to skip.

**Version mismatch errors:**
Update both `app.manifest` and `default/app.conf` to have matching versions.

**XML validation fails:**
Check that all dashboard XML files are well-formed. Use an XML validator or IDE with XML support.

**Python not found:**
Ensure Python 3.7+ is installed and in your PATH.

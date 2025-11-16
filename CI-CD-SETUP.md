# CI/CD Setup Guide

This guide helps you set up the validation and CI/CD tooling for the CACA Splunk app.

## Quick Start

### 1. Local Validation (Windows)

Run the PowerShell validation script:

```powershell
# Full validation
.\scripts\validate.ps1

# Quick validation (skip AppInspect)
.\scripts\validate.ps1 -Quick
```

### 2. Install Pre-commit Hooks (Recommended)

Install pre-commit to automatically validate before each commit:

```powershell
# Install pre-commit
pip install pre-commit

# Install the hooks in your repo
pre-commit install

# Test it
pre-commit run --all-files
```

### 3. GitHub Actions (Automatic)

GitHub Actions automatically run on:
- ✅ Push to `main` or `develop` branches
- ✅ Pull requests
- ✅ Manual workflow dispatch

No setup needed - it just works!

---

## What Gets Checked?

### ✅ Configuration Files
- `.conf` file syntax validation
- Version consistency (app.manifest ↔ app.conf)
- App ID consistency
- Required files present

### ✅ Content Files
- XML syntax (dashboards, navigation)
- JSON syntax (app.manifest)
- Lookup table definitions match CSV files

### ✅ Security
- No hardcoded passwords/tokens/API keys
- No private keys committed
- Proper file permissions

### ✅ Package Quality
- No unwanted files (`.git`, `local/`, `*.pyc`)
- Proper `.gitignore` coverage
- No large files

### ✅ Splunk AppInspect (Optional)
- Splunkbase compliance
- Cloud compatibility
- Best practices
- Security vulnerabilities

---

## Installation Details

### Prerequisites

**Required:**
- Git
- Python 3.7+
- PowerShell (Windows) or Bash (Linux/macOS)

**Optional but recommended:**
- Splunk AppInspect: `pip install splunk-appinspect`
- Pre-commit: `pip install pre-commit`

### Installing Splunk AppInspect

AppInspect is Splunk's official validation tool:

```powershell
# Install via pip
pip install splunk-appinspect

# Verify installation
splunk-appinspect --version
```

Benefits:
- Official Splunkbase validation
- Cloud compatibility checks
- Security scanning
- Best practices enforcement

### Setting Up Pre-commit

Pre-commit hooks run validation before each `git commit`:

```powershell
# 1. Install pre-commit
pip install pre-commit

# 2. Install hooks in your repo (one-time setup)
cd c:\Users\Devin\Repos\splunk-content-monitoring-console
pre-commit install

# 3. Test the setup
pre-commit run --all-files
```

Now validation runs automatically before every commit!

**Skip hooks temporarily:**
```powershell
git commit --no-verify -m "Emergency fix"
```

---

## Usage Examples

### Before Committing

```powershell
# Run local validation
.\scripts\validate.ps1 -Quick

# If no errors, commit
git add .
git commit -m "My changes"
# Pre-commit hooks run automatically here
```

### Before Publishing

```powershell
# Run full validation including AppInspect
.\scripts\validate.ps1

# Check the results
# Fix any errors or warnings
# Review appinspect_report.json if generated
```

### In CI/CD

GitHub Actions run automatically:

1. Push your changes to GitHub
2. Go to **Actions** tab in your repo
3. Watch the validation workflow run
4. Review any failures in the workflow logs

---

## Troubleshooting

### "splunk-appinspect not found"

**Solution:** Install AppInspect or use `-Quick` flag:
```powershell
pip install splunk-appinspect
# OR
.\scripts\validate.ps1 -Quick
```

### "Version mismatch" error

**Solution:** Update both files to match:
- `app.manifest` → `info.id.version`
- `default/app.conf` → `version =`

### "XML validation failed"

**Solution:** Check dashboard XML syntax:
```powershell
# Open the failing XML file
# Look for unclosed tags, invalid characters, etc.
# Use an XML validator or IDE with XML support
```

### Pre-commit hooks slow

**Solution:** Skip certain hooks or run selectively:
```powershell
# Skip all hooks temporarily
git commit --no-verify

# Run specific hook
pre-commit run check-yaml --all-files
```

### GitHub Actions failed

**Solution:**
1. Go to Actions tab in GitHub
2. Click on the failed workflow
3. Expand the failed step
4. Read the error message
5. Fix locally and push again

---

## Customization

### Modify Pre-commit Hooks

Edit `.pre-commit-config.yaml`:
- Add/remove hooks
- Change hook arguments
- Skip specific checks

### Modify GitHub Actions

Edit `.github/workflows/validate.yml`:
- Change trigger branches
- Add/remove validation steps
- Adjust failure conditions

### Modify Local Script

Edit `scripts/validate.ps1`:
- Add custom checks
- Change validation logic
- Adjust output formatting

---

## Best Practices

1. **Run validation before pushing**
   ```powershell
   .\scripts\validate.ps1 -Quick
   git push
   ```

2. **Use pre-commit hooks**
   - Catches issues early
   - Prevents bad commits
   - Saves time in CI/CD

3. **Fix warnings, not just errors**
   - Warnings can become errors
   - Better code quality
   - Easier maintenance

4. **Run full validation before releases**
   ```powershell
   .\scripts\validate.ps1  # Full check with AppInspect
   ```

5. **Review AppInspect reports**
   - Check `appinspect_report.json`
   - Address all failures
   - Consider fixing warnings

---

## Support

For issues with:
- **Validation scripts**: Check `scripts/README.md`
- **Pre-commit**: Visit https://pre-commit.com/
- **AppInspect**: Visit https://dev.splunk.com/enterprise/docs/developapps/testvalidate/appinspect/
- **GitHub Actions**: Check `.github/workflows/validate.yml` comments

Happy coding! 🚀

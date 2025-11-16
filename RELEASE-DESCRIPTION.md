# Splunkbase Release Description

This document contains the content for the Splunkbase listing tabs.

---

## Summary

**CACA (Content Activity Checking Application)** helps Splunk teams track the usage, health, and lifecycle of their dashboards and content. Get clear, metric-driven insights to answer critical questions: "Is anyone using this dashboard I built?" • "Which dashboards are most critical to our users?" • "Is this dashboard performing well?" • "Which dashboards are safe to archive?"

**Key Benefits:**
- **Automated Discovery** - Automatically catalogs all dashboards across your environment
- **Usage Analytics** - Track views, users, and engagement patterns over time
- **Health Monitoring** - Detect and track dashboard errors and warnings
- **Performance Tracking** - Identify slow-loading dashboards that need optimization
- **Stale Detection** - Find unused dashboards that can be archived or deleted
- **Efficient Storage** - Uses Splunk's native metrics index for low-impact data collection

**Why CACA?** While Splunk Monitoring Console (DMC) focuses on system health for admins, CACA answers a different question for content creators and users: "Is my content useful and working well?"

---

## Details

### Features

**Dashboard Monitoring**
- Automated dashboard discovery across all apps (including private dashboards)
- Real-time usage tracking (views by user and timestamp)
- Edit history monitoring (creation and modification tracking)
- Health monitoring from internal logs (errors and warnings)
- Performance monitoring (load times and slow dashboard identification)
- Stale dashboard detection (30+ days without access)

**Metrics & Analytics**
- Efficient metrics storage using Splunk's native metrics index
- Near real-time collection with 5-15 minute scheduled searches
- Historical trending up to 1 year (configurable retention)
- Aggregate statistics across all content

**Visualization & Reporting**
- **Dashboard Leaderboard** - Centralized view of all monitored dashboards with sortable metrics
- **CACA Admin Dashboard** - Multi-dimensional filtering, bulk management, and workflow guides
- **Detailed Analytics** - Drill down into individual dashboard performance
- **Health Status Indicators** - Color-coded badges (Healthy, Warning, Critical, Stale)
- **Trending Charts** - Track views, errors, and performance over time

**Embeddable Badges**
- GitHub-style badges showing usage and health metrics
- Customizable XML templates for quick integration
- Multiple badge styles (single-stat or multi-metric)
- Self-service implementation for dashboard owners

**Search Macros**
Pre-built macros for common queries:
- `get_dashboards_with_errors` - Find dashboards with health issues
- `get_slow_dashboards` - Identify performance problems
- `get_problematic_dashboards` - All dashboards needing attention
- `get_dashboard_stats("name")` - Comprehensive stats for specific dashboard
- `get_all_dashboards_summary` - Overview of all dashboard metrics
- `get_top_dashboards(metric)` - Top 10 dashboards by views or edits

### Architecture

Three-stage pipeline for efficiency:
1. **Collect** - Scheduled searches analyze `_internal` and `_audit` logs
2. **Store** - Metrics written to dedicated metrics index using `mcollect`
3. **Query** - Fast retrieval via `mstats` and reusable search macros

**Resource Impact:** Lightweight scheduled searches run at low priority to avoid impacting user searches or system performance.

### Use Cases

- **Content Governance** - Identify and archive unused dashboards
- **Performance Optimization** - Find and fix slow-loading dashboards
- **Health Monitoring** - Proactively detect dashboard errors
- **Usage Analytics** - Understand which content delivers the most value
- **Team Metrics** - Demonstrate content creation impact with real data
- **Compliance** - Maintain audit trails for dashboard access and changes

---

## Installation

### Requirements

- Splunk Enterprise 8.0 or later
- Access to `_internal` and `_audit` indexes
- Permissions to create metrics indexes and scheduled searches
- Admin or appropriate capabilities to discover private dashboards (optional)

### Installation Steps

**Method 1: Via Splunk Web (Recommended)**

1. Download the latest release package from Splunkbase
2. In Splunk Web, navigate to **Apps → Manage Apps**
3. Click **Install app from file**
4. Upload the package file
5. Click **Upload**
6. Restart Splunk if prompted

**Method 2: Manual Installation**

1. Extract the app package to `$SPLUNK_HOME/etc/apps/`
2. Ensure the directory is named `caca`
3. Restart Splunk:
   ```bash
   $SPLUNK_HOME/bin/splunk restart
   ```

### Initial Setup (Required)

After installation, complete these steps to activate CACA:

**Step 1: Verify Index Creation**

The `caca_metrics` index is created automatically. Verify:
```spl
| eventcount summarize=false index=caca_metrics
```

**Step 2: Populate Dashboard Registry**

Navigate to the **CACA app** in Splunk Web and run this search:
```spl
| rest /services/data/ui/views splunk_server=local count=0 search="sharing=*"
| search isDashboard=1 OR isVisible=1
| eval dashboard_uri="/app/".eai:acl.app."/".title
| eval pretty_name=coalesce(label, title)
| eval app=eai:acl.app, owner=eai:acl.owner, sharing=eai:acl.sharing
| eval description=coalesce(eai:data, ""), status="active"
| table dashboard_uri pretty_name app owner sharing description status
| outputlookup dashboard_registry.csv
```

Verify the registry:
```spl
| inputlookup dashboard_registry | stats count
```

**Step 3: Enable Scheduled Searches**

Navigate to **Settings → Searches, reports, and alerts** and enable:
- Dashboard Views - Metrics Collector (every 5 minutes)
- Dashboard Edits - Metrics Collector (every 10 minutes)
- Dashboard Performance - Metrics Collector (every 10 minutes)
- Dashboard Health - Metrics Collector (every 15 minutes)
- Dashboard Registry - Auto Update (daily at 2 AM)

**Important:** These searches are disabled by default. Enable them only after completing Steps 1 and 2.

**Step 4: Wait for Data Collection**

Allow 15-30 minutes for initial metrics to populate. Verify:
```spl
| mstats count WHERE index=caca_metrics BY metric_name
```

### Configuration (Optional)

**Filter Apps for Monitoring**
Edit `lookups/app_filter.csv` to include/exclude specific apps:
```csv
app,include
production_app,true
splunk_monitoring_console,false
```

**Adjust Metrics Retention**
Edit `local/indexes.conf`:
```ini
[caca_metrics]
frozenTimePeriodInSecs = 31536000  # 1 year (default)
```

**Customize Collection Schedules**
Modify scheduled search frequencies in **Settings → Searches, reports, and alerts**.

---

## Troubleshooting

### No Data Appearing in Dashboards

**Symptom:** CACA dashboards show zero metrics or "No results found"

**Solutions:**

1. **Verify scheduled searches are running:**
   ```spl
   index=_internal source=*scheduler.log savedsearch_name="Dashboard*Metrics*"
   | stats count by savedsearch_name status
   ```
   - Ensure searches show `status=success`
   - If searches aren't running, verify they are enabled in **Settings → Searches, reports, and alerts**

2. **Check metrics index exists and has data:**
   ```spl
   | eventcount summarize=false index=caca_metrics
   | where count > 0
   ```
   - If count is 0, wait 15-30 minutes for initial collection
   - Verify dashboards have been accessed since CACA was installed

3. **Verify dashboard registry is populated:**
   ```spl
   | inputlookup dashboard_registry | stats count
   ```
   - If count is 0, re-run the registry population search from Step 2 of Initial Setup
   - Ensure you run the search **from within the CACA app** in Splunk Web

### Dashboard Not Appearing in Registry

**Symptom:** Specific dashboard is missing from the registry or metrics

**Solutions:**

1. **Re-run registry update manually:**
   - Navigate to the **CACA app** in Splunk Web (important!)
   - Run the registry population search from Installation Step 2
   - Verify the dashboard appears: `| inputlookup dashboard_registry | search pretty_name="Your Dashboard"`

2. **Check app filter configuration:**
   - Verify `lookups/app_filter.csv` isn't excluding the dashboard's app
   - If app is listed with `include=false`, change to `true` or remove the entry

3. **Private dashboard visibility:**
   - Private dashboards require admin privileges to discover via REST API
   - Ensure the registry update search runs with sufficient permissions
   - Alternatively, manually add to `lookups/dashboard_registry.csv`

### Metrics Showing Zero Despite Dashboard Usage

**Symptom:** Dashboard appears in registry but shows 0 views/edits/errors

**Solutions:**

1. **Check scheduled search permissions:**
   ```spl
   index=_internal source=*scheduler.log savedsearch_name="Dashboard Views - Metrics Collector"
   | table _time status message
   ```
   - Look for permission errors or failed executions
   - Ensure search runs with role that has access to `_internal` and `_audit` indexes

2. **Verify internal logs are accessible:**
   ```spl
   index=_internal sourcetype=splunkd_ui_access "/app/*" earliest=-1h
   | stats count
   ```
   - If count is 0, check that `_internal` index is available
   - Verify audit logging is enabled in Splunk

3. **Check for dashboard activity:**
   - Dashboards must be accessed **after** CACA is installed for metrics to appear
   - Open the dashboard manually to generate initial view event
   - Wait 5-15 minutes for collection searches to run

### Error in 'outputlookup': Could not find all of the specified destination fields

**Symptom:** Registry update search fails with outputlookup error

**Solution:**
- Ensure you are running the search **from within the CACA app context** in Splunk Web
- Navigate to **CACA app** first, then run the search
- Alternatively, use the `caca:` prefix: `| outputlookup caca:dashboard_registry.csv`

### High Scheduler Load or Performance Impact

**Symptom:** CACA searches impacting system performance

**Solutions:**

1. **Adjust collection frequency:**
   - Reduce scheduled search frequency in **Settings → Searches, reports, and alerts**
   - Example: Change view collection from 5 minutes to 15 minutes

2. **Filter monitored apps:**
   - Edit `lookups/app_filter.csv` to exclude non-critical apps
   - Focus monitoring on production apps only

3. **Reduce metrics retention:**
   - Edit `local/indexes.conf` and decrease `frozenTimePeriodInSecs`
   - Default is 1 year; consider 90 or 180 days for less storage

### Dashboard Health Status Incorrect

**Symptom:** Dashboard shows errors but appears healthy (or vice versa)

**Solutions:**

1. **Check error thresholds:**
   - Health status is based on 7-day error counts
   - Review dashboard detail view to see actual error counts
   - Recent errors may not impact 7-day average immediately

2. **Manually verify errors:**
   ```spl
   index=_internal source=*splunkd.log dashboard_id="*your_dashboard*" (ERROR OR WARN)
   | stats count by log_level
   ```

### Need Additional Help?

- Review the built-in **CACA Admin Dashboard** for dashboard management guidance
- Check `README.md` in the app directory for detailed documentation
- Visit the GitHub repository for issues and community support
- Contact Splunk support for platform-level issues

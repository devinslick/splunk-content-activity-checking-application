# CACA - Content Activity Checking Application

[![Validate App](https://github.com/devinslick/splunk-content-monitoring-console/actions/workflows/validate.yml/badge.svg)](https://github.com/devinslick/splunk-content-monitoring-console/actions/workflows/validate.yml)
[![Splunkbase](https://img.shields.io/badge/Splunkbase-Not%20Published-red)](https://splunkbase.splunk.com/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

> **Note:** The "Validate App" badge shows the current AppInspect status. Green = passing with 0 failures.

## Overview

**CACA (Content Activity Checking Application)** is a Splunk app designed to help teams track the caca in their environment: highlighting usage, health, and lifecycle of their Splunk dashboards and content. It provides clear, metric-driven insights to help answer critical questions:

- **"Is anyone using this dashboard I built?"** - Track views and user engagement
- **"Which dashboards are most critical to our users?"** - Identify high-value content
- **"Is this dashboard actually performing well?"** - Monitor health and errors
- **"Which dashboards are safe to archive or delete?"** - Find unused or stale content
- **"How do we demonstrate the value of our team's work?"** - Quantify dashboard impact with real metrics

### Why This App?

While the Splunk Monitoring Console (DMC) focuses on system-level health and performance, CACA fills a different need:

- **DMC is for Admins**: Tracks scheduler load, memory, and infrastructure health
- **CACA is for Creators & Users**: Answers "Is my content useful and working well?"

## Features

### Current Features

#### Dashboard Monitoring
- **Automated Discovery**: Automatically discovers and catalogs all dashboards across your Splunk environment
- **Usage Tracking**: Track how many times each dashboard is viewed, by which users, and when
- **Edit History**: Monitor when dashboards are created or modified, and by whom
- **Health Monitoring**: Detect and track dashboard errors and warnings from internal logs
- **Performance Monitoring**: Track dashboard load times and identify slow-performing dashboards
- **Stale Dashboard Detection**: Identify dashboards that haven't been accessed in 30+ days

#### Metrics & Analytics
- **Efficient Metrics Store**: Uses Splunk's native metrics index for high-performance, low-storage-impact data collection
- **Real-Time Collection**: Scheduled searches run every 5-15 minutes for near real-time metrics
- **Historical Trending**: Track usage patterns and trends over time (up to 1 year by default)
- **Aggregate Statistics**: View total views, edits, and errors across all content

#### Visualization & Reporting
- **Dashboard Leaderboard**: Centralized view showing all monitored dashboards with sortable metrics
- **Detailed Analytics**: Drill down into individual dashboards for comprehensive insights
- **Health Status Indicators**: Color-coded status badges (Healthy, Warning, Critical, Stale)
- **Top Performers**: Identify most-viewed and most-edited dashboards
- **User Activity Breakdown**: See which users are accessing specific dashboards

#### Embeddable Badges
- **GitHub-Style Badges**: Add usage and health metrics directly to your dashboards
- **Customizable Templates**: Pre-built XML snippets for quick badge integration
- **Multiple Badge Styles**: Choose from compact single-stat or detailed multi-metric badges
- **Self-Service**: Dashboard owners can add badges without admin intervention

#### Search Macros
- **Reusable Queries**: Pre-built macros for common metrics queries
- **Parameterized Searches**: Easily query specific dashboards or time ranges
- **Consistent Results**: Standardized queries across the app

### Architecture

The app uses a three-stage pipeline for efficiency:

1. **Collect**: Scheduled searches analyze Splunk's internal logs (`_internal`, `_audit`) to track views, edits, errors, and performance
2. **Store**: Metrics are written to a dedicated metrics index using `mcollect` for optimal performance
3. **Query**: Fast retrieval via `mstats` command and reusable search macros

**Note on Scheduled Searches**: CACA is powered by lightweight scheduled searches that run at the following intervals:
- Dashboard views: Every 5 minutes
- Dashboard edits: Every 10 minutes
- Dashboard performance: Every 10 minutes
- Dashboard health: Every 15 minutes
- Registry updates: Daily at 2 AM

All searches are configured with **low priority** to ensure they do not impact regular user searches or system performance. The searches use efficient `mcollect` commands to write directly to a metrics index, minimizing resource consumption.

## Status
DRAFT - Work in Progress

## Requirements

- Splunk Enterprise 8.0 or later
- Access to `_internal` and `_audit` indexes
- Permissions to create metrics indexes and scheduled searches

## Installation

### Method 1: Via Splunk Web (Recommended)

1. Download the latest release package (`.spl` or `.tar.gz`)
2. In Splunk Web, navigate to **Apps → Manage Apps**
3. Click **Install app from file**
4. Upload the package file
5. Click **Upload**
6. Restart Splunk if prompted

### Method 2: Manual Installation

1. Extract the app package to `$SPLUNK_HOME/etc/apps/`
2. Ensure the directory is named `splunk-content-monitoring-console`
3. Restart Splunk:
   ```bash
   $SPLUNK_HOME/bin/splunk restart
   ```

## Initial Setup

After installation, follow these steps to initialize CACA:

### 1. Verify Index Creation

The `caca_metrics` index should be created automatically. Verify by running:

```spl
| eventcount summarize=false index=caca_metrics
```

### 2. Populate Dashboard Registry

Run the registry update search to populate the dashboard registry. **Important:** Make sure to run this search from within the CACA app context, or use the full app path in the outputlookup command:

**Option A - Run from CACA app context:**
Navigate to **CACA app** in Splunk Web, then run:

```spl
| rest /services/data/ui/views splunk_server=local count=0 search="sharing=*"
| search isDashboard=1 OR isVisible=1
| eval dashboard_uri="/app/".eai:acl.app."/".title
| eval pretty_name=coalesce(label, title)
| eval app=eai:acl.app
| eval owner=eai:acl.owner
| eval sharing=eai:acl.sharing
| eval description=coalesce(eai:data, "")
| eval status="active"
| table dashboard_uri pretty_name app owner sharing description status
| outputlookup dashboard_registry.csv
```

**Option B - Run from any app:**

If you prefer to run the search from a different app (like Search & Reporting), you can do so, but you **must** include the full app path in the outputlookup command:

```spl
| rest /services/data/ui/views splunk_server=local count=0 search="sharing=*"
| search isDashboard=1 OR isVisible=1
| eval dashboard_uri="/app/".eai:acl.app."/".title
| eval pretty_name=coalesce(label, title)
| eval app=eai:acl.app
| eval owner=eai:acl.owner
| eval sharing=eai:acl.sharing
| eval description=coalesce(eai:data, "")
| eval status="active"
| table dashboard_uri pretty_name app owner sharing description status
| outputlookup caca:dashboard_registry.csv
```

**Note:** The `caca:` prefix ensures the lookup is saved to the correct app even when running from elsewhere.

**Recommended:** Just use Option A - it's simpler and less error-prone.

This will scan your Splunk environment and populate the `dashboard_registry.csv` lookup with all discovered dashboards, including private dashboards.

**Note on Private Dashboards:** The `search="sharing=*"` parameter ensures that dashboards with all sharing levels (global, app, and user/private) are included in the registry. To see private dashboards owned by other users, the scheduled search must run with appropriate permissions (typically as admin or with the `list_storage_passwords` capability).

**Verify the registry (run from CACA app):**

```spl
| inputlookup dashboard_registry | stats count
```

Or from any app, navigate to the lookup location:
```spl
Settings → Lookups → Lookup table files → Find "dashboard_registry.csv" in caca
```

### 3. Enable Scheduled Searches

Navigate to **Settings → Searches, reports, and alerts** and enable these searches:

- **Dashboard Views - Metrics Collector** (runs every 5 minutes)
- **Dashboard Edits - Metrics Collector** (runs every 10 minutes)
- **Dashboard Performance - Metrics Collector** (runs every 10 minutes)
- **Dashboard Health - Metrics Collector** (runs every 15 minutes)
- **Dashboard Registry - Auto Update** (runs daily at 2 AM)

**Important:** These searches are disabled by default to prevent errors before the registry is populated. Enable them only after completing steps 1 and 2 above.

### 4. Wait for Data Collection

Allow 15-30 minutes for the initial data collection to populate the metrics index.

**Verify metrics are being collected:**

```spl
| mstats count WHERE index=caca_metrics BY metric_name
```

## Usage

### Main Dashboard - Leaderboard

Navigate to **CACA → Dashboard Leaderboard** to view:

- **High-Level KPIs**: Total dashboards, views, errors, average load time, and stale dashboards
- **Activity Leaderboard Table**: Sortable list of all dashboards with usage, health, and performance metrics
- **Trending Charts**: Views, errors, and load time trends over time
- **Top Dashboards**: Most viewed, most edited, and slowest dashboards

### CACA Admin Dashboard

Navigate to **CACA → CACA Admin Dashboard** for centralized dashboard administration:

- **Multi-Dimensional Filtering**: Filter dashboards by name, app, owner, health status, and performance
- **Management View**: Sortable table with all key metrics (views, errors, load time, health)
- **Quick Actions**: Direct links to edit, change ownership, move between apps, delete, and manage permissions
- **Bulk Recommendations**: Prioritized list of dashboards needing attention (fix, optimize, archive)
- **Workflow Guides**: Step-by-step instructions for common administrative tasks

See the [CACA Admin Dashboard README](default/data/ui/views/CACA_ADMIN_README.md) for detailed usage instructions and examples.

### Dashboard Details

Click any dashboard in the leaderboard to view detailed metrics:

- Total views, edits, errors, and average load time
- Activity and performance trends over time
- Top users by views
- Edit history
- Error details with severity
- Load time analysis (average and maximum)

### Adding Badges to Your Dashboards

You can add usage badges to any dashboard. See the **Badge Template** (`default/data/ui/views/BADGE_TEMPLATE.md`) for instructions.

**Quick Example:**

Add this panel to your dashboard XML:

```xml
<row>
  <panel>
    <title>Dashboard Views (7d)</title>
    <single>
      <search>
        <query>| mstats sum(_value) as total WHERE index=caca_metrics AND pretty_name="YOUR_DASHBOARD_NAME" AND metric_name="dashboard.views" span=1d
| where _time >= relative_time(now(), "-7d")
| stats sum(total) as views</query>
        <earliest>-7d</earliest>
        <latest>now</latest>
      </search>
      <option name="underLabel">Views (7d)</option>
    </single>
  </panel>
</row>
```

Replace `YOUR_DASHBOARD_NAME` with your dashboard's pretty name from the registry.

### Using Search Macros

CACA provides several search macros for easy querying. These macros help you quickly identify dashboards with issues, analyze performance, and understand usage patterns.

**Note:** All macros respect the app filter configuration (see "Filtering Apps for Monitoring" in Configuration section). All results include the `app` field showing which app each dashboard belongs to, making it easy to filter or group results by application.

#### Finding Dashboards with Issues

##### Identify dashboards with health issues (errors/warnings):
```spl
`get_dashboards_with_errors`
```
**Returns:** Dashboards with errors or warnings in the last 7 days, sorted by severity
**Columns:** pretty_name, app, errors, warnings, total_issues, health_status
**Use case:** Find dashboards that are generating errors and need attention

##### Identify slow-performing dashboards:
```spl
`get_slow_dashboards`
```
**Returns:** Dashboards with average load time > 3 seconds in the last 7 days
**Columns:** pretty_name, app, avg_load_time_7d, performance_status
**Use case:** Find dashboards that need performance optimization

##### Identify all problematic dashboards (health OR performance issues):
```spl
`get_problematic_dashboards`
```
**Returns:** Dashboards with critical/warning health status OR slow performance
**Columns:** pretty_name, app, views_7d, errors_7d, avg_load_time_7d, health_status, issue_type
**Use case:** Get a comprehensive list of all dashboards needing attention

**Example - Filter for critical issues only:**
```spl
`get_problematic_dashboards`
| where health_status="critical" OR avg_load_time_7d > 10000
```

#### Dashboard Analytics

##### Get comprehensive stats for a specific dashboard:
```spl
`get_dashboard_stats("My Dashboard Name")`
```
**Returns:** All metrics (views, edits, errors, load time) for the specified dashboard
**Use case:** Deep dive into a specific dashboard's activity

##### Get all dashboards summary:
```spl
`get_all_dashboards_summary`
```
**Returns:** Summary of all dashboards with 7-day metrics
**Columns:** pretty_name, app, views_7d, edits_7d, errors_7d, avg_load_time_7d, health_status
**Use case:** Get an overview of all dashboard health and activity

##### Get top dashboards by metric type:
```spl
`get_top_dashboards(views)`
`get_top_dashboards(edits)`
```
**Returns:** Top 10 dashboards by views or edits in the last 7 days
**Use case:** Identify most-used or most-edited dashboards

#### Performance Analysis

##### Get performance rating for a specific dashboard:
```spl
`get_dashboard_performance("My Dashboard Name")`
```
**Returns:** Average load time and performance rating (Excellent/Good/Fair/Poor)
**Use case:** Check if a dashboard meets performance standards

##### Get last viewed time for a dashboard:
```spl
`get_dashboard_last_viewed("My Dashboard Name")`
```
**Returns:** Last viewed timestamp and days since last view
**Use case:** Identify stale or unused dashboards

#### Common Use Cases

**Find all dashboards needing immediate attention:**
```spl
`get_problematic_dashboards`
| where health_status="critical" OR (errors_7d > 50) OR (avg_load_time_7d > 10000)
```

**Filter results by specific app:**
```spl
`get_dashboards_with_errors`
| where app="search"
| table pretty_name app errors warnings health_status
```

**List dashboards with errors across multiple apps:**
```spl
`get_dashboards_with_errors`
| where app IN ("my_app1", "my_app2", "production_app")
| sort -errors
```

**List dashboards with errors that are actively used:**
```spl
`get_dashboards_with_errors`
| where errors > 0
| join type=inner pretty_name [| mstats sum(_value) as views WHERE index=caca_metrics AND metric_name="dashboard.views" BY pretty_name span=1d | where _time >= relative_time(now(), "-7d") | stats sum(views) as views_7d by pretty_name | where views_7d > 10]
| table pretty_name app errors warnings views_7d health_status
```

**Find slow dashboards with high usage:**
```spl
`get_slow_dashboards`
| join type=inner pretty_name [| mstats sum(_value) as views WHERE index=caca_metrics AND metric_name="dashboard.views" BY pretty_name span=1d | where _time >= relative_time(now(), "-7d") | stats sum(views) as views_7d by pretty_name]
| where views_7d > 50
| table pretty_name app avg_load_time_7d performance_status views_7d
| sort -views_7d
```

**Dashboard health report for a specific app:**
```spl
`get_all_dashboards_summary`
| where app="search"
| table pretty_name views_7d edits_7d errors_7d avg_load_time_7d health_status
| sort -errors_7d
```

## Configuration

### Adjusting Collection Schedules

Edit `default/savedsearches.conf` or use Splunk Web to modify:

- **View tracking frequency**: Default every 5 minutes
- **Edit tracking frequency**: Default every 10 minutes
- **Performance tracking frequency**: Default every 10 minutes
- **Health tracking frequency**: Default every 15 minutes
- **Registry update frequency**: Default daily at 2 AM

### Customizing Metrics Retention

Edit `default/indexes.conf` to adjust retention:

```ini
[caca_metrics]
frozenTimePeriodInSecs = 31536000  # 1 year (default)
```

### Filtering Apps for Monitoring

CACA can be configured to only monitor dashboards from specific apps, or exclude certain apps from monitoring. This is useful when you only want to track dashboards in production apps, or exclude system/admin apps.

#### Configuration Method

Edit `lookups/app_filter.csv` to control which apps are monitored:

**Include specific apps only:**
```csv
app,include
search,true
my_production_app,true
another_app,true
```

**Exclude specific apps:**
```csv
app,include
splunk_monitoring_console,false
learned,false
introspection_generator_addon,false
```

**How it works:**
- If an app is **not listed** in app_filter.csv, it **will be monitored** (default behavior)
- If an app is listed with `include=true` (or `1` or `yes`), it **will be monitored**
- If an app is listed with `include=false` (or `0` or `no`), it **will NOT be monitored**
- The filter applies to:
  - Dashboard registry updates (which dashboards are discovered)
  - All metrics collection (views, edits, errors, performance)
  - All search macros and dashboard queries

#### Examples

**Monitor only specific production apps:**
```csv
app,include
production_app1,true
production_app2,true
production_app3,true
```
Then add a wildcard exclusion entry to exclude everything else (optional):
```csv
app,include
production_app1,true
production_app2,true
*,false
```

**Exclude system and admin apps:**
```csv
app,include
splunk_monitoring_console,false
learned,false
introspection_generator_addon,false
splunk_instrumentation,false
```

**Note:** After updating `app_filter.csv`, run the "Dashboard Registry - Auto Update" search to rebuild the dashboard registry with the new filter applied.

### Excluding Individual Dashboards from Monitoring

Edit `lookups/dashboard_registry.csv` and set `status=inactive` for specific dashboards you want to exclude from collection (this is independent of app filtering).

## Troubleshooting

### No Data Appearing

1. **Check scheduled searches are running:**
   ```spl
   index=_internal source=*scheduler.log savedsearch_name="Dashboard*Metrics*"
   ```

2. **Verify metrics index exists:**
   ```spl
   | eventcount summarize=false index=caca_metrics
   ```

3. **Check lookup is populated:**
   ```spl
   | inputlookup dashboard_registry
   ```

### Dashboard Not Appearing in Registry

Run the registry update search manually from the CACA app context:

**Step 1:** Navigate to the CACA app in Splunk Web

**Step 2:** Run this search:
```spl
| rest /services/data/ui/views splunk_server=local count=0 search="sharing=*"
| search isDashboard=1 OR isVisible=1
| eval dashboard_uri="/app/".eai:acl.app."/".title
| eval pretty_name=coalesce(label, title)
| eval app=eai:acl.app
| eval owner=eai:acl.owner
| eval sharing=eai:acl.sharing
| eval status="active"
| table dashboard_uri pretty_name app owner sharing status
| outputlookup caca:dashboard_registry.csv
```

**For Private Dashboards:** If private dashboards still don't appear, ensure the search is running with appropriate permissions. Private dashboards owned by other users require admin privileges or specific capabilities to be discovered via REST API.

Or add it manually to `lookups/dashboard_registry.csv` in the CACA app directory.

### Metrics Showing Zero

- Ensure dashboards have been accessed since CACA was installed
- Check that scheduled searches have appropriate permissions
- Verify `_internal` and `_audit` indexes are accessible

## Performance Considerations

- The app uses metrics indexes which are highly efficient
- Scheduled searches are lightweight and use `mcollect` for optimal performance
- Default retention is 1 year; adjust based on your needs
- Registry auto-updates daily; increase frequency if dashboards change often

## Support

Feel free to open a github issue or contribute with a pull request!

## Roadmap

### Planned Features

#### Saved Search & Alert Monitoring
- **Scheduled Search Tracking**: Monitor execution frequency, run time, and success rates for all saved searches
- **Alert Effectiveness Metrics**: Track alert trigger frequency, action execution, and alert fatigue indicators
- **Report Usage Analytics**: Identify which scheduled reports are being used vs. those running unnecessarily
- **Performance Metrics**: Track search execution times, result counts, and resource consumption
- **Owner Assignment**: Link saved searches to owners for accountability
- **Stale Search Detection**: Identify searches that never trigger alerts or whose results are never viewed
- **Cost Analysis**: Calculate scheduler load and resource cost per saved search

#### Additional Knowledge Object Support
- **Lookup Table Monitoring**: Track lookup file usage, size, and update frequency
- **Data Model Tracking**: Monitor data model acceleration, search usage, and performance
- **Field Extraction Usage**: Identify which field extractions are actually being used in searches
- **Macro Utilization**: Track which search macros are referenced and where
- **Tag & Event Type Usage**: Identify unused tags and event types for cleanup

#### Enhanced Analytics & Insights
- **Predictive Analytics**: Forecast future dashboard usage trends
- **Anomaly Detection**: Alert on unusual patterns (sudden usage drops, error spikes)
- **Dependency Mapping**: Visualize relationships between dashboards, searches, and data sources
- **Content Lifecycle Management**: Automated workflows for deprecating unused content
- **ROI Metrics**: Calculate value/cost ratios for content creation efforts

#### User Experience Improvements
- **Setup Wizard**: Guided initial configuration and onboarding
- **Custom Badge Visualization**: Develop native custom visualization for badges (no XML editing required)
- **Email Digests**: Scheduled reports showing content health summaries
- **Integration with ITSI**: Surface content metrics in ITSI service monitoring
- **REST API Endpoints**: Programmatic access to content metrics for external tools
- **Mobile-Friendly Views**: Responsive dashboards for mobile devices

#### Advanced Features
- **Multi-Tenant Support**: Track content usage across multiple business units or teams
- **Compliance Reporting**: Demonstrate content governance and audit trails
- **A/B Testing Support**: Compare usage metrics before/after dashboard changes
- **Content Recommendations**: Suggest related or popular dashboards to users
- **Auto-Archival**: Automatically disable or archive stale content with admin approval

### Community Contributions Welcome!

We welcome contributions for any of these roadmap items or new feature ideas. Please:
1. Open an issue to discuss the feature before starting work
2. Follow the existing code patterns and architecture
3. Include documentation and examples
4. Add test data or validation steps

## Release Notes

### Version 0.0.1
- Initial draft

## License

MIT License

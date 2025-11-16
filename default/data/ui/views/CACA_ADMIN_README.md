# CACA Admin Dashboard

## Overview

The **CACA Admin Dashboard** is a comprehensive administrative control panel designed to streamline dashboard management tasks in Splunk. It consolidates filtering, analysis, and administrative actions into a single, unified interface.

## Purpose

Administrative tasks in the Splunk UI can be cumbersome, requiring navigation between multiple views to:
- Edit dashboards
- Change ownership
- Move objects between apps
- Delete dashboards
- Change permissions

The CACA Admin Dashboard solves this by providing:
1. **Multi-dimensional filtering** to quickly find the dashboards you need to manage
2. **Comprehensive dashboard listing** with health and performance metrics from CACA
3. **Quick access** to all common administrative functions
4. **Actionable recommendations** based on dashboard health and usage data

## Key Features

### 1. Advanced Filtering

Filter dashboards by multiple criteria simultaneously:

- **Dashboard Name**: Wildcard search (e.g., "sales*" or "*report*")
- **App**: Select one or more apps
- **Owner**: Select one or more owners
- **Sharing Level**: Global, App, or Private
- **Health Status**: Healthy, Warning, Critical, or Stale
- **Performance**: Fast (<1s), Good (1-3s), Slow (3-5s), or Very Slow (>5s)
- **Load Time Analysis Period**: Select time range (24h, 7d, 30d, 90d) for analyzing average total dashboard load time
- **Metrics Time Range**: Configurable metrics window for views, edits, and errors (default: 7 days)

**Use Cases:**
- Find all stale dashboards in the "search" app
- Identify all dashboards owned by a departing team member
- List all dashboards with critical health issues
- Find slow-performing dashboards with high usage
- Analyze load time trends over different time periods

### 2. Dashboard Management Table

The main table displays all dashboards matching your filters with:

- **Dashboard Name** (clickable to open)
- **App** - Which app contains the dashboard
- **Owner** - Current owner
- **Sharing** - Sharing level (🌐 Global, 📦 App, 🔒 Private)
- **Views (7d)** - Number of views in the selected time range
- **Edits (7d)** - Number of edits
- **Errors (7d)** - Error count
- **Avg Load (ms)** - Average load time (from last 7 days)
- **Avg Total Load Time (ms)** - Average total load time for the selected Load Time Analysis Period
- **Performance** - Visual performance rating (⚡ Fast, ✓ Good, ⚠ Slow, ✗ Very Slow)
- **Health** - Visual health status (✓ Healthy, ⚠ Warning, ✗ Critical, ☾ Stale)

**Note:** The "Avg Total Load Time (ms)" column dynamically updates based on the "Load Time Analysis Period" dropdown selection (24h, 7d, 30d, or 90d), allowing you to analyze performance trends over different time ranges.

**Interactions:**
- Click any dashboard name to open it directly
- Click any other cell to view detailed analytics
- Sort by any column
- Paginated display (50 per page)

### 3. Quick Access Buttons

Direct links to common administrative pages:
- **Manage All Dashboards** - Access Splunk's dashboard management interface
- **Create New Dashboard** - Start creating a new dashboard
- **Settings** - System settings and configuration
- **Search** - Open the search interface

### 4. Administrative Workflows Guide

Built-in documentation for common tasks:

#### Change Dashboard Ownership
1. Click "Manage All Dashboards"
2. Find the dashboard
3. Click "Edit" → "Edit Permissions"
4. Change the "Owner" field
5. Save

#### Move Dashboard Between Apps
1. Click "Manage All Dashboards"
2. Find the dashboard
3. Click "Move" in the Actions column
4. Select destination app
5. Move

#### Delete Dashboards (Bulk)
1. Use filters to narrow down candidates (e.g., stale dashboards)
2. Review the filtered list
3. Click "Manage All Dashboards"
4. Select and delete dashboards

#### Change Permissions
1. Click dashboard name to open it
2. Click "Edit" → "Edit Permissions"
3. Modify read/write permissions
4. Set sharing scope (app or global)
5. Save

### 5. Bulk Action Recommendations

Automated analysis that identifies dashboards requiring attention:

- **Priority Levels**: URGENT, HIGH, MEDIUM, CONSIDER
- **Action Types**:
  - Fix/Debug - Critical or warning health issues
  - Optimize - Performance improvements needed
  - Archive/Delete - Stale or unused dashboards
  - Review - General attention needed

**Recommendations:**
- "URGENT: Fix errors AND optimize performance" - Dashboard with critical health AND slow performance
- "HIGH: Fix critical errors" - Dashboard with critical health issues
- "HIGH: Optimize performance (very slow)" - Dashboard taking >10 seconds to load
- "MEDIUM: Review and fix warnings" - Dashboard with warnings
- "MEDIUM: Optimize performance" - Dashboard taking >5 seconds to load
- "CONSIDER: Archive or delete if not needed" - Stale dashboard with zero views

## Usage Examples

### Example 1: Clean Up Stale Dashboards
1. Set **Health Status** filter to "☾ Stale"
2. Review the list of dashboards not viewed in 30+ days
3. Check the "Bulk Action Recommendations" panel for specific guidance
4. Use "Manage All Dashboards" to delete or archive them

### Example 2: Transfer Ownership for Departing Team Member
1. Set **Owner** filter to the departing user's username
2. Review all their dashboards
3. Note the apps and usage patterns
4. Follow the "Change Dashboard Ownership" workflow for each dashboard

### Example 3: Identify and Fix Performance Issues
1. Set **Performance** filter to "✗ Very Slow"
2. Review dashboards with >5 second load times
3. Check "Views (7d)" to prioritize high-traffic dashboards
4. Click dashboard name to open and investigate/optimize

### Example 4: Analyze Load Time Trends
1. Select **Load Time Analysis Period** to "Last 24 Hours" for recent performance
2. Review the **Avg Total Load Time (ms)** column to see current performance
3. Change period to "Last 30 Days" to compare with longer-term trends
4. Identify dashboards with increasing load times for proactive optimization

### Example 5: Find All Broken Dashboards in Production App
1. Set **App** filter to your production app name
2. Set **Health Status** filter to "✗ Critical"
3. Review error counts and view the recommendations
4. Click each dashboard to view error details and fix

### Example 6: Audit Dashboard Permissions
1. Set **App** filter to specific app(s)
2. Review the owner column
3. Click each dashboard name to check permissions
4. Follow the "Change Permissions" workflow to adjust as needed

## Integration with Other CACA Views

The CACA Admin Dashboard integrates seamlessly with other CACA dashboards:

- **Dashboard Leaderboard** - High-level overview of all dashboards
- **Poop Deck** - Deep-dive analytics for gems, crap, broken, and slow dashboards
- **Dashboard Details** - Detailed metrics and history for individual dashboards

Navigate between these views using the navigation menu or the links at the bottom of each dashboard.

## Best Practices

1. **Regular Audits**: Use the admin dashboard weekly or monthly to identify stale content
2. **Performance Monitoring**: Set up a routine to check for slow dashboards and optimize them
3. **Health Checks**: Regularly review dashboards with critical or warning status
4. **Ownership Management**: Ensure all dashboards have active owners
5. **Bulk Operations**: Use filters to batch similar administrative tasks
6. **Documentation**: Update dashboard descriptions to help identify purpose during cleanup

## Access Requirements

To use the CACA Admin Dashboard effectively, you need:

- Read access to the CACA metrics index (`caca_metrics`)
- Read access to the dashboard registry lookup
- Appropriate Splunk role permissions to:
  - View dashboards across apps
  - Edit dashboards (for modifications)
  - Manage dashboards (for delete/move operations)
  - Change permissions (for ownership and permission changes)

## Troubleshooting

### No Dashboards Appearing
- Verify the dashboard registry is populated: `| inputlookup dashboard_registry`
- Check that metrics are being collected: `| mstats count WHERE index=caca_metrics`
- Ensure filters aren't too restrictive (try resetting to defaults)
- **For private dashboards**: Ensure the "Dashboard Registry - Auto Update" scheduled search runs with appropriate permissions to discover private dashboards owned by other users

### Filters Not Working
- Click the "Submit" button after changing filters
- Check for typos in the name filter (use wildcards: *)
- Verify app/owner names match exactly what's in the registry

### Private Dashboards Not Appearing
- Private dashboards require the registry update search to run with admin privileges
- Verify the search includes `search="sharing=*"` parameter in the REST call
- Check if the user running the scheduled search has permissions to view other users' private content
- Manually verify private dashboard exists: `| rest /services/data/ui/views search="sharing=*" | search owner="username" sharing="user"`

### Links Not Working
- Ensure you have appropriate permissions to access management pages
- Some links require admin or power user roles
- Check that you're logged into Splunk with sufficient privileges

## Technical Details

**File Location**: `default/data/ui/views/caca_admin.xml`

**Dependencies**:
- `dashboard_registry.csv` lookup
- `caca_metrics` index
- Search macro: `get_all_dashboards_summary`

**Private Dashboard Support**:
- The dashboard registry includes dashboards with all sharing levels: global, app, and user/private
- The registry update search uses `search="sharing=*"` parameter to discover private dashboards
- Viewing private dashboards owned by other users requires appropriate permissions
- The scheduled search should run with admin privileges to capture all private dashboards across users
- The `sharing` field in the registry indicates the sharing level of each dashboard

**Performance Considerations**:
- Initial load may take a few seconds if you have many dashboards
- Filters are applied on submit to improve performance
- Time range affects query performance (shorter = faster)

## Future Enhancements

Potential future improvements:
- Bulk permission changes
- Scheduled cleanup workflows
- Dashboard cloning functionality
- Export filtered list to CSV
- Custom action templates
- Integration with change management systems

## Support

For issues or feature requests, please open a GitHub issue in the CACA repository.

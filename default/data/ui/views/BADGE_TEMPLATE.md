# CACA Dashboard Badge Template

This template provides a reusable badge panel that can be embedded into any dashboard to display its usage and health metrics.

## Usage Instructions

1. Copy the XML snippet below
2. Paste it into your dashboard's XML
3. Replace `YOUR_DASHBOARD_NAME` with the actual dashboard name (pretty_name from the registry)
4. Optionally adjust colors and thresholds

## Badge Panel XML

```xml
<row>
  <panel>
    <title>📊 Dashboard Health Badge</title>
    <table>
      <search>
        <query>| mstats sum(_value) as metric_value WHERE index=caca_metrics AND pretty_name="YOUR_DASHBOARD_NAME" BY metric_name span=1d
| where _time >= relative_time(now(), "-7d")
| stats sum(metric_value) as total by metric_name
| eval metric_display=case(
    metric_name=="dashboard.views", "Views (7d)",
    metric_name=="dashboard.edits", "Edits (7d)",
    metric_name=="dashboard.errors", "Errors (7d)",
    1=1, metric_name)
| eval status=case(
    metric_name=="dashboard.errors" AND total > 10, "CRITICAL",
    metric_name=="dashboard.errors" AND total > 0, "WARNING",
    metric_name=="dashboard.views" AND total == 0, "STALE",
    1=1, "HEALTHY")
| table metric_display total status
| rename metric_display as "Metric", total as "Count", status as "Status"</query>
        <earliest>-7d@h</earliest>
        <latest>now</latest>
      </search>
      <option name="drilldown">none</option>
      <option name="count">10</option>
      <format type="color" field="Status">
        <colorPalette type="map">{"HEALTHY":#53A051,"WARNING":#F8BE34,"CRITICAL":#DC4E41,"STALE":#708794}</colorPalette>
      </format>
      <format type="number" field="Count">
        <option name="precision">0</option>
      </format>
    </table>
  </panel>
</row>
```

## Compact Single Stat Badge

For a more compact badge, use this single stat version:

```xml
<row>
  <panel>
    <title>Views (7d)</title>
    <single>
      <search>
        <query>| mstats sum(_value) as total WHERE index=caca_metrics AND pretty_name="YOUR_DASHBOARD_NAME" AND metric_name="dashboard.views" span=1d
| where _time >= relative_time(now(), "-7d")
| stats sum(total) as views_7d</query>
        <earliest>-7d@h</earliest>
        <latest>now</latest>
      </search>
      <option name="drilldown">none</option>
      <option name="numberPrecision">0</option>
      <option name="underLabel">Dashboard Views</option>
    </single>
  </panel>

  <panel>
    <title>Health Status</title>
    <single>
      <search>
        <query>| mstats sum(_value) as errors WHERE index=caca_metrics AND pretty_name="YOUR_DASHBOARD_NAME" AND metric_name="dashboard.errors" span=1d
| where _time >= relative_time(now(), "-7d")
| stats sum(errors) as error_count
| eval status=case(error_count > 10, "CRITICAL", error_count > 0, "WARNING", 1=1, "HEALTHY")
| eval status_icon=case(status=="HEALTHY", "✓", status=="WARNING", "⚠", status=="CRITICAL", "✗", 1=1, "?")
| eval display=status_icon." ".status
| table display</query>
        <earliest>-7d@h</earliest>
        <latest>now</latest>
      </search>
      <option name="drilldown">none</option>
      <option name="colorMode">block</option>
      <option name="rangeColors">["0x53a051","0xf8be34","0xdc4e41"]</option>
      <option name="rangeValues">[1,2]</option>
      <option name="underLabel">Health</option>
    </single>
  </panel>
</row>
```

## Customization Options

### Adjusting Time Range
Change `-7d@h` to your preferred time range:
- `-24h` for last 24 hours
- `-30d@d` for last 30 days
- `-90d@d` for last 90 days

### Adjusting Error Thresholds
Modify the case statement thresholds:
```spl
error_count > 10, "CRITICAL"   # Change 10 to your threshold
error_count > 0, "WARNING"     # Change 0 to your threshold
```

### Color Schemes
Modify `rangeColors` to match your theme:
- Green healthy: `#53a051`
- Yellow warning: `#f8be34`
- Red critical: `#dc4e41`
- Gray stale: `#708794`

## Example: Full Dashboard with Badge

```xml
<dashboard>
  <label>My Dashboard with CACA Badge</label>

  <!-- CACA Badge at the top -->
  <row>
    <panel>
      <title>📊 Dashboard Metrics</title>
      <single>
        <search>
          <query>| mstats sum(_value) as total WHERE index=caca_metrics AND pretty_name="My Dashboard" AND metric_name="dashboard.views" span=1d
| where _time >= relative_time(now(), "-7d")
| stats sum(total) as views</query>
          <earliest>-7d</earliest>
          <latest>now</latest>
        </search>
        <option name="underLabel">Views (7d)</option>
      </single>
    </panel>
  </row>

  <!-- Your regular dashboard content below -->
  <row>
    <panel>
      <title>My Regular Panel</title>
      <table>
        <search>
          <query>index=main | stats count</query>
        </search>
      </table>
    </panel>
  </row>
</dashboard>
```

## Getting Your Dashboard Name

To find your dashboard's `pretty_name`, run this search:

```spl
| inputlookup dashboard_registry
| search dashboard_uri="*YOUR_DASHBOARD*"
| table dashboard_uri pretty_name app
```

Or check the Dashboard Leaderboard in CACA app.

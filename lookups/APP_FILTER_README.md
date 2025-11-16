# App Filter Configuration

This file controls which Splunk apps are monitored by CACA (Content Activity Checking Application).

## How It Works

- If an app is **not listed** in this file, it **WILL be monitored** (default behavior)
- If an app is listed with `include=true` (or `1` or `yes`), it **WILL be monitored**
- If an app is listed with `include=false` (or `0` or `no`), it **WILL NOT be monitored**

## Examples

### Include Only Specific Apps

To monitor ONLY certain apps, list them with include=true:

```csv
app,include
search,true
my_production_app,true
another_app,true
```

### Exclude Specific Apps

To exclude certain apps from monitoring (monitor everything else):

```csv
app,include
splunk_monitoring_console,false
learned,false
introspection_generator_addon,false
splunk_instrumentation,false
```

### Mixed Configuration

You can combine inclusions and exclusions:

```csv
app,include
production_app1,true
production_app2,true
test_app,false
dev_app,false
```

## After Changing This File

After updating app_filter.csv:

1. **Rebuild the dashboard registry** by running the "Dashboard Registry - Auto Update" search manually, or wait for it to run at 2 AM
2. The filter will automatically apply to all new metrics collection
3. Existing metrics for excluded apps will remain in the index but won't be updated

## Default Behavior

By default (empty file), ALL apps are monitored. Add entries to this file only if you want to:
- Monitor only specific apps (whitelist approach)
- Exclude specific apps (blacklist approach)

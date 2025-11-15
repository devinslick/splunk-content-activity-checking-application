# Release Notes - CACA v0.0.1

**Release Date:** November 15, 2025  
**App Name:** CACA - Content Activity Checking Application  
**Version:** 0.0.1 (Initial Beta Release)  
**License:** MIT

---

## 🎉 Initial Release

This is the first beta release of CACA (Content Activity Checking Application) - a Splunk app designed to track the usage, health, and lifecycle of your Splunk dashboards and content.

---

## ✨ Features

### Dashboard Monitoring
- **Automated Discovery** - Automatically discovers and catalogs all dashboards across your Splunk environment
- **Usage Tracking** - Tracks dashboard views by user and time
- **Edit History** - Monitors when dashboards are created or modified
- **Health Monitoring** - Detects and tracks dashboard errors and warnings
- **Stale Detection** - Identifies dashboards not accessed in 30+ days

### Metrics & Analytics
- **Efficient Storage** - Uses Splunk's native metrics index for high-performance, low-storage-impact
- **Real-Time Collection** - Scheduled searches run every 5-15 minutes
- **Historical Trending** - Track patterns over time (up to 1 year retention by default)
- **Aggregate Statistics** - View total views, edits, and errors across all content

### Dashboards
- **Dashboard Leaderboard** - Centralized view of all monitored dashboards with sortable metrics
- **The Poop Deck** 💩 - Deep analytics dashboard with categories:
  - 💎 The Gems - Most valuable dashboards
  - 💩 The Crap - Stale dashboards ready for cleanup
  - 🔧 The Broken - Dashboards with health issues
  - 😴 The Neglected - Low engagement dashboards
  - 💠 The Work in Progress - Most edited dashboards
- **Dashboard Details** - Drill-down view for individual dashboard analytics
- **Embeddable Badges** - GitHub-style badges to add to your dashboards

### Technical Highlights
- **Pure SPL Implementation** - No custom Python scripts required
- **Splunk Cloud Compatible** - Works in all Splunk deployment types
- **Low Priority Searches** - Won't impact user searches or system performance
- **Search Macros** - Reusable queries for consistent results
- **Automatic Registry Updates** - Daily discovery of new dashboards

---

## 📋 Requirements

- Splunk Enterprise 8.0 or later
- Access to `_internal` and `_audit` indexes
- Permissions to create metrics indexes and scheduled searches

---

## 🚀 Installation

### Quick Start

1. Download the app package
2. Install via Splunk Web: **Apps → Manage Apps → Install app from file**
3. Restart Splunk if prompted
4. Run the registry population search (see Initial Setup below)
5. Enable the scheduled searches
6. Wait 15-30 minutes for data collection to begin

### Initial Setup

After installation:

1. **Verify Index Creation**
   ```spl
   | eventcount summarize=false index=caca_metrics
   ```

2. **Populate Dashboard Registry**
   ```spl
   | rest /services/data/ui/views splunk_server=local count=0 
   | search isDashboard=1 OR isVisible=1 
   | eval dashboard_uri="/app/".eai:acl.app."/".title 
   | eval pretty_name=coalesce(label, title) 
   | eval app=eai:acl.app 
   | eval owner=eai:acl.owner 
   | eval description=coalesce(eai:data, "") 
   | eval status="active" 
   | table dashboard_uri pretty_name app owner description status 
   | outputlookup dashboard_registry.csv
   ```

3. **Enable Scheduled Searches**
   - Navigate to **Settings → Searches, reports, and alerts**
   - Enable all four CACA searches:
     - Dashboard Views - Metrics Collector
     - Dashboard Edits - Metrics Collector
     - Dashboard Health - Metrics Collector
     - Dashboard Registry - Auto Update

---

## 📊 What Gets Collected

### Dashboard Views
- **Source:** `index=_internal sourcetype=splunkd_access`
- **Frequency:** Every 5 minutes
- **Data:** Dashboard URI, user, timestamp

### Dashboard Edits
- **Source:** `index=_audit`
- **Frequency:** Every 10 minutes
- **Data:** Dashboard name, user, action (create/edit), timestamp

### Dashboard Health
- **Source:** `index=_internal` (errors and warnings)
- **Frequency:** Every 15 minutes
- **Data:** Dashboard name, severity, error details, timestamp

### Dashboard Registry
- **Source:** REST API
- **Frequency:** Daily at 2 AM
- **Data:** Dashboard metadata (name, app, owner, description)

---

## 🔧 Configuration

### Default Settings
- **Metrics Index:** `caca_metrics`
- **Retention:** 1 year (365 days)
- **Search Priority:** Low (won't impact user searches)

### Customization
- Adjust collection schedules in `savedsearches.conf`
- Modify retention in `indexes.conf`
- Exclude dashboards by setting `status=inactive` in the registry

---

## 📝 Known Limitations

1. **Historical Data** - Can only track dashboards from installation forward (no historical data before CACA was installed)
2. **Stale Detection Accuracy** - Requires at least 90 days of data collection for accurate 90-day stale detection
3. **Local Server Only** - Registry discovery runs on local server only (not distributed search)
4. **Dashboard URIs** - Some special characters in dashboard names may not be captured correctly

---

## 🐛 Known Issues

None reported in this initial release.

---

## 🔮 Roadmap

See [README.md](README.md) for full roadmap, including:
- Saved search & alert monitoring
- Additional knowledge object support (lookups, data models, macros)
- Predictive analytics and anomaly detection
- Enhanced user experience features
- REST API endpoints

---

## 📖 Documentation

- Full documentation: [README.md](README.md)
- Badge templates: `default/data/ui/views/BADGE_TEMPLATE.md`
- Project plan: `devnotes/PROJECT-PLAN.md`

---

## 🤝 Contributing

Contributions welcome! Please:
1. Open an issue to discuss the feature/fix
2. Follow existing code patterns
3. Include documentation
4. Add validation steps

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Inspired by the need for better content lifecycle management in Splunk
- Built with pure SPL for maximum compatibility
- Community-driven project

---

## 📧 Support

- **GitHub Issues:** https://github.com/devinslick/splunk-content-monitoring-console/issues
- **Author:** Devin Slick

---

## 🔄 Upgrade Notes

This is the initial release. Future upgrades will include:
- Automated migration scripts
- Backward compatibility notes
- Configuration preservation guidance

---

**Thank you for trying CACA! Happy monitoring! 💩📊**

# Uptime Kuma -- Package Center Screenshots

Screenshots are displayed in Package Center when users browse the package listing.
Each screenshot should be 940x600 pixels (or similar 16:10 aspect ratio), in PNG format.

## Recommended Screenshots

### 1. dashboard.png -- Main Dashboard
The primary monitoring dashboard showing:
- Monitor list with status indicators (up/down/pending)
- Response time sparkline graphs
- Uptime percentage badges
- Group/tag organization

### 2. monitor-config.png -- Monitor Configuration
The "Add New Monitor" dialog showing:
- Monitor type dropdown (HTTP, TCP, Ping, DNS, etc.)
- URL/hostname field
- Heartbeat interval and retry settings
- Notification selection

### 3. status-page.png -- Public Status Page
A public-facing status page showing:
- Custom branding and title
- Service group categories
- Current status of each monitor
- Uptime history bars

### 4. notifications.png -- Notification Setup
The notification configuration panel showing:
- List of available providers (Telegram, Discord, Slack, Email, etc.)
- Configuration form for a provider
- Test notification button

### 5. settings.png -- Settings Panel
The application settings showing:
- General settings (theme, timezone)
- Security settings (2FA toggle)
- Backup/restore options
- About/version information

## How to Capture

1. Install Uptime Kuma and configure several example monitors
2. Wait for monitors to collect data (response times, uptime)
3. Capture each screen at the recommended resolution
4. Save as PNG with descriptive filenames
5. Place files in this directory

## Notes

- Use a clean browser window (no bookmarks bar, minimal chrome)
- Use light theme for better visibility in Package Center
- Avoid including sensitive data (real URLs, IP addresses)
- Consider using example.com and placeholder hostnames

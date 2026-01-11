# Release Notes - Network Reporter Version 1.0

**Release Date:** January 4, 2026

## ✨ New Features ✨

This is the initial major release of Network Reporter, introducing a powerful suite of tools to help you understand your internet connection.

*   **Real-Time Network Monitoring:** At a glance, see the current health of your network connection right from your desktop. The main view displays your live status, latency, packet loss, and upload/download speeds.

*   **Historical Performance Analysis:** A brand new "History" section allows you to visualize your network performance over time.
    *   **Interactive Charts:** Explore your latency, packet loss, connectivity, and speed metrics on beautiful, easy-to-read charts.
    *   **Time Range Selection:** Filter your historical data by the Last Hour, Last 24 Hours, Last 7 Days, or Last 30 Days.
    *   **Degradation Highlighting:** Periods of high latency (> 200ms) or high packet loss (> 5%) are automatically highlighted, so you can spot problems in the past instantly.

## 🚀 Improvements

*   The network monitoring service now uses real `ping` data to provide accurate latency and packet loss metrics.
*   The UI has been updated to provide more detailed real-time information.
*   Added a navigation structure to access different parts of the application.

## 🐞 Bug Fixes

*   Initial release, so we're starting fresh!

## Known Issues

*   Upload/Download speed monitoring is not yet implemented. The application requires the `speedtest-cli` command-line tool to be installed to measure this. If it is not present, speeds will be reported as 0.0 Mbps.

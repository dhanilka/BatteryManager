# Battery Manager for macOS

A modern, minimalist battery monitoring application for MacBooks with a beautiful black & white UI.

## Features

### 📊 Battery Information Dashboard
- Real-time battery percentage with circular progress indicator
- Battery health status and percentage
- Cycle count tracking
- Voltage, amperage, and wattage monitoring
- Temperature monitoring (when available)
- Current, maximum, and design capacity
- Charging status and power source
- Time remaining estimate
- Battery condition status

### 🎨 Modern UI Design
- Sleek black & white minimalist design
- Smooth animations and transitions
- Apple-like aesthetic with rounded corners
- Clean typography using SF Symbols
- Glass-morphic effects
- Card-based layout for easy reading

### 📈 Visualizations
- Health progress bar with color coding
- Cycle count indicator
- Real-time power consumption graph
- Capacity comparison charts

### 🔔 Smart Alerts
- Customizable high battery alert (default: 80%)
- Customizable low battery alert (default: 20%)
- Native macOS notifications
- Toggle alerts on/off in settings

### 📟 Menu Bar Integration
- Live battery percentage in menu bar
- Dynamic battery icon showing charge level
- Quick stats dropdown menu
- One-click access to full dashboard

### ⚡ Live Updates
- Automatic updates every 3 seconds
- Minimal CPU usage (< 1% idle)
- Efficient IOKit battery monitoring
- Real-time charging state detection

## Requirements

- macOS 13.0 (Ventura) or later
- MacBook with battery (not compatible with iMac/Mac Mini/Mac Pro)
- Xcode 14.0+ for building from source

## Installation

### Building from Source

1. Open `BatteryManager.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run (Cmd+R)

### Permissions

The app will request notification permissions on first launch. This is required for:
- High battery alerts (when battery reaches 80%)
- Low battery alerts (when battery drops to 20%)

You can enable/disable these alerts in the Settings panel within the app.

## Usage

### Menu Bar
- The app runs in the menu bar
- Click the battery icon to see quick stats
- Click "Open Dashboard" to view detailed information

### Dashboard
- Shows comprehensive battery statistics
- Real-time power consumption graph
- Health and cycle count progress bars
- Detailed electrical properties
- Access settings via the gear icon

### Settings
- Toggle alerts on/off
- Adjust high battery threshold (70-100%)
- Adjust low battery threshold (5-30%)
- Alerts only trigger when charging (high) or discharging (low)

## Project Structure

```
BatteryManager/
├── Models/
│   └── BatteryInfo.swift          # Battery data model
├── Services/
│   └── BatteryService.swift       # IOKit battery information retrieval
├── ViewModels/
│   └── BatteryViewModel.swift     # State management and updates
├── Views/
│   ├── DashboardView.swift        # Main dashboard UI
│   ├── MenuBarView.swift          # Menu bar dropdown UI
│   └── Components/
│       ├── BatteryCardComponent.swift        # Reusable card components
│       └── HealthVisualizationView.swift     # Progress bars and charts
├── Managers/
│   └── AlertManager.swift         # Notification handling
├── Utils/
│   └── Theme.swift                # Centralized styling
└── BatteryManagerApp.swift        # App entry point
```

## Technical Details

### IOKit Integration
The app uses IOKit's `IOPowerSources` API to access low-level battery information:
- `kIOPSCurrentCapacityKey` - Current battery percentage
- `kIOPSIsChargingKey` - Charging status
- `kIOPSVoltageKey` - Voltage in millivolts
- `kIOPSCurrentKey` - Amperage in milliamperes
- `kIOPSMaxCapacityKey` - Maximum battery capacity
- `kIOPSDesignCapacityKey` - Original design capacity
- And more...

### Performance
- Updates every 3 seconds by default
- Maintains 60-point history for graphing (3 minutes)
- Minimal memory footprint
- Efficient battery queries

### Color Coding
- **Green**: Healthy (>80% health, >50% charge when not charging, charging)
- **Orange**: Warning (60-80% health, 20-50% charge)
- **Red**: Critical (<60% health, <20% charge)

## Troubleshooting

### "No Battery Detected"
- This app requires a MacBook with a battery
- Desktop Macs (iMac, Mac Mini, Mac Pro) are not supported

### "Unable to load battery info"
- Restart the app
- Check System Settings > Privacy & Security
- Ensure the app has necessary permissions

### Notifications Not Working
- Check System Settings > Notifications
- Ensure "Battery Manager" is allowed to send notifications
- Enable alerts in the app's Settings panel

## Development

### Adding New Features
The app is structured for easy extensibility:
- Add new metrics in `BatteryInfo.swift`
- Extend `BatteryService.swift` to retrieve new data
- Create new visualization components in `Views/Components/`
- Update `DashboardView.swift` to display new information

### Styling
All styling constants are centralized in `Theme.swift`:
- Colors, typography, spacing, corner radius
- Reusable view modifiers
- Consistent design system

## License

This project is created for educational and personal use.

## Credits

Created using:
- SwiftUI for modern UI
- IOKit for battery information
- UserNotifications for alerts
- Charts framework for visualizations

---

**Note**: Battery health calculations and cycle count are estimates based on current vs. design capacity. For authoritative battery health information, consult Apple's System Information app or Apple Support.

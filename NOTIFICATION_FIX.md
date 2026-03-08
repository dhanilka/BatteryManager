# Notification Permission Troubleshooting

## Problem
Getting error: "Notifications are not allowed for this application"

## Root Cause
The app has **App Sandbox** enabled, which requires proper entitlements to use UserNotifications framework. Sandboxed macOS apps need explicit capabilities declared.

## Solutions (Choose One)

### ✅ Solution 1: Add Entitlements File (RECOMMENDED)

I've created `BatteryManager.entitlements` file for you. Now add it to your Xcode project:

1. **In Xcode**, select your project in the navigator
2. Select the **BatteryManager** target
3. Go to **Build Settings** tab
4. Search for **"Code Signing Entitlements"**
5. Set the value to: `BatteryManager/BatteryManager.entitlements`
6. Clean build folder: **Product > Clean Build Folder** (Cmd+Shift+K)
7. Build and run again

The entitlements file includes:
- App Sandbox capability (required for Mac App Store)
- User selected files read-only access
- Application groups for data sharing

---

### 🔧 Solution 2: Grant System Permissions Manually

Even with sandboxing, you may need to manually enable notifications:

1. Open **System Settings** (or System Preferences on older macOS)
2. Go to **Notifications**
3. Scroll down and find **Battery Manager**
4. Toggle **Allow Notifications** to ON
5. Ensure these are enabled:
   - ☑️ Allow notifications
   - ☑️ Alerts
   - ☑️ Sound

---

### ⚠️ Solution 3: Disable App Sandbox (NOT RECOMMENDED)

Only use this for development/testing. **Don't use for distribution.**

1. In Xcode, select the **BatteryManager** target
2. Go to **Signing & Capabilities** tab
3. Find **App Sandbox** section
4. Click the **minus (-)** button to remove it
5. Clean and rebuild

**Note**: Apps without sandbox cannot be distributed via Mac App Store.

---

### 🔍 Solution 4: Add Push Notifications Capability

If the above solutions don't work, try adding explicit capability:

1. In Xcode, select the **BatteryManager** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Search and add **"Push Notifications"** (even though we're using local notifications)
5. Clean and rebuild

---

## How to Verify It's Working

After applying any solution:

1. **Clean Build**: Cmd+Shift+K
2. **Run the app**: Cmd+R
3. **Check console output** should show:
   ```
   ✅ Notification permission granted - alerts will work
   ```
   Instead of:
   ```
   ❌ Error requesting notification permission: Notifications are not allowed
   ```

4. **Test alerts**:
   - Open Dashboard (click menu bar icon → Open Dashboard)
   - Click the ⚙️ gear icon for Settings
   - Enable "Enable Alerts" toggle
   - Enable "Low Battery Alert"
   - Set threshold to 90% (or current battery level)
   - Wait for notification to appear

---

## Understanding App Sandbox

macOS App Sandbox is a security technology that:
- Restricts app access to system resources
- Required for Mac App Store distribution
- Requires explicit entitlements for features like:
  - File access
  - Network access
  - Notifications
  - Location services
  - etc.

By default, sandboxed apps **cannot** use many system features without declaring them in an entitlements file.

---

## Common Issues

### "Notification permission denied by user"
➡️ User clicked "Don't Allow" when prompted. Go to System Settings > Notifications to re-enable.

### Permission dialog never appears
➡️ Sandbox is blocking the request. Use Solution 1 or 3.

### Works in Debug but not Release
➡️ Ensure entitlements file is set in both Debug and Release configurations.

### App crashes on notification
➡️ Verify the app is properly code-signed with your development team.

---

## Current Status

✅ Entitlements file created: `BatteryManager/BatteryManager.entitlements`  
✅ AlertManager updated with better error handling  
✅ App now provides helpful console messages  

**Next Step**: Apply Solution 1 to add the entitlements file to your Xcode project.

---

## Need More Help?

Check the console output in Xcode when you run the app. It will now provide detailed guidance on what's needed.

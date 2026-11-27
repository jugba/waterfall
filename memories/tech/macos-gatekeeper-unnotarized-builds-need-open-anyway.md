# Unnotarized macOS builds are blocked by Gatekeeper; testers need "Open Anyway" or xattr

- Area: tech
- Date / source: 2026-11-27, user hit "Apple cannot check it for malicious software" on the
  Knolling Co. 0.1.0 playtest build (projects/002, prompt 15).
- Confidence: high
- Apply when: sending any macOS build to a tester, or deciding on Mac support at launch.

On macOS 15+, right-click → Open no longer bypasses it. Steps: open once → Done → System Settings
→ Privacy & Security → Open Anyway; or `xattr -dr com.apple.quarantine <App>.app`. Put the exact
warning text and these steps in the message that delivers the build. Steam-delivered builds
avoid the quarantine flag, but a smooth Mac release still needs an Apple Developer ID ($99/yr)
and notarization (can be done from Linux with rcodesign + an App Store Connect API key).

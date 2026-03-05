import AppKit

// Use the exact same pattern as the working test:
// Direct NSApplication + AppDelegate + app.run()
// NO SwiftUI lifecycle — it interferes with NSStatusItem visibility

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

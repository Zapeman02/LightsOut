import AppKit
import SwiftUI
import Testing
@testable import LightsOut

/// Renders the popover with whatever is running right now into docs/ for the README.
/// Only runs when asked: `LIGHTSOUT_SCREENSHOTS=1 swift test --filter Screenshot`.
@MainActor
struct ScreenshotTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["LIGHTSOUT_SCREENSHOTS"] != nil))
    func renderPopover() throws {
        let store = ProcessStore()
        store.refresh()
        let docs = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appending(path: "docs")
        for (appearance, file) in [(NSAppearance.Name.aqua, "light.png"), (.darkAqua, "dark.png")] {
            let view = ProcessListView(store: store)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.separator))
                .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
                .padding(24)
            try render(view, appearance: appearance, to: docs.appending(path: file))
        }
    }

    private func render(_ view: some View, appearance: NSAppearance.Name, to url: URL) throws {
        let host = NSHostingView(rootView: view)
        host.frame.size = host.fittingSize
        let window = NSWindow(contentRect: host.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: appearance)
        window.backgroundColor = .clear
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        let rep = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        rep.size = host.bounds.size
        host.cacheDisplay(in: host.bounds, to: rep)
        try #require(rep.representation(using: .png, properties: [:])).write(to: url)
    }
}

import SwiftUI
import AppKit

extension Notification.Name {
    static let showTomatiSettings = Notification.Name("ShowTomatiSettings")
}

@main
struct TomatiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
                .environment(TomatiModel.shared)
                .environment(appDelegate.updaterController)
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    let updaterController = UpdaterController()
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    private var settingsWindow: NSWindow?
    private var overtimePulseTimer: Timer?
    private var isPulseRed = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        TomatiModel.shared.updateDockIconVisibility()

        let contentView = ContentView().environment(TomatiModel.shared)
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 230, height: 162)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateMenuIcon()
        
        // 1. Escuchar Clicks Izquierdos Y Derechos
        if let button = statusItem.button {
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(handleStatusItemClick(_:))
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateMenuIcon), name: NSNotification.Name("UpdateMenuIcon"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showSettingsFromNotification), name: .showTomatiSettings, object: nil)
    }
    
    // 2. Discriminador de Clicks
    @objc func handleStatusItemClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            showContextMenu(sender)
        } else {
            togglePopover(sender)
        }
    }
    
    // 3. El Menú Nativo (Click Derecho)
    func showContextMenu(_ sender: NSStatusBarButton) {
        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Tomati", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        // Si el popover estaba abierto, ciérralo
        if popover.isShown { popover.performClose(nil) }
        
        // Muestra el menú debajo del icono
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 5), in: sender)
    }
    
    // MARK: - Acciones del Menú
    @objc func openSettings() {
        TomatiModel.shared.settingsSelection = "General"
        presentSettingsWindow()
    }
        
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            if let button = statusItem.button {
                togglePopover(button)
            }
        }
        return true
    }

    private func presentSettingsWindow() {
        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
            .environment(TomatiModel.shared)
            .environment(updaterController)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 390),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.minSize = NSSize(width: 520, height: 390)
        window.maxSize = NSSize(width: 520, height: 390)
        window.title = "Tomati Settings"
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: settingsView)
        window.center()

        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showSettingsFromNotification(_ notification: Notification) {
        presentSettingsWindow()
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    // MARK: - Lógica Anterior
    @objc func updateMenuIcon() {
        guard let button = statusItem.button else { return }
        let model = TomatiModel.shared
        let currentProgress = model.state == .idle ? 0.0 : model.progress
        button.image = generateProgressIcon(iconName: model.menuIcon, progress: currentProgress)
        updateOvertimePulse(isOvertime: model.state == .overtime)

        let targetSize = model.state == .idle
            ? NSSize(width: 230, height: 162)
            : NSSize(width: 230, height: model.activeSession == nil ? 70 : 92)
        if popover.contentSize != targetSize {
            resizePopover(to: targetSize)
        }
    }

    private func resizePopover(to targetSize: NSSize) {
        guard popover.isShown else {
            popover.contentSize = targetSize
            return
        }

        guard let window = popover.contentViewController?.view.window else {
            popover.contentSize = targetSize
            return
        }

        let targetContentRect = NSRect(origin: .zero, size: targetSize)
        let targetWindowSize = window.frameRect(forContentRect: targetContentRect).size
        var targetFrame = window.frame
        targetFrame.origin.x += (targetFrame.width - targetWindowSize.width) / 2
        targetFrame.origin.y += targetFrame.height - targetWindowSize.height
        targetFrame.size = targetWindowSize

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.24
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(targetFrame, display: true)
        } completionHandler: {
            MainActor.assumeIsolated {
                self.popover.contentSize = targetSize
            }
        }
    }

    private func updateOvertimePulse(isOvertime: Bool) {
        guard isOvertime else {
            overtimePulseTimer?.invalidate()
            overtimePulseTimer = nil
            return
        }

        guard overtimePulseTimer == nil else { return }
        isPulseRed = true
        tintMenuBarIcon(.systemRed)

        let timer = Timer(timeInterval: 0.55, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.isPulseRed.toggle()
                self.tintMenuBarIcon(self.isPulseRed ? .systemRed : .white)
            }
        }
        overtimePulseTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func tintMenuBarIcon(_ color: NSColor) {
        guard let sourceImage = statusItem.button?.image else { return }
        let tintedImage = NSImage(size: sourceImage.size)
        tintedImage.lockFocus()
        sourceImage.draw(
            in: NSRect(origin: .zero, size: sourceImage.size),
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
        color.setFill()
        NSRect(origin: .zero, size: sourceImage.size).fill(using: .sourceAtop)
        tintedImage.unlockFocus()
        tintedImage.isTemplate = false
        statusItem.button?.image = tintedImage
    }
    
    func generateProgressIcon(iconName: String, progress: Double) -> NSImage {
        let fillRatio = 1.0 - progress
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let baseImage: NSImage
        if iconName == "tomato" {
            baseImage = generateTomatoIcon()
        } else {
            guard let symbol = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)?.withSymbolConfiguration(config) else {
                return generateTomatoIcon()
            }
            baseImage = symbol
        }
        let size = baseImage.size
        let image = NSImage(size: size)
        image.lockFocus()
        baseImage.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .sourceOver, fraction: 0.3)
        let clipHeight = size.height * CGFloat(fillRatio)
        let clipRect = NSRect(x: 0, y: 0, width: size.width, height: clipHeight)
        NSGraphicsContext.current?.saveGraphicsState()
        NSBezierPath.clip(clipRect)
        baseImage.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .sourceOver, fraction: 1.0)
        NSGraphicsContext.current?.restoreGraphicsState()
        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    private func generateTomatoIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        NSColor.black.setFill()
        NSBezierPath(ovalIn: NSRect(x: 2, y: 1.5, width: 14, height: 13)).fill()

        let leaves = NSBezierPath()
        leaves.move(to: NSPoint(x: 9, y: 13))
        leaves.line(to: NSPoint(x: 5.2, y: 16.2))
        leaves.line(to: NSPoint(x: 8.2, y: 15.5))
        leaves.line(to: NSPoint(x: 9, y: 17.2))
        leaves.line(to: NSPoint(x: 9.8, y: 15.5))
        leaves.line(to: NSPoint(x: 13.2, y: 16.2))
        leaves.close()
        leaves.fill()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}

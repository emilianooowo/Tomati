import SwiftUI
import AppKit

struct SettingsView: View {
    @Environment(TomatiModel.self) private var model

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 3) {
                SidebarTabButton(
                    title: "General",
                    systemImage: "gearshape",
                    isSelected: model.settingsSelection == "General",
                    accentColor: model.accentColor,
                    textColor: model.accentForegroundColor
                ) {
                    model.settingsSelection = "General"
                }

                SidebarTabButton(
                    title: "Sessions",
                    systemImage: "rectangle.stack",
                    isSelected: model.settingsSelection == "Sessions",
                    accentColor: model.accentColor,
                    textColor: model.accentForegroundColor
                ) {
                    model.settingsSelection = "Sessions"
                }

                SidebarTabButton(
                    title: "System",
                    systemImage: "desktopcomputer",
                    isSelected: model.settingsSelection == "System",
                    accentColor: model.accentColor,
                    textColor: model.accentForegroundColor
                ) {
                    model.settingsSelection = "System"
                }

                SidebarTabButton(
                    title: "Sounds",
                    systemImage: "speaker.wave.2",
                    isSelected: model.settingsSelection == "Sounds",
                    accentColor: model.accentColor,
                    textColor: model.accentForegroundColor
                ) {
                    model.settingsSelection = "Sounds"
                }

                Spacer()

                SidebarTabButton(
                    title: "About",
                    systemImage: "info.circle",
                    isSelected: model.settingsSelection == "About",
                    accentColor: model.accentColor,
                    textColor: model.accentForegroundColor
                ) {
                    model.settingsSelection = "About"
                }

                SidebarTabButton(
                    title: "What’s New",
                    systemImage: "sparkles",
                    isSelected: model.settingsSelection == "WhatsNew",
                    accentColor: model.accentColor,
                    textColor: model.accentForegroundColor
                ) {
                    model.settingsSelection = "WhatsNew"
                }
            }
            .padding(8)
            .frame(maxHeight: .infinity)
            .navigationSplitViewColumnWidth(min: 130, ideal: 130, max: 130)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            if model.settingsSelection == "Sessions" {
                SessionsSettingsView()
            } else if model.settingsSelection == "System" {
                SystemSettingsView()
            } else if model.settingsSelection == "Sounds" {
                SoundsSettingsView()
            } else if model.settingsSelection == "About" {
                AboutTomatiView()
            } else if model.settingsSelection == "WhatsNew" {
                WhatsNewView()
            } else {
                GeneralSettingsView()
            }
        }
        .frame(width: 520, height: 390)
    }
}

private struct SidebarTabButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let accentColor: Color
    let textColor: Color
    let action: () -> Void

    @Environment(\.controlActiveState) private var controlActiveState
    @State private var isHovering = false

    private var isActive: Bool {
        controlActiveState == .key || controlActiveState == .active
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? (isActive ? textColor : .primary) : (isHovering ? .primary : .secondary))
                    .frame(width: 18)

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? (isActive ? textColor : .primary) : .primary)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .frame(height: 28)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isActive ? accentColor : Color.secondary.opacity(0.2))
                } else if isHovering {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

private struct GeneralSettingsView: View {
    @Environment(TomatiModel.self) private var model

    private let icons = [
        MenuIconChoice(id: "hourglass", name: "Hourglass"),
        MenuIconChoice(id: "clock", name: "Clock"),
        MenuIconChoice(id: "timer", name: "Timer"),
        MenuIconChoice(id: "circle", name: "Circle"),
        MenuIconChoice(id: "tomato", name: "Tomati")
    ]
    var body: some View {
        @Bindable var bindableModel = model

        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 18) {
                Text("General")
                    .font(.title2.bold())

                settingsSection("Appearance", subtitle: "Choose the accent color and menu bar icon.") {
                    HStack(spacing: 12) {
                        ColorPicker("Accent color", selection: $bindableModel.accentColor, supportsOpacity: false)

                        Spacer(minLength: 8)

                        HStack(spacing: 5) {
                            ForEach(icons) { icon in
                                Button {
                                    model.menuIcon = icon.id
                                } label: {
                                    MenuIconGlyph(icon: icon.id)
                                        .font(.system(size: 14, weight: .medium))
                                        .frame(width: 28, height: 28)
                                        .background(
                                            model.menuIcon == icon.id
                                                ? model.accentColor.opacity(0.18)
                                                : Color.primary.opacity(0.045),
                                            in: RoundedRectangle(cornerRadius: 7)
                                        )
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 7)
                                                .stroke(model.menuIcon == icon.id ? model.accentColor : .clear, lineWidth: 1.5)
                                        }
                                }
                                .buttonStyle(.plain)
                                .help(icon.name)
                                .accessibilityLabel(icon.name)
                            }
                        }
                    }
                }

                Divider()

                settingsSection("Presets & Limits", subtitle: "Set the scale limit and your quick-start timers.") {
                    HStack(spacing: 14) {
                        HStack(spacing: 6) {
                            Text("Scale limit")
                                .font(.subheadline)
                            TextField("Minutes", value: $bindableModel.maxCustomTime, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 52)
                            Text("min")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 8)

                        HStack(spacing: 6) {
                            ForEach(0..<4, id: \.self) { slot in
                                if slot < model.presets.count {
                                    PresetEditCircle(index: slot)
                                } else {
                                    AddPresetCircle(slot: slot)
                                }
                            }
                        }
                    }
                }

            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.automatic)
    }

    private func settingsSection<Content: View>(
        _ title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            content()
        }
    }
}

private struct MenuIconChoice: Identifiable {
    let id: String
    let name: String
}

private struct MenuIconGlyph: View {
    let icon: String

    var body: some View {
        if icon == "tomato" {
            ZStack {
                Ellipse()
                    .strokeBorder(lineWidth: 1.7)
                    .frame(width: 16, height: 13)
                    .offset(y: 1.5)

                Image(systemName: "leaf.fill")
                    .font(.system(size: 7, weight: .bold))
                    .rotationEffect(.degrees(-18))
                    .offset(x: 1, y: -6)
            }
            .frame(width: 18, height: 18)
        } else {
            Image(systemName: icon)
        }
    }
}

private struct AboutTomatiView: View {
    @Environment(UpdaterController.self) private var updaterController

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .accessibilityHidden(true)

            Text("Tomati")
                .font(.title2.bold())

            Text("Developed by Emiliano Leal")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Version \(version)")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Button("Check for Updates…") {
                updaterController.checkForUpdates()
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .controlSize(.regular)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

private struct WhatsNewView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("What’s New")
                        .font(.title2.bold())
                    Text("Tomati 2.1")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                whatsNewRow(
                    icon: "slider.horizontal.3",
                    title: "Compact time picker",
                    description: "Choose a duration faster with a denser draggable minute scale."
                )

                whatsNewRow(
                    icon: "square.grid.2x2",
                    title: "Grouped presets",
                    description: "Quick presets now live inside a single compact menu."
                )

                whatsNewRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Built-in updates",
                    description: "Check for new versions directly from About Tomati."
                )

                whatsNewRow(
                    icon: "sidebar.left",
                    title: "Cleaner Settings",
                    description: "Sessions and system controls are simpler and more consistent."
                )
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func whatsNewRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 26, height: 26)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct SystemSettingsView: View {
    @Environment(TomatiModel.self) private var model

    var body: some View {
        @Bindable var bindableModel = model

        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 2) {
                Text("System")
                    .font(.title2.bold())
                Text("Configure how Tomati behaves in macOS.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    settingLabel(
                        "Launch at login",
                        description: "Open Tomati automatically when you log in."
                    )
                    Spacer(minLength: 16)
                    Toggle("", isOn: $bindableModel.launchAtLogin)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                Divider()

                HStack {
                    settingLabel(
                        "Show icon in Dock",
                        description: "Display Tomati in the macOS Dock."
                    )
                    Spacer(minLength: 16)
                    Toggle("", isOn: $bindableModel.showDockIcon)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            model.refreshLaunchAtLoginStatus()
        }
    }

    private func settingLabel(_ title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.subheadline)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct SoundsSettingsView: View {
    @Environment(TomatiModel.self) private var model
    private let sounds = ["Ping", "Glass", "Basso", "Blow", "Bottle", "Frog", "Tink"]

    var body: some View {
        @Bindable var bindableModel = model

        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Sounds")
                    .font(.title2.bold())
                Text("Choose the sound played when a timer finishes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Alarm sound")
                        .font(.subheadline)
                    Text("Hover over an option to hear a preview.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                SoundPicker(
                    selection: $bindableModel.alarmSound,
                    sounds: sounds,
                    onPreview: { model.playSoundPreview(name: $0) }
                )
                .frame(width: 140, height: 24)
            }

            Spacer()
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct PresetEditCircle: View {
    @Environment(TomatiModel.self) private var model
    @State private var isHovering = false
    let index: Int

    private var presetValue: Binding<Double> {
        Binding(
            get: {
                guard model.presets.indices.contains(index) else { return 0 }
                return model.presets[index]
            },
            set: { newValue in
                guard model.presets.indices.contains(index) else { return }
                model.presets[index] = newValue
            }
        )
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TextField("", value: presetValue, format: .number)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle().strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.55), .clear, .black.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                }

            if isHovering && model.presets.count > 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        model.removePreset(at: index)
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .red)
                }
                .buttonStyle(.plain)
                .offset(x: 4, y: -4)
            }
        }
        .frame(width: 40, height: 40)
        .onHover { isHovering = $0 }
    }
}

private struct AddPresetCircle: View {
    @Environment(TomatiModel.self) private var model
    let slot: Int

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                model.addPreset(at: slot)
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .overlay {
                    Circle()
                        .strokeBorder(
                            Color.secondary.opacity(0.5),
                            style: StrokeStyle(lineWidth: 1.4, dash: [4, 3])
                        )
                }
        }
        .buttonStyle(.plain)
        .frame(width: 40, height: 40)
        .help("Add preset")
    }
}

private struct SessionsSettingsView: View {
    @Environment(TomatiModel.self) private var model

    var body: some View {
        @Bindable var bindableModel = model

        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sessions")
                            .font(.title2.bold())
                        Text("Alternate focus intervals and breaks.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            model.addSession()
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(model.accentColor)
                    .controlSize(.small)
                    .help("New session")
                }

                if model.sessions.isEmpty {
                    ContentUnavailableView(
                        "No Sessions",
                        systemImage: "rectangle.stack.badge.plus",
                        description: Text("Create a session to combine focus intervals with automatic breaks.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 190)
                } else {
                    ForEach(Array(model.sessions.enumerated()), id: \.element.id) { index, session in
                        SessionEditorCard(
                            session: $bindableModel.sessions[index],
                            onDelete: { model.removeSession(id: session.id) }
                        )
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct SessionEditorCard: View {
    @Binding var session: FocusSession
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                TextField("Session name", text: $session.name)
                    .textFieldStyle(.plain)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                ColorPicker(
                    "Session accent",
                    selection: Binding(
                        get: { session.accentColor },
                        set: { session.setAccentColor($0) }
                    ),
                    supportsOpacity: false
                )
                .labelsHidden()
                .help("Session accent color")

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)
                .help("Delete session")
            }

            HStack(spacing: 10) {
                Stepper(value: $session.intervalCount, in: 1...24) {
                    Text("\(session.intervalCount) intervals")
                        .font(.caption)
                        .monospacedDigit()
                }
                .frame(width: 120, alignment: .leading)

                Spacer(minLength: 4)

                sessionDurationField("Focus", value: $session.focusMinutes)
                sessionDurationField("Break", value: $session.breakMinutes)
            }
        }
        .padding(11)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .leading) {
            Capsule()
                .fill(session.accentColor)
                .frame(width: 3)
                .padding(.vertical, 8)
        }
    }

    private func sessionDurationField(_ title: String, value: Binding<Double>) -> some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                TextField("Minutes", value: value, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 46)
            }
            Text("min")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 12)
        }
    }
}

private struct SoundPicker: NSViewRepresentable {
    @Binding var selection: String
    let sounds: [String]
    let onPreview: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSPopUpButton {
        let picker = NSPopUpButton(frame: .zero, pullsDown: false)
        picker.controlSize = .small
        picker.addItems(withTitles: sounds)
        picker.selectItem(withTitle: selection)
        picker.target = context.coordinator
        picker.action = #selector(Coordinator.didSelect(_:))
        picker.menu?.delegate = context.coordinator
        return picker
    }

    func updateNSView(_ picker: NSPopUpButton, context: Context) {
        context.coordinator.parent = self

        if picker.itemTitles != sounds {
            picker.removeAllItems()
            picker.addItems(withTitles: sounds)
        }
        if picker.titleOfSelectedItem != selection {
            picker.selectItem(withTitle: selection)
        }
        picker.menu?.delegate = context.coordinator
    }

    final class Coordinator: NSObject, NSMenuDelegate {
        var parent: SoundPicker

        init(parent: SoundPicker) {
            self.parent = parent
        }

        @objc func didSelect(_ sender: NSPopUpButton) {
            guard let selectedSound = sender.titleOfSelectedItem else { return }
            parent.selection = selectedSound
        }

        func menu(_ menu: NSMenu, willHighlight item: NSMenuItem?) {
            guard let sound = item?.title, parent.sounds.contains(sound) else { return }
            parent.onPreview(sound)
        }
    }
}

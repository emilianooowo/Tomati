import SwiftUI
import AppKit

private struct SettingsContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private extension View {
    func reportSettingsContentHeight() -> some View {
        background {
            GeometryReader { geometry in
                Color.clear.preference(key: SettingsContentHeightKey.self, value: geometry.size.height)
            }
        }
    }
}

struct SettingsView: View {
    @Environment(TomatiModel.self) private var model
    @State private var measuredContentHeight: CGFloat = 0

    private var windowHeight: CGFloat {
        if model.settingsSelection == "WhatsNew" { return 390 }
        return measuredContentHeight > 0 ? 61 + measuredContentHeight : 390
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 2) {
                SettingsTabButton(title: "General", systemImage: "gearshape", isSelected: model.settingsSelection == "General") {
                    model.settingsSelection = "General"
                }
                SettingsTabButton(title: "Sessions", systemImage: "rectangle.stack", isSelected: model.settingsSelection == "Sessions") {
                    model.settingsSelection = "Sessions"
                }
                SettingsTabButton(title: "About", systemImage: "info.circle", isSelected: model.settingsSelection == "About") {
                    model.settingsSelection = "About"
                }
                SettingsTabButton(title: "What’s New", systemImage: "sparkles", isSelected: model.settingsSelection == "WhatsNew") {
                    model.settingsSelection = "WhatsNew"
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
            .padding(.bottom, 4)

            Divider()

            Group {
                if model.settingsSelection == "Sessions" {
                    SessionsSettingsView()
                } else if model.settingsSelection == "About" {
                    AboutTomatiView()
                } else if model.settingsSelection == "WhatsNew" {
                    WhatsNewPage()
                } else {
                    GeneralSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(width: 520, height: windowHeight)
        .background(alignment: .bottom) {
            SettingsWindowSizer(contentHeight: windowHeight)
                .frame(width: 1, height: 1)
                .opacity(0)
        }
        .onPreferenceChange(SettingsContentHeightKey.self) { height in
            guard height > 0 else { return }
            measuredContentHeight = ceil(height)
        }
    }
}

private struct SettingsTabButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: .regular))

                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(isSelected ? Color.blue : Color.secondary)
            .frame(width: 70, height: 52)
            .modifier(SettingsTabGlass(isSelected: isSelected))
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}

private struct SettingsOptionRow<Controls: View>: View {
    let title: String
    let description: String
    let controls: Controls

    init(
        title: String,
        description: String,
        @ViewBuilder controls: () -> Controls
    ) {
        self.title = title
        self.description = description
        self.controls = controls()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                if !description.isEmpty {
                    Text(description)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            controls
        }
        .padding(.vertical, 8)
    }
}

private struct SettingsTabGlass: ViewModifier {
    let isSelected: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isSelected {
            content.background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.clear)
                    .liquidGlass(in: RoundedRectangle(cornerRadius: 10, style: .continuous), interactive: true)
            }
        } else {
            content
        }
    }
}

private struct SettingsPopoverControlGlass: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: Circle())
            .overlay {
                Circle().strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.55), .clear, .black.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            }
            .shadow(color: .black.opacity(0.14), radius: 3, x: 0, y: 1.5)
    }
}

private struct SettingsWindowSizer: NSViewRepresentable {
    let contentHeight: CGFloat

    func makeNSView(context: Context) -> SettingsSizerNSView {
        SettingsSizerNSView(contentHeight: contentHeight)
    }

    func updateNSView(_ view: SettingsSizerNSView, context: Context) {
        view.contentHeight = contentHeight
    }
}

private final class SettingsSizerNSView: NSView {
    var contentHeight: CGFloat {
        didSet { resizeWindow() }
    }

    init(contentHeight: CGFloat) {
        self.contentHeight = contentHeight
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        resizeWindow()
    }

    private func resizeWindow() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let window = self.window else { return }
            let targetContent = NSRect(x: 0, y: 0, width: 520, height: self.contentHeight)
            let targetFrame = window.frameRect(forContentRect: targetContent)
            var frame = window.frame
            frame.origin.x = frame.midX - targetFrame.width / 2
            frame.origin.y += frame.height - targetFrame.height
            frame.size = targetFrame.size
            window.setFrame(frame, display: true, animate: true)
        }
    }
}

private struct GeneralSettingsView: View {
    @Environment(TomatiModel.self) private var model
    private let sounds = ["Ping", "Glass", "Basso", "Blow", "Bottle", "Frog", "Tink"]
    var body: some View {
        @Bindable var bindableModel = model

        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 6) {
                VStack(spacing: 0) {
                    Text("General")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 4)

                    SettingsOptionRow(title: "Accent color", description: "Choose the timer’s highlight color.") {
                        ColorPicker("Accent color", selection: $bindableModel.accentColor, supportsOpacity: false)
                            .labelsHidden()
                    }

                    SettingsOptionRow(title: "Quick presets", description: "Edit the minute shortcuts in the timer.") {
                        HStack(spacing: 0) {
                            ForEach(0..<4, id: \.self) { slot in
                                if slot < model.presets.count {
                                    PresetEditCircle(index: slot)
                                } else {
                                    AddPresetCircle(slot: slot)
                                }
                            }
                        }
                    }

                    Text("System")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 10)

                    SettingsOptionRow(title: "Launch at login", description: "Open Tomati automatically when you log in.") {
                        Toggle("", isOn: $bindableModel.launchAtLogin).labelsHidden()
                    }

                    SettingsOptionRow(title: "Show icon in Dock", description: "Display Tomati in the macOS Dock.") {
                        Toggle("", isOn: $bindableModel.showDockIcon).labelsHidden()
                    }

                    Text("Sounds")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 10)

                    SettingsOptionRow(title: "Alarm sound", description: "Choose and preview the sound played when a timer ends.") {
                        Picker("Alarm sound", selection: $bindableModel.alarmSound) {
                            ForEach(sounds, id: \.self) { sound in
                                Text(sound).tag(sound)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(width: 145, alignment: .trailing)
                        .onChange(of: model.alarmSound) { _, sound in
                            model.playSoundPreview(name: sound)
                        }
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 14)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .reportSettingsContentHeight()
        }
        .scrollIndicators(.automatic)
        .onAppear { model.refreshLaunchAtLoginStatus() }
    }
}

private struct AboutTomatiView: View {
    @Environment(UpdaterController.self) private var updaterController

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 88, height: 88)
                    .accessibilityHidden(true)

                VStack(spacing: 3) {
                    Text("Tomati")
                        .font(.title2.bold())
                    Text("Developed by Emiliano Leal")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text("Version \(version)")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                }

                Button("Check for Updates…") {
                    updaterController.checkForUpdates()
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 14)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .center)
            .reportSettingsContentHeight()
        }
    }
}

private struct WhatsNewPage: View {
    var body: some View {
        ScrollView {
            WhatsNewView()
                .padding(.horizontal, 22)
                .padding(.top, 14)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .reportSettingsContentHeight()
                .frame(minHeight: 305, alignment: .top)
        }
    }
}

private struct WhatsNewView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What’s New")
                .font(.title2.bold())

            release(
                version: "2.3.0",
                summary: "More control over focus sessions and a refreshed Settings experience.",
                changes: [
                    "Added progressive alarms and overtime at each Focus and Break transition, with a control to advance to the next phase.",
                    "Added a clear Focus or Break indicator and session-specific progress color.",
                    "Redesigned session settings as compact cards with editable names, colors, intervals, and durations.",
                    "Quick presets can now be removed completely and added again later.",
                    "Refreshed Settings with native macOS controls and removed the menu bar icon selector.",
                    "Fixed a crash when deleting the last session."
                ]
            )

            release(
                version: "2.2.0",
                summary: "A simpler timer and a more focused Settings window.",
                changes: [
                    "Replaced the minute scale with editable minute and second fields.",
                    "Added a compact Liquid Glass timer popover with progress fill.",
                    "Grouped System and Sounds options under General.",
                    "Made Settings resize to fit each section."
                ]
            )

            release(
                version: "2.1.5",
                summary: "A focused refinement of the timer and release history.",
                changes: [
                    "Animated the minute scale while choosing a duration.",
                    "Simplified session cards.",
                    "Added a compact release history."
                ]
            )

            release(
                version: "2.1",
                summary: "A faster timer picker, clearer Settings, and secure updates.",
                changes: [
                    "Made the minute scale compact and draggable.",
                    "Grouped presets into a single menu.",
                    "Simplified Sessions and aligned System controls.",
                    "Added update checks with Sparkle.",
                    "Added clean defaults for Debug runs."
                ]
            )

            release(
                version: "1.0",
                summary: "Tomati arrives as a compact focus timer for the macOS menu bar.",
                changes: [
                    "Choose any timer duration or use a preset.",
                    "Create focus sessions with automatic breaks.",
                    "Pause, resume, reset, and follow overtime.",
                    "Personalize the accent, sounds, and menu bar icon.",
                    "Keep the timer visible without occupying the Dock."
                ]
            )
        }
    }

    private func release(version: String, summary: String, changes: [String]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(version)
                .font(.title3.bold())

            Text(summary)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 5) {
                ForEach(changes, id: \.self) { change in
                    HStack(alignment: .firstTextBaseline, spacing: 7) {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text(change)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
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
        TextField("", value: presetValue, format: .number)
            .textFieldStyle(.plain)
            .multilineTextAlignment(.center)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .padding(2)
            .frame(width: 29, height: 29)
            .modifier(SettingsPopoverControlGlass())
            .frame(width: 34, height: 34)
            .overlay(alignment: .topTrailing) {
                if isHovering && !model.presets.isEmpty {
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
                    .offset(x: 3, y: -3)
                }
            }
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
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.secondary)
                .overlay {
                    Circle()
                        .strokeBorder(Color.secondary.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                        .frame(width: 29, height: 29)
                }
                .frame(width: 29, height: 29)
        }
        .buttonStyle(.plain)
        .frame(width: 34, height: 34)
        .help("Add preset")
    }
}

private struct SessionsSettingsView: View {
    @Environment(TomatiModel.self) private var model
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .top), count: 3)

    var body: some View {
        @Bindable var bindableModel = model

        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sessions")
                            .font(.title2.bold())
                        Text("Alternate focus intervals and breaks.")
                            .font(.callout)
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
                    .buttonStyle(.plain)
                    .foregroundStyle(model.accentColor)
                    .frame(width: 24, height: 24)
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
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                        ForEach($bindableModel.sessions) { $session in
                            SessionEditorCard(
                                session: $session,
                                onDelete: { model.removeSession(id: session.id) }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 14)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .reportSettingsContentHeight()
        }
    }
}

private struct SessionEditorCard: View {
    @Binding var session: FocusSession
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Session name", text: $session.name)
                .textFieldStyle(.plain)
                .font(.title3.bold())
                .lineLimit(1)

            HStack(spacing: 6) {
                Text("Change color")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
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
            }

            HStack(spacing: 4) {
                Text("Intervals")
                    .font(.callout)
                Spacer(minLength: 0)
                Stepper(value: $session.intervalCount, in: 1...24) {
                    Text("\(session.intervalCount)")
                        .font(.callout)
                        .monospacedDigit()
                        .frame(minWidth: 16)
                }
                .controlSize(.small)
                .fixedSize()
            }

            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Focus")
                        .font(.callout)
                    sessionDurationField(value: $session.focusMinutes)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Break")
                        .font(.callout)
                    sessionDurationField(value: $session.breakMinutes)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Spacer(minLength: 0)
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
                .help("Delete session")
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 166, alignment: .topLeading)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func sessionDurationField(value: Binding<Double>) -> some View {
        HStack(spacing: 3) {
            TextField("Minutes", value: value, format: .number)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.leading)
                .font(.callout)
                .frame(width: 36)
            Text("min")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

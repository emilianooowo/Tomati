import SwiftUI

private enum DurationField: Hashable {
    case minutes
    case seconds
}

struct LiquidGlassSurface<S: Shape>: ViewModifier {
    let shape: S
    var interactive = false

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(.regular.interactive(interactive), in: shape)
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .overlay { shape.stroke(Color.primary.opacity(0.08), lineWidth: 0.8) }
        }
    }
}

extension View {
    func liquidGlass<S: Shape>(in shape: S, interactive: Bool = false) -> some View {
        modifier(LiquidGlassSurface(shape: shape, interactive: interactive))
    }
}

private struct PopoverControlGlass: ViewModifier {
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

private struct GlassIcon: View {
    let name: String
    var color: Color = .primary
    var size: CGFloat = 30

    var body: some View {
        Image(systemName: name)
            .font(.system(size: size * 0.42, weight: .medium))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .modifier(PopoverControlGlass())
    }
}

struct ContentView: View {
    @Environment(TomatiModel.self) private var model

    @State private var minutesText = "00"
    @State private var secondsText = "00"
    @State private var customMinutes = 0.0
    @FocusState private var focusedField: DurationField?

    private var isIdle: Bool { model.state == .idle }
    private var isSessionOvertime: Bool { model.state == .overtime && model.activeSession != nil }
    private var canStart: Bool { isIdle && customMinutes > 0 }
    private var elapsedProgress: Double { min(1, max(0, 1 - model.progress)) }
    private var durationFontSize: CGFloat {
        if minutesText.count > 5 { 18 }
        else if minutesText.count > 3 { 22 }
        else { 29 }
    }
    private var minutesFieldWidth: CGFloat {
        max(38, CGFloat(minutesText.count) * durationFontSize * 0.6 + 4)
    }

    private var minutesBinding: Binding<String> {
        Binding(
            get: { minutesText },
            set: { value in
                minutesText = String(value.filter(\.isNumber).prefix(6))
                updateDurationFromFields()
            }
        )
    }

    private var secondsBinding: Binding<String> {
        Binding(
            get: { secondsText },
            set: { value in
                let digits = String(value.filter(\.isNumber).prefix(2))
                let seconds = min(59, Int(digits) ?? 0)
                secondsText = digits.count == 2 && seconds == 59 && (Int(digits) ?? 0) > 59
                    ? "59"
                    : digits
                updateDurationFromFields()
            }
        )
    }

    private func updateDurationFromFields() {
        let minutes = Double(minutesText) ?? 0
        let seconds = min(59, Double(secondsText) ?? 0)
        customMinutes = minutes + seconds / 60
    }

    private func setDurationFields(minutes: Double) {
        let totalSeconds = max(0, Int((minutes * 60).rounded()))
        minutesText = String(format: "%02d", totalSeconds / 60)
        secondsText = String(format: "%02d", totalSeconds % 60)
        customMinutes = minutes
    }

    private func normalizeDurationFields() {
        let minutes = max(0, Int(minutesText) ?? 0)
        let seconds = min(59, max(0, Int(secondsText) ?? 0))
        minutesText = String(format: "%02d", minutes)
        secondsText = String(format: "%02d", seconds)
        customMinutes = Double(minutes) + Double(seconds) / 60
        focusedField = nil
    }

    private func startTimer(minutes: Double? = nil) {
        if let minutes {
            setDurationFields(minutes: minutes)
        } else {
            normalizeDurationFields()
        }

        let duration = minutes ?? customMinutes
        guard duration.isFinite, duration > 0, isIdle else { return }

        withAnimation(.easeInOut(duration: 0.22)) {
            model.start(minutes: duration)
        }
    }

    private func toggleTimer() {
        if isSessionOvertime {
            withAnimation(.easeInOut(duration: 0.2)) {
                model.advanceToNextSessionPhase()
            }
        } else if isIdle {
            startTimer()
        } else {
            withAnimation(.easeInOut(duration: 0.18)) {
                model.toggle()
            }
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                if isIdle {
                    durationEntry
                } else if let phaseLabel = model.sessionPhaseLabel {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(model.timeString)
                            .font(.system(size: 29, weight: .light, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .accessibilityLabel(model.state == .overtime ? "Overtime" : "Time remaining")

                        Text(phaseLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Session phase: \(phaseLabel)")
                    }
                } else {
                    Text(model.timeString)
                        .font(.system(size: 29, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .accessibilityLabel("Time remaining")
                }

                Spacer(minLength: 0)

                if model.state == .running || model.state == .paused || isSessionOvertime {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            model.stop()
                        }
                    } label: {
                        GlassIcon(name: "stop.fill", size: 26)
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .help(model.activeSession == nil ? "Cancel timer" : "Cancel session")
                }

                Button(action: toggleTimer) {
                    GlassIcon(name: primaryControlIcon, size: 28)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .disabled(isIdle && !canStart)
                .accessibilityLabel(primaryControlHelp)
                .help(primaryControlHelp)
            }
            .frame(height: model.sessionPhaseLabel == nil ? 36 : 50)

            if isIdle {
                bottomBar
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .frame(width: 222)
        .background {
            GeometryReader { geometry in
                if !isIdle {
                    Rectangle()
                        .fill(model.timerAccentColor.opacity(0.32))
                        .frame(width: geometry.size.width * elapsedProgress)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(.linear(duration: 1), value: model.progress)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.state)
        .onAppear {
            setDurationFields(minutes: customMinutes)
        }
        .onChange(of: model.state) { _, newState in
            if newState == .idle {
                setDurationFields(minutes: customMinutes)
            }
        }
    }

    private var durationEntry: some View {
        HStack(spacing: 2) {
            TextField("00", text: minutesBinding)
                .textFieldStyle(.plain)
                .font(.system(size: durationFontSize, weight: .light, design: .rounded))
                .monospacedDigit()
                .multilineTextAlignment(.leading)
                .frame(width: minutesFieldWidth, alignment: .leading)
                .focused($focusedField, equals: .minutes)
                .onSubmit { focusedField = .seconds }
                .accessibilityLabel("Minutes")

            Text(":")
                .font(.system(size: durationFontSize, weight: .light, design: .rounded))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField("00", text: secondsBinding)
                .textFieldStyle(.plain)
                .font(.system(size: durationFontSize, weight: .light, design: .rounded))
                .monospacedDigit()
                .multilineTextAlignment(.leading)
                .frame(width: 42)
                .focused($focusedField, equals: .seconds)
                .onSubmit { normalizeDurationFields() }
                .accessibilityLabel("Seconds")
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 2) {
            ForEach(Array(model.presets.enumerated()), id: \.offset) { _, preset in
                Button {
                    startTimer(minutes: preset)
                } label: {
                    Text("\(Int(preset))")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .frame(width: 28, height: 28)
                        .modifier(PopoverControlGlass())
                }
                .buttonStyle(.plain)
                .help("Start a \(Int(preset))-minute timer")
            }

            Spacer(minLength: 4)

            Menu {
                if model.sessions.isEmpty {
                    Button("Create a Session…") {
                        showSessionsSettings()
                    }
                } else {
                    ForEach(model.sessions) { session in
                        Button {
                            withAnimation(.easeInOut(duration: 0.22)) {
                                model.start(session: session)
                            }
                        } label: {
                            Text("\(session.name.isEmpty ? "Untitled Session" : session.name) · \(session.intervalCount)×")
                        }
                    }

                    Divider()

                    Button("Manage Sessions…") {
                        showSessionsSettings()
                    }
                }
            } label: {
                GlassIcon(name: "rectangle.stack", size: 28)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Sessions")

            Button {
                model.settingsSelection = "General"
                NotificationCenter.default.post(name: .showTomatiSettings, object: nil)
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help("Settings")
        }
        .frame(height: 30)
    }

    private func showSessionsSettings() {
        model.settingsSelection = "Sessions"
        NotificationCenter.default.post(name: .showTomatiSettings, object: nil)
    }

    private var primaryControlIcon: String {
        switch model.state {
        case .idle, .paused: "play.fill"
        case .running: "pause.fill"
        case .overtime: model.activeSession == nil ? "stop.fill" : "forward.end.fill"
        }
    }

    private var primaryControlHelp: String {
        switch model.state {
        case .idle: "Start timer"
        case .running: "Pause timer"
        case .paused: "Resume timer"
        case .overtime: model.activeSession == nil ? "Stop timer" : "Advance session phase"
        }
    }
}

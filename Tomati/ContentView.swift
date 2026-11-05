import SwiftUI

struct LiquidGlassModifier: ViewModifier {
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

extension View {
    func liquidGlass() -> some View { modifier(LiquidGlassModifier()) }
}

private struct GlassIcon: View {
    let name: String
    var color: Color = .primary
    var size: CGFloat = 27

    var body: some View {
        Image(systemName: name)
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .liquidGlass()
    }
}

private struct GlassResetIcon: View {
    let color: Color

    var body: some View {
        Image(systemName: "stop.fill")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(color)
            .frame(width: 22, height: 22)
            .background(.ultraThinMaterial, in: Circle())
            .overlay {
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.55), .clear, .black.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
    }
}

private struct DraggableMinuteScale: View {
    let maximumMinutes: Int
    let accentColor: Color
    @Binding var selectedMinutes: Double

    @State private var dragOriginMinutes: Double?
    @State private var visualMinutes: Double = 0
    @State private var isDragging = false
    @State private var isHovering = false

    private let pointsPerMinute: CGFloat = 3.2

    private func clamped(_ minutes: Double) -> Double {
        min(Double(maximumMinutes), max(0, minutes))
    }

    private func drawScale(
        context: inout GraphicsContext,
        size: CGSize,
        magnification: CGFloat = 1,
        insideLens: Bool = false
    ) {
        let centerX = size.width / 2
        let minuteSpacing = pointsPerMinute * magnification
        let visibleMinuteCount = Int(ceil(size.width / minuteSpacing / 2)) + 2
        let firstMinute = max(1, Int(floor(visualMinutes)) - visibleMinuteCount)
        let lastMinute = min(maximumMinutes, Int(ceil(visualMinutes)) + visibleMinuteCount)

        guard firstMinute <= lastMinute else { return }

        for minute in firstMinute...lastMinute {
            let isMajor = minute.isMultiple(of: 5)
            let distanceFromSelection = abs(CGFloat(minute) - CGFloat(visualMinutes))
            let proximity = max(0, 1 - (distanceFromSelection / 5))
            let interactionScale: CGFloat = isDragging ? 1 : (isHovering ? 0.55 : 0)
            let x = centerX + (CGFloat(minute) - CGFloat(visualMinutes)) * minuteSpacing
            let baseHeight: CGFloat = isMajor ? 11 : 7
            let lensBoost: CGFloat = insideLens ? 3 : 0
            let height = baseHeight + lensBoost + (3 * proximity * interactionScale)
            let baseOpacity: Double = isMajor ? 0.38 : 0.22
            let lensOpacity: Double = insideLens ? 0.2 : 0
            let opacity = min(1, baseOpacity + lensOpacity + (0.28 * Double(proximity) * Double(interactionScale)))
            let isSelectedTick = insideLens && distanceFromSelection < 0.38

            var tick = Path()
            tick.move(to: CGPoint(x: x, y: (size.height - height) / 2))
            tick.addLine(to: CGPoint(x: x, y: (size.height + height) / 2))
            context.stroke(
                tick,
                with: .color(isSelectedTick ? accentColor : Color.primary.opacity(opacity)),
                lineWidth: isSelectedTick ? 2 : 1.5
            )
        }
    }

    var body: some View {
        GeometryReader { _ in
            ZStack {
                Canvas { context, size in
                    drawScale(context: &context, size: size)
                }

                Canvas { context, size in
                    drawScale(context: &context, size: size, magnification: 1.8, insideLens: true)
                }
                .frame(width: 34, height: 18)
                .background(.ultraThinMaterial, in: Capsule())
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(Color.primary.opacity(isDragging ? 0.18 : 0.1), lineWidth: 0.75)
                }
                .scaleEffect(isDragging ? 1.08 : (isHovering ? 1.04 : 1))
                .shadow(color: .black.opacity(isDragging ? 0.14 : 0.08), radius: isDragging ? 4 : 2, y: 1)

                Capsule()
                    .fill(accentColor)
                    .frame(width: 2, height: 15)
                    .scaleEffect(x: 1, y: isDragging ? 1.12 : (isHovering ? 1.06 : 1))
                    .shadow(color: accentColor.opacity(isDragging ? 0.55 : 0.35), radius: isDragging ? 3 : 2)
            }
            .animation(.easeOut(duration: 0.16), value: isHovering)
            .animation(.easeOut(duration: 0.12), value: isDragging)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if dragOriginMinutes == nil {
                            let origin = clamped(selectedMinutes)
                            dragOriginMinutes = origin
                            visualMinutes = origin
                            isDragging = true
                        }

                        guard let origin = dragOriginMinutes else { return }
                        let draggedMinutes = origin - Double(value.translation.width / pointsPerMinute)
                        visualMinutes = clamped(draggedMinutes)
                        selectedMinutes = clamped(draggedMinutes.rounded())
                    }
                    .onEnded { _ in
                        dragOriginMinutes = nil
                        isDragging = false
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                            visualMinutes = selectedMinutes
                        }
                    }
            )
            .onHover { isHovering in
                self.isHovering = isHovering
                if isHovering {
                    NSCursor.resizeLeftRight.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
            .onAppear {
                visualMinutes = clamped(selectedMinutes)
            }
            .onChange(of: selectedMinutes) { _, newValue in
                guard dragOriginMinutes == nil else { return }
                visualMinutes = clamped(newValue)
            }
            .accessibilityLabel("Timer duration")
            .accessibilityValue("\(Int(selectedMinutes)) minutes")
            .accessibilityHint("Drag the minute scale left or right to choose a duration")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    selectedMinutes = min(Double(maximumMinutes), selectedMinutes + 1)
                case .decrement:
                    selectedMinutes = max(0, selectedMinutes - 1)
                @unknown default:
                    break
                }
                visualMinutes = selectedMinutes
            }
        }
    }
}

struct ContentView: View {
    @Environment(TomatiModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme

    @State private var customMinutes: Double = 0

    private var isIdle: Bool { model.state == .idle }
    private var canStart: Bool { isIdle && customMinutes > 0 }
    private var maximumMinutes: Int { max(1, Int(model.maxCustomTime.rounded())) }

    private var timerForeground: Color {
        if model.state == .overtime { return .red }
        return model.progress > 0.72 ? model.timerAccentForegroundColor : .primary
    }

    private var controlForeground: Color {
        if model.state == .overtime { return .red }
        return model.progress > 0.23 ? model.timerAccentForegroundColor : .primary
    }

    private var timerShadowColor: Color {
        if model.progress > 0.72 { return model.timerAccentOpposingColor.opacity(0.32) }
        return colorScheme == .light ? .white.opacity(0.42) : .black.opacity(0.35)
    }

    private func startTimer(minutes: Double? = nil) {
        let duration = minutes ?? customMinutes
        guard duration > 0, isIdle else { return }

        withAnimation(.easeInOut(duration: 0.24)) {
            customMinutes = duration
            model.start(minutes: duration)
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            if isIdle {
                idleTimerControls
                .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            } else {
                if let sessionStatus = model.sessionStatusText {
                    Text(sessionStatus)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(timerForeground.opacity(0.88))
                        .lineLimit(1)
                        .frame(height: 12)
                        .transition(.opacity)
                }

                timerRow
                    .zIndex(1)
            }

            if isIdle {
                bottomBar
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, isIdle ? 10 : 10)
        .frame(width: 230)
        .fixedSize(horizontal: true, vertical: true)
        .background(timerProgressBackground)
        .animation(.easeInOut(duration: 0.24), value: model.state)
        .onChange(of: model.maxCustomTime) { _, newLimit in
            customMinutes = min(customMinutes, max(1, newLimit))
        }
        .focusable(false)
    }

    private var idleTimerControls: some View {
        VStack(spacing: 6) {
            Text(String(format: "%02d:00", Int(customMinutes)))
                .font(.system(size: 34, weight: .thin, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.62)
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.18), value: customMinutes)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityLabel("Selected duration")

            DraggableMinuteScale(
                maximumMinutes: maximumMinutes,
                accentColor: model.accentColor,
                selectedMinutes: $customMinutes
            )
            .frame(height: 18)

            Button {
                startTimer()
            } label: {
                GlassIcon(name: "play.fill", color: primaryControlColor, size: 31)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .disabled(!canStart)
            .help("Start timer")
        }
    }

    private var timerRow: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { model.toggle() }
                } label: {
                    GlassIcon(name: primaryControlIcon, color: primaryControlColor, size: 35)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help(primaryControlHelp)

                if model.state == .running || model.state == .paused {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            model.stop()
                        }
                    } label: {
                        GlassResetIcon(color: controlForeground)
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .help("Reset timer")
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }

            Spacer(minLength: 0)

            Text(model.timeString)
                .font(.system(size: 40, weight: .thin, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.62)
                .foregroundStyle(timerForeground)
                .shadow(
                    color: timerShadowColor,
                    radius: 1,
                    x: 0,
                    y: 1
                )
                .frame(minWidth: 132, maxWidth: .infinity, alignment: .trailing)
                .contentTransition(.numericText())
                .accessibilityLabel("Time remaining")
        }
        .frame(height: 50)
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            Menu {
                ForEach(Array(model.presets.enumerated()), id: \.offset) { _, preset in
                    Button {
                        startTimer(minutes: preset)
                    } label: {
                        Label("\(Int(preset)) minutes", systemImage: "play.fill")
                    }
                }
            } label: {
                GlassIcon(name: "circle.grid.2x2.fill", size: 28)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Quick presets")

            Spacer(minLength: 12)

            HStack(spacing: 6) {
                Menu {
                    if model.sessions.isEmpty {
                        Button("Create a Session…") {
                            model.settingsSelection = "Sessions"
                            NotificationCenter.default.post(name: .showTomatiSettings, object: nil)
                        }
                    } else {
                        ForEach(model.sessions) { session in
                            Button {
                                withAnimation(.easeInOut(duration: 0.24)) {
                                    model.start(session: session)
                                }
                            } label: {
                                Text("\(session.name.isEmpty ? "Untitled Session" : session.name) · \(session.intervalCount)×")
                            }
                        }

                        Divider()

                        Button("Manage Sessions…") {
                            model.settingsSelection = "Sessions"
                            NotificationCenter.default.post(name: .showTomatiSettings, object: nil)
                        }
                    }
                } label: {
                    GlassIcon(name: "rectangle.stack.fill", size: 28)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Start a session")

                Button {
                    model.settingsSelection = "General"
                    NotificationCenter.default.post(name: .showTomatiSettings, object: nil)
                } label: {
                    GlassIcon(name: "gearshape.fill", size: 28)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help("Settings")
            }
        }
        .frame(height: 28)
    }

    private var primaryControlIcon: String {
        switch model.state {
        case .idle, .paused: "play.fill"
        case .running: "pause.fill"
        case .overtime: "stop.fill"
        }
    }

    private var primaryControlColor: Color {
        if isIdle && !canStart { return .secondary.opacity(0.28) }
        return isIdle ? .primary : controlForeground
    }

    private var primaryControlHelp: String {
        switch model.state {
        case .idle: "Start timer"
        case .running: "Pause timer"
        case .paused: "Resume timer"
        case .overtime: "Stop alarm"
        }
    }

    private var timerProgressBackground: some View {
        GeometryReader { geometry in
            if !isIdle {
                model.timerAccentColor
                    .opacity(0.82)
                    .frame(width: geometry.size.width * CGFloat(model.progress))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(.linear(duration: 1), value: model.progress)
                    .transition(.opacity)
            }
        }
    }
}

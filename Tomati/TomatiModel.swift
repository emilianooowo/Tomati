import SwiftUI
import AVFoundation
import ServiceManagement

struct FocusSession: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var intervalCount: Int
    var focusMinutes: Double
    var breakMinutes: Double
    var accentRed: Double? = nil
    var accentGreen: Double? = nil
    var accentBlue: Double? = nil

    var accentColor: Color {
        Color(
            red: accentRed ?? 0.2,
            green: accentGreen ?? 0.48,
            blue: accentBlue ?? 0.95
        )
    }

    mutating func setAccentColor(_ color: Color) {
        guard let convertedColor = NSColor(color).usingColorSpace(.sRGB) else { return }
        accentRed = Double(convertedColor.redComponent)
        accentGreen = Double(convertedColor.greenComponent)
        accentBlue = Double(convertedColor.blueComponent)
    }
}

private enum TomatiDefaults {
    static let presets = [5.0, 15.0, 25.0, 50.0]
    static let alarmSound = "Ping"
    static let menuIcon = "tomato"
    static let maximumMinutes = 60.0
    static let accentRed = 232.0 / 255.0
    static let accentGreen = 74.0 / 255.0
    static let accentBlue = 60.0 / 255.0
}

@MainActor
@Observable
class TomatiModel {
    static let shared: TomatiModel = {
        #if DEBUG
        resetDebugPreferences()
        #endif
        return TomatiModel()
    }()

    enum TimerState { case idle, running, paused, overtime }
    enum SessionPhase { case focus, rest }

    private init() {}

    #if DEBUG
    private static func resetDebugPreferences() {
        let applicationKeys = [
            "presets",
            "focusSessions",
            "alarmSound",
            "menuIcon",
            "maxCustomTime",
            "accentColorR",
            "accentColorG",
            "accentColorB",
            "launchAtLogin",
            "showDockIcon"
        ]

        applicationKeys.forEach(UserDefaults.standard.removeObject(forKey:))

        if #available(macOS 13.0, *), SMAppService.mainApp.status == .enabled {
            try? SMAppService.mainApp.unregister()
        }
    }
    #endif

    
    var state: TimerState = .idle { didSet { updateMenuIcon() } }
    var timeRemaining: TimeInterval = 0
    var totalDuration: TimeInterval = 0
    var overtime: TimeInterval = 0
    var activeSession: FocusSession?
    var sessionPhase: SessionPhase?
    var currentSessionInterval: Int = 0
    var settingsSelection: String? = "General"
    
    private var audioPlayer: AVAudioPlayer?
    
    // Reemplazamos Timer con Task para cumplir con Swift 6
    private var timerTask: Task<Void, Never>?
    private var alarmTask: Task<Void, Never>?
    
    // MARK: - Ajustes Guardados
    var presets: [Double] = {
        guard let saved = UserDefaults.standard.array(forKey: "presets") as? [Double] else {
            return TomatiDefaults.presets
        }
        let validValues = saved.prefix(4).filter { $0.isFinite && $0 > 0 }
        if saved.isEmpty { return [] }
        return validValues.isEmpty ? TomatiDefaults.presets : Array(validValues)
    }() {
        didSet {
            let sanitizedValues = presets.prefix(4).map { $0.isFinite ? min(max($0, 1), 1_440) : 25 }
            if presets != sanitizedValues {
                presets = sanitizedValues
            }
            UserDefaults.standard.set(sanitizedValues, forKey: "presets")
        }
    }

    var sessions: [FocusSession] = {
        guard let data = UserDefaults.standard.data(forKey: "focusSessions"),
              let saved = try? JSONDecoder().decode([FocusSession].self, from: data) else {
            return []
        }
        return saved
    }() {
        didSet {
            let sanitizedSessions = sessions.map { session in
                FocusSession(
                    id: session.id,
                    name: session.name,
                    intervalCount: min(max(session.intervalCount, 1), 24),
                    focusMinutes: min(max(session.focusMinutes.isFinite ? session.focusMinutes : 30, 1), 1_440),
                    breakMinutes: min(max(session.breakMinutes.isFinite ? session.breakMinutes : 5, 1), 1_440),
                    accentRed: session.accentRed,
                    accentGreen: session.accentGreen,
                    accentBlue: session.accentBlue
                )
            }
            if sessions != sanitizedSessions {
                sessions = sanitizedSessions
            }
            if let data = try? JSONEncoder().encode(sanitizedSessions) {
                UserDefaults.standard.set(data, forKey: "focusSessions")
            }
        }
    }

    var alarmSound: String = UserDefaults.standard.string(forKey: "alarmSound") ?? TomatiDefaults.alarmSound {
        didSet { UserDefaults.standard.set(alarmSound, forKey: "alarmSound") }
    }
    
    var menuIcon: String = {
        let validIcons = ["hourglass", "circle", "tomato"]
        guard let savedIcon = UserDefaults.standard.string(forKey: "menuIcon"),
              validIcons.contains(savedIcon) else {
            return TomatiDefaults.menuIcon
        }
        return savedIcon
    }() {
        didSet {
            UserDefaults.standard.set(menuIcon, forKey: "menuIcon")
            updateMenuIcon()
        }
    }
    
    var maxCustomTime: Double = {
        let savedValue = UserDefaults.standard.double(forKey: "maxCustomTime")
        guard savedValue.isFinite, savedValue > 0 else { return TomatiDefaults.maximumMinutes }
        return min(savedValue, 1_440)
    }() {
        didSet {
            let sanitizedValue = maxCustomTime.isFinite
                ? min(max(maxCustomTime, 1), 1_440)
                : TomatiDefaults.maximumMinutes
            if maxCustomTime != sanitizedValue {
                maxCustomTime = sanitizedValue
            }
            UserDefaults.standard.set(sanitizedValue, forKey: "maxCustomTime")
        }
    }
    
    var accentColor: Color = {
        if UserDefaults.standard.object(forKey: "accentColorR") != nil {
            let r = UserDefaults.standard.double(forKey: "accentColorR")
            let g = UserDefaults.standard.double(forKey: "accentColorG")
            let b = UserDefaults.standard.double(forKey: "accentColorB")
            return Color(red: r, green: g, blue: b)
        }
        return Color(
            red: TomatiDefaults.accentRed,
            green: TomatiDefaults.accentGreen,
            blue: TomatiDefaults.accentBlue
        )
    }() {
        didSet {
            if let nsColor = NSColor(accentColor).usingColorSpace(.sRGB) {
                UserDefaults.standard.set(nsColor.redComponent, forKey: "accentColorR")
                UserDefaults.standard.set(nsColor.greenComponent, forKey: "accentColorG")
                UserDefaults.standard.set(nsColor.blueComponent, forKey: "accentColorB")
            }
        }
    }
    
    // MARK: - Startup & Dock
    var launchAtLogin: Bool = {
        if #available(macOS 13.0, *) {
            if SMAppService.mainApp.status == .enabled { return true }
        }
        return UserDefaults.standard.bool(forKey: "launchAtLogin")
    }() {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            if #available(macOS 13.0, *) {
                do {
                    if launchAtLogin {
                        if SMAppService.mainApp.status != .enabled {
                            try SMAppService.mainApp.register()
                        }
                    } else {
                        if SMAppService.mainApp.status == .enabled {
                            try SMAppService.mainApp.unregister()
                        }
                    }
                } catch {
                    print("Launch at login registration error: \(error)")
                }
            }
        }
    }

    var showDockIcon: Bool = UserDefaults.standard.bool(forKey: "showDockIcon") {
        didSet {
            UserDefaults.standard.set(showDockIcon, forKey: "showDockIcon")
            updateDockIconVisibility()
        }
    }

    func updateDockIconVisibility() {
        guard let app = NSApplication.shared as NSApplication? else { return }
        let targetPolicy: NSApplication.ActivationPolicy = showDockIcon ? .regular : .accessory
        if app.activationPolicy() != targetPolicy {
            app.setActivationPolicy(targetPolicy)
            if showDockIcon {
                app.activate(ignoringOtherApps: true)
            }
        }
    }

    func refreshLaunchAtLoginStatus() {
        if #available(macOS 13.0, *) {
            let isEnabled = SMAppService.mainApp.status == .enabled
            if launchAtLogin != isEnabled {
                launchAtLogin = isEnabled
            }
        }
    }

    // MARK: - Lógica Visual
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return min(1, max(0, timeRemaining / totalDuration))
    }

    var accentForegroundColor: Color {
        accentLuminance > 0.46 ? .black : .white
    }

    var accentOpposingColor: Color {
        accentLuminance > 0.46 ? .white : .black
    }

    private var accentLuminance: Double {
        luminance(of: accentColor)
    }

    var timerAccentColor: Color {
        activeSession?.accentColor ?? accentColor
    }

    var timerAccentForegroundColor: Color {
        luminance(of: timerAccentColor) > 0.46 ? .black : .white
    }

    var timerAccentOpposingColor: Color {
        luminance(of: timerAccentColor) > 0.46 ? .white : .black
    }

    private func luminance(of sourceColor: Color) -> Double {
        guard let color = NSColor(sourceColor).usingColorSpace(.sRGB) else { return 0 }

        func linearComponent(_ component: CGFloat) -> Double {
            let value = Double(component)
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * linearComponent(color.redComponent)
            + 0.7152 * linearComponent(color.greenComponent)
            + 0.0722 * linearComponent(color.blueComponent)
    }
    
    var timeString: String {
        if state == .overtime { return "+\(formatTime(overtime))" }
        return formatTime(timeRemaining)
    }

    var sessionStatusText: String? {
        guard let activeSession else { return nil }
        guard let sessionPhase else { return "\(displayName(for: activeSession)) · Complete" }
        let phaseName = sessionPhase == .focus ? "Focus" : "Break"
        return "\(displayName(for: activeSession)) · \(phaseName) \(currentSessionInterval)/\(activeSession.intervalCount)"
    }

    var sessionPhaseLabel: String? {
        guard let activeSession, let sessionPhase else { return nil }
        let currentPhase = sessionPhase == .focus ? "Focus" : "Break"
        guard state == .overtime else { return currentPhase }

        let nextPhase: String
        switch sessionPhase {
        case .focus:
            nextPhase = currentSessionInterval < activeSession.intervalCount ? "Break" : "Finish"
        case .rest:
            nextPhase = "Focus"
        }
        return "\(currentPhase) → \(nextPhase)"
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Controles
    func start(minutes: Double) {
        guard minutes.isFinite, minutes > 0 else { return }
        activeSession = nil
        sessionPhase = nil
        currentSessionInterval = 0
        prepareSegment(minutes: minutes)
        overtime = 0
        state = .running
        stopAudio()
        startTimer()
    }

    func start(session: FocusSession) {
        guard session.intervalCount > 0, session.focusMinutes > 0, session.breakMinutes > 0 else { return }
        stopAudio()
        activeSession = session
        sessionPhase = .focus
        currentSessionInterval = 1
        overtime = 0
        prepareSegment(minutes: session.focusMinutes)
        state = .running
        startTimer()
    }

    func addSession() {
        var session = FocusSession(name: "New Session", intervalCount: 3, focusMinutes: 30, breakMinutes: 5)
        session.setAccentColor(accentColor)
        sessions.append(session)
    }

    func removeSession(id: UUID) {
        sessions.removeAll { $0.id == id }
    }

    func addPreset(at slot: Int) {
        guard presets.count < 4 else { return }
        let suggestedValues = [5.0, 15.0, 25.0, 50.0]
        presets.append(suggestedValues[min(max(slot, 0), suggestedValues.count - 1)])
    }

    func removePreset(at index: Int) {
        guard presets.indices.contains(index) else { return }
        presets.remove(at: index)
    }

    func advanceToNextSessionPhase() {
        guard state == .overtime, let activeSession, let sessionPhase else { return }

        stopAudio()
        overtime = 0

        switch sessionPhase {
        case .focus:
            guard currentSessionInterval < activeSession.intervalCount else {
                stop()
                return
            }
            self.sessionPhase = .rest
            prepareSegment(minutes: activeSession.breakMinutes)
        case .rest:
            currentSessionInterval += 1
            self.sessionPhase = .focus
            prepareSegment(minutes: activeSession.focusMinutes)
        }

        state = .running
        startTimer()
    }
    
    func toggle() {
        switch state {
        case .running: state = .paused; timerTask?.cancel()
        case .paused: state = .running; startTimer()
        case .overtime: stop()
        case .idle: break
        }
    }
    
    func stop() {
        timerTask?.cancel()
        timerTask = nil
        state = .idle
        timeRemaining = 0
        totalDuration = 0
        overtime = 0
        activeSession = nil
        sessionPhase = nil
        currentSessionInterval = 0
        stopAudio()
    }
    
    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if !Task.isCancelled {
                    self.tick()
                }
            }
        }
    }
    
    private func tick() {
        if state == .running {
            if timeRemaining > 1 {
                timeRemaining -= 1
                updateMenuIcon()
            } else {
                timeRemaining = 0
                if activeSession != nil {
                    advanceSession()
                } else {
                    state = .overtime
                    playProgressiveAlarm()
                }
            }
        } else if state == .overtime {
            overtime += 1
        }
    }

    private func prepareSegment(minutes: Double) {
        totalDuration = minutes * 60
        timeRemaining = totalDuration
        updateMenuIcon()
    }

    private func advanceSession() {
        guard activeSession != nil, sessionPhase != nil else { return }
        overtime = 0
        state = .overtime
        playProgressiveAlarm()
    }

    private func displayName(for session: FocusSession) -> String {
        let trimmedName = session.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Untitled Session" : trimmedName
    }
    
    // MARK: - Alarma & Iconos
    private func updateMenuIcon() {
        NotificationCenter.default.post(name: NSNotification.Name("UpdateMenuIcon"), object: nil)
    }
    
    func playSoundPreview(name: String) { playSound(name: name, isPreview: true) }
    func playProgressiveAlarm() { playSound(name: alarmSound, isPreview: false) }
    
    private func playSound(name: String, isPreview: Bool) {
        let soundURL = URL(fileURLWithPath: "/System/Library/Sounds/\(name).aiff")
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            if isPreview {
                audioPlayer?.volume = 0.5
                audioPlayer?.play()
                return
            }
            audioPlayer?.volume = 0.1
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.play()
            
            // Reemplazamos el Timer de la alarma progresiva por un Task loop
            alarmTask?.cancel()
            alarmTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(2))
                    if !Task.isCancelled, self.state == .overtime, let player = self.audioPlayer {
                        if player.volume < 1.0 {
                            player.volume = min(1, player.volume + 0.15)
                        } else {
                            self.alarmTask?.cancel()
                        }
                    } else {
                        self.alarmTask?.cancel()
                    }
                }
            }
        } catch { print("Error reproduciendo \(name)") }
    }
    
    private func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        alarmTask?.cancel()
    }
}

import Foundation
import Observation

/// Manages the capture state machine and speech recognition lifecycle.
///
/// State transitions:
///   idle ──tap mic──▶ listening ──silence/stop──▶ (triggerSave=true) ──▶ saved
///   idle ──tap mic──▶ permissionDenied  (text input becomes primary)
///
/// Persisting the note is intentionally left to CaptureView, which holds the
/// SwiftData ModelContext. The ViewModel exposes `triggerSave` and `effectiveText`
/// for the view to act on.
@MainActor
@Observable
final class CaptureViewModel {

    // MARK: - State

    enum CaptureState: Equatable {
        case idle
        case listening
        case permissionDenied   // voice unavailable; text input is emphasised
        case saved
    }

    var captureState: CaptureState = .idle
    /// Live transcription result — updates as the user speaks.
    var liveTranscript: String = ""
    /// Text typed in the fallback input field.
    var inputText: String = ""
    /// View observes this to initiate the save + dismiss flow.
    var triggerSave: Bool = false
    
    private var hasTrackedStart: Bool = false

    // MARK: - Private

    private let speech = SpeechService()
    private var silenceTimer: Timer?
    private let silenceTimeout: TimeInterval = 2.5

    init() {
        speech.onTranscript = { [weak self] text in
            self?.liveTranscript = text
            self?.resetSilenceTimer()
        }
        speech.onError = { [weak self] in
            self?.fallbackToText()
        }
    }

    // MARK: - Mic interaction

    func tapMic() async {
        if !hasTrackedStart {
            AnalyticsService.shared.track(.capture_started, metadata: [AnalyticsMetadata.sourceType: "voice"])
            hasTrackedStart = true
        }
        switch captureState {
        case .listening:
            stopSpeech()
            if !liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                triggerSave = true
            } else {
                captureState = .idle
            }
        case .idle, .permissionDenied:
            await requestAndStart()
        case .saved:
            break
        }
    }

    private func requestAndStart() async {
        let micStatus = MicrophonePermissionService.status
        let speechStatus = SpeechPermissionService.status
        
        print("🎤 DEBUG: Mic status: \(micStatus), Speech status: \(speechStatus)")
        
        if micStatus.isDenied || speechStatus.isDenied {
            print("🎤 DEBUG: Permissions denied - Mic: \(micStatus.isDenied), Speech: \(speechStatus.isDenied)")
            captureState = .permissionDenied
            return
        }
        
        print("🎤 DEBUG: Requesting permissions...")
        let granted = await SpeechService.requestPermissions()
        print("🎤 DEBUG: Permissions granted: \(granted)")
        guard granted else {
            captureState = .permissionDenied
            return
        }
        do {
            print("🎤 DEBUG: Starting speech recognition...")
            try speech.start()
            captureState = .listening
            startSilenceTimer()
        } catch {
            print("🎤 DEBUG: Speech start failed: \(error)")
            fallbackToText()
        }
    }

    // MARK: - Effective text (voice takes priority over typed)

    var effectiveText: String {
        let voice = liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        let typed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        return voice.isEmpty ? typed : voice
    }

    var captureSourceType: NoteSourceType {
        liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? .manualText : .manualVoice
    }

    // MARK: - Post-save lifecycle

    func markSaved() {
        AnalyticsService.shared.track(.note_added, metadata: [AnalyticsMetadata.sourceType: captureSourceType.rawValue])
        stopSpeech()
        triggerSave = false
        captureState = .saved
    }

    func reset() {
        captureState = .idle
        liveTranscript = ""
        inputText = ""
        triggerSave = false
        hasTrackedStart = false
    }

    func cancel() {
        stopSpeech()
    }

    // MARK: - Silence timer

    private func startSilenceTimer() {
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleSilenceTimeout()
            }
        }
    }

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        startSilenceTimer()
    }

    private func handleSilenceTimeout() {
        guard captureState == .listening else { return }
        stopSpeech()
        if !liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            triggerSave = true
        } else {
            // Nothing transcribed — return to idle silently
            captureState = .idle
        }
    }

    // MARK: - Helpers

    private func stopSpeech() {
        silenceTimer?.invalidate()
        speech.stop()
        if captureState == .listening {
            captureState = .idle
        }
    }

    private func fallbackToText() {
        speech.stop()
        silenceTimer?.invalidate()
        captureState = .permissionDenied
    }
}

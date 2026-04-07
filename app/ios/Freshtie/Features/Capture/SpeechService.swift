import Foundation
import Speech
import AVFoundation

/// Minimal wrapper around SFSpeechRecognizer + AVAudioEngine.
///
/// Handles audio session setup, buffer feeding, and recognition task lifecycle.
/// The service is intentionally ignorant of UI state — CaptureViewModel drives behavior.
///
/// All callbacks fire on the main thread.
final class SpeechService {

    // MARK: - Callbacks

    /// Called with each partial transcription result.
    var onTranscript: ((String) -> Void)?
    /// Called on a recognition error (excludes cancellation / no-speech codes).
    var onError: (() -> Void)?

    // MARK: - Private

    private let recognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    // MARK: - Permissions

    /// Requests speech recognition + microphone authorization.
    /// Returns `true` only when both are granted.
    static func requestPermissions() async -> Bool {
        print("🎤 DEBUG: Requesting speech permission...")
        let speechGranted = await SpeechPermissionService.requestAccess()
        print("🎤 DEBUG: Speech granted: \(speechGranted)")
        guard speechGranted else { return false }

        print("🎤 DEBUG: Requesting microphone permission...")
        let micGranted = await MicrophonePermissionService.requestAccess()
        print("🎤 DEBUG: Microphone granted: \(micGranted)")
        return micGranted
    }

    // MARK: - Lifecycle

    /// Starts the audio engine and recognition task.
    /// Throws `SpeechError.unavailable` if the recognizer is unavailable.
    func start() throws {
        stop() // Ensure clean state

        guard let recognizer, recognizer.isAvailable else {
            throw SpeechError.unavailable
        }

        let session = AVAudioSession.sharedInstance()
        do {
            print("🎤 DEBUG: Setting audio session category...")
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            print("🎤 DEBUG: Activating audio session...")
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("🎤 DEBUG: Audio session setup failed: \(error)")
            throw error
        }

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        request = req

        // Pass nil so AVAudioEngine resolves the hardware format lazily at start
        // time, avoiding a crash when outputFormat returns 0 Hz before the engine
        // has initialised the audio unit.
        print("🎤 DEBUG: Installing audio tap...")
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buf, _ in
            self?.request?.append(buf)
        }

        print("🎤 DEBUG: Preparing audio engine...")
        audioEngine.prepare()
        print("🎤 DEBUG: Starting audio engine...")
        try audioEngine.start()

        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            DispatchQueue.main.async {
                if let text = result?.bestTranscription.formattedString, !text.isEmpty {
                    self?.onTranscript?(text)
                }
                if let error {
                    let nsError = error as NSError
                    print("🎤 DEBUG: Speech recognition error - Domain: \(nsError.domain), Code: \(nsError.code), Description: \(nsError.localizedDescription)")
                    // 203 = user cancelled, 216 = no speech, 301 = audio interrupted
                    if nsError.domain == "kAFAssistantErrorDomain" && (nsError.code == 203 || nsError.code == 216) {
                        print("🎤 DEBUG: Ignoring error code \(nsError.code) (user cancelled or no speech)")
                        return
                    }
                    if nsError.code != 301 {
                        print("🎤 DEBUG: Triggering onError callback for error code \(nsError.code)")
                        self?.onError?()
                    }
                }
            }
        }
    }

    /// Stops audio engine and cancels the recognition task cleanly.
    func stop() {
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)

        // Reset session category to avoid keeping the mic 'active' in the system status bar
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        try? session.setCategory(.ambient)
    }

    // MARK: - Error

    enum SpeechError: Error {
        case unavailable
    }
}

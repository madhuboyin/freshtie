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
        let speechGranted = await SpeechPermissionService.requestAccess()
        guard speechGranted else { return false }
        return await MicrophonePermissionService.requestAccess()
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
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        request = req

        // prepare() initialises the hardware and resolves the input node's format
        // before we read it — without this, outputFormat(forBus:) returns 0 Hz.
        audioEngine.prepare()

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let tapFormat: AVAudioFormat
        if inputFormat.sampleRate > 0 && inputFormat.channelCount > 0 {
            tapFormat = inputFormat
        } else {
            tapFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: tapFormat) { [weak self] buf, _ in
            self?.request?.append(buf)
        }

        try audioEngine.start()

        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            DispatchQueue.main.async {
                if let text = result?.bestTranscription.formattedString, !text.isEmpty {
                    self?.onTranscript?(text)
                }
                if let error {
                    let nsError = error as NSError
                    // 203 = user cancelled, 216 = no speech, 301 = audio interrupted
                    if nsError.domain == "kAFAssistantErrorDomain" && (nsError.code == 203 || nsError.code == 216) {
                        return
                    }
                    if nsError.code != 301 {
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
        // Must remove tap before the next installTap call; do NOT call
        // audioEngine.reset() — that destroys the node graph and causes a crash
        // the next time inputNode is accessed.
        audioEngine.inputNode.removeTap(onBus: 0)

        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        try? session.setCategory(.ambient)
    }

    // MARK: - Error

    enum SpeechError: Error {
        case unavailable
    }
}

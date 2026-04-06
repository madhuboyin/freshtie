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
        let speechStatus: SFSpeechRecognizerAuthorizationStatus = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        guard speechStatus == .authorized else { return false }

        return await withCheckedContinuation { cont in
            AVAudioSession.sharedInstance().requestRecordPermission { cont.resume(returning: $0) }
        }
    }

    // MARK: - Lifecycle

    /// Starts the audio engine and recognition task.
    /// Throws `SpeechError.unavailable` if the recognizer is unavailable.
    func start() throws {
        guard let recognizer, recognizer.isAvailable else {
            throw SpeechError.unavailable
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        request = req

        let inputNode = audioEngine.inputNode
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputNode.outputFormat(forBus: 0)) { [weak self] buf, _ in
            self?.request?.append(buf)
        }

        audioEngine.prepare()
        try audioEngine.start()

        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            DispatchQueue.main.async {
                if let text = result?.bestTranscription.formattedString, !text.isEmpty {
                    self?.onTranscript?(text)
                }
                if let error {
                    let code = (error as NSError).code
                    // 203 = request cancelled, 216 = no speech, 301 = audio interrupted
                    if code != 203 && code != 216 && code != 301 {
                        self?.onError?()
                    }
                }
            }
        }
    }

    /// Stops audio engine and cancels the recognition task cleanly.
    func stop() {
        request?.endAudio()
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        task?.cancel()
        task = nil
        request = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Error

    enum SpeechError: Error {
        case unavailable
    }
}

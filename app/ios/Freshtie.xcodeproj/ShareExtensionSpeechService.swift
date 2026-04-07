import Foundation
import Speech
import AVFoundation

/// Simplified speech service for Share Extension use.
/// Records audio and provides transcription without the complexity of the full SpeechService.
final class ShareExtensionSpeechService: ObservableObject {
    
    @Published var isRecording = false
    @Published var transcriptionText = ""
    @Published var hasPermissions = false
    
    private var audioRecorder: AVAudioRecorder?
    private var speechRecognizer = SFSpeechRecognizer()
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private var recordingURL: URL? {
        let documentsPath = FileManager.default.temporaryDirectory
        return documentsPath.appendingPathComponent("shareExtensionRecording.m4a")
    }
    
    // MARK: - Permissions
    
    func checkPermissions() async {
        let speechGranted = await SpeechPermissionService.requestAccess()
        let micGranted = await MicrophonePermissionService.requestAccess()
        
        await MainActor.run {
            hasPermissions = speechGranted && micGranted
        }
    }
    
    // MARK: - Recording
    
    func startRecording() {
        guard hasPermissions, !isRecording else { return }
        guard let url = recordingURL else { return }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("🔄 SHARE EXT: Audio session setup failed: \(error)")
            return
        }
        
        // Configure recorder
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            isRecording = true
            
            // Start speech recognition
            startSpeechRecognition(url: url)
            
            print("🔄 SHARE EXT: Recording started")
        } catch {
            print("🔄 SHARE EXT: Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() -> Data? {
        guard isRecording else { return nil }
        
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        
        // Stop speech recognition
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Reset audio session
        try? AVAudioSession.sharedInstance().setActive(false)
        
        print("🔄 SHARE EXT: Recording stopped")
        
        // Return audio data
        guard let url = recordingURL else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            // Clean up temp file
            try FileManager.default.removeItem(at: url)
            return data
        } catch {
            print("🔄 SHARE EXT: Failed to read recording: \(error)")
            return nil
        }
    }
    
    // MARK: - Speech Recognition
    
    private func startSpeechRecognition(url: URL) {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("🔄 SHARE EXT: Speech recognizer not available")
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = true
        
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.transcriptionText = result.bestTranscription.formattedString
                }
                
                if let error = error {
                    print("🔄 SHARE EXT: Speech recognition error: \(error)")
                }
            }
        }
    }
}
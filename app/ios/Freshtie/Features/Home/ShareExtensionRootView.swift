import SwiftUI
import Speech
import AVFoundation

/// Permission state enum for Share Extension
enum ShareExtensionPermissionState {
    case notDetermined, authorized, denied, restricted
}

/// Simple permission services for Share Extension
enum ShareExtensionSpeechPermission {
    static var status: ShareExtensionPermissionState {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }
    
    static func requestAccess() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}

enum ShareExtensionMicrophonePermission {
    static var status: ShareExtensionPermissionState {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: return .authorized
        case .denied: return .denied
        case .undetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }
    
    static func requestAccess() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}

/// Simple listening indicator for Share Extension
struct ShareExtensionListeningIndicator: View {
    @State private var isAnimating = false
    
    private static let barHeights: [CGFloat] = [14, 24, 36, 44, 38, 26, 42, 30]
    
    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<8, id: \.self) { i in
                Capsule()
                    .fill(AppColors.accent)
                    .frame(width: 3)
                    .frame(height: isAnimating ? Self.barHeights[i] : 6)
                    .animation(
                        .easeInOut(duration: 0.45)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear { isAnimating = true }
        .onDisappear { isAnimating = false }
    }
}

/// Simple speech recording service for Share Extension.
@MainActor
final class ShareExtensionSpeechService: ObservableObject {
    @Published var isRecording = false
    @Published var transcriptionText = ""
    @Published var hasPermissions = false
    
    private var audioRecorder: AVAudioRecorder?
    private var speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    
    private var recordingURL: URL? {
        let documentsPath = FileManager.default.temporaryDirectory
        return documentsPath.appendingPathComponent("shareExtensionRecording.m4a")
    }
    
    func checkPermissions() async {
        let speechGranted = await ShareExtensionSpeechPermission.requestAccess()
        let micGranted = await ShareExtensionMicrophonePermission.requestAccess()
        hasPermissions = speechGranted && micGranted
    }
    
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
        
        // Configure recorder settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            // Start file recording
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            
            // Start live speech recognition using audio engine
            try startLiveSpeechRecognition()
            
            isRecording = true
            print("🔄 SHARE EXT: Recording started")
        } catch {
            print("🔄 SHARE EXT: Failed to start recording: \(error)")
            cleanup()
        }
    }
    
    func stopRecording() -> Data? {
        guard isRecording else { return nil }
        
        // Stop everything
        audioRecorder?.stop()
        audioRecorder = nil
        
        stopLiveSpeechRecognition()
        
        isRecording = false
        
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
    
    // MARK: - Live Speech Recognition
    
    private func startLiveSpeechRecognition() throws {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw NSError(domain: "SpeechRecognition", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"])
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        // prepare() initialises the hardware so outputFormat returns a valid rate.
        audioEngine.prepare()
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let tapFormat: AVAudioFormat
        if inputFormat.sampleRate > 0 && inputFormat.channelCount > 0 {
            tapFormat = inputFormat
        } else {
            tapFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: tapFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        try audioEngine.start()

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.transcriptionText = result.bestTranscription.formattedString
                }
            }
        }
    }

    private func stopLiveSpeechRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        // Do NOT call audioEngine.reset() — it destroys the node graph and causes
        // a crash (inputNode == nullptr) the next time prepare()/start() is called.
        audioEngine.inputNode.removeTap(onBus: 0)
    }
    
    private func cleanup() {
        audioRecorder?.stop()
        audioRecorder = nil
        stopLiveSpeechRecognition()
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

struct ShareExtensionRootView: View {
    let displayName: String
    let onSave: (String, String?) -> Void // (noteText, audioFileName)
    let onCancel: () -> Void
    
    @State private var noteText: String = ""
    @State private var inputMode: InputMode = .text
    @State private var speechService = ShareExtensionSpeechService()
    @State private var showingPermissionDenied = false
    
    private enum InputMode {
        case text, voice
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Header
            HStack {
                Button("Cancel", action: onCancel)
                    .foregroundStyle(AppColors.secondaryLabel)
                
                Spacer()
                
                Text("Freshtie")
                    .font(AppTypography.headline)
                
                Spacer()
                
                Button("Add") {
                    saveContent()
                }
                .fontWeight(.bold)
                .foregroundStyle(AppColors.accent)
            }
            .padding(.bottom, AppSpacing.sm)
            
            // Content
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Say one thing")
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.label)
                Text("before you forget about \(displayName).")
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.secondaryLabel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Input mode picker
            Picker("Input Mode", selection: $inputMode) {
                Text("Type").tag(InputMode.text)
                Text("Voice").tag(InputMode.voice)
            }
            .pickerStyle(.segmented)
            
            // Input area based on mode
            Group {
                if inputMode == .text {
                    textInputSection
                } else {
                    voiceInputSection
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.background)
        .onAppear {
            Task {
                await speechService.checkPermissions()
            }
        }
        .alert("Microphone Access Required", isPresented: $showingPermissionDenied) {
            Button("Cancel", role: .cancel) { }
            Button("OK") { 
                // Note: Can't open Settings from Share Extension
                // User will need to go to Settings manually
            }
        } message: {
            Text("Freshtie needs access to your microphone to record voice notes. Please enable access in Settings > Freshtie.")
        }
    }
    
    // MARK: - Input Sections
    
    private var textInputSection: some View {
        TextField("Optional note...", text: $noteText, axis: .vertical)
            .font(AppTypography.body)
            .padding(AppSpacing.md)
            .background(AppColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .lineLimit(3...6)
    }
    
    private var voiceInputSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Transcription display
            if !speechService.transcriptionText.isEmpty {
                ScrollView {
                    Text(speechService.transcriptionText)
                        .font(AppTypography.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppSpacing.md)
                        .background(AppColors.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }
                .frame(maxHeight: 120)
            } else {
                Text("Tap to record a voice note")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.secondaryLabel)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(AppColors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            }
            
            // Recording button and indicator
            VStack(spacing: AppSpacing.sm) {
                if speechService.isRecording {
                    ShareExtensionListeningIndicator()
                        .frame(height: 50)
                }
                
                Button(action: toggleRecording) {
                    Image(systemName: speechService.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(speechService.isRecording ? Color.red : AppColors.accent)
                        .clipShape(Circle())
                }
                .disabled(!speechService.hasPermissions)
                
                Text(speechService.isRecording ? "Tap to stop" : "Tap to record")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondaryLabel)
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleRecording() {
        if !speechService.hasPermissions {
            showingPermissionDenied = true
            return
        }
        
        if speechService.isRecording {
            _ = speechService.stopRecording()
        } else {
            speechService.startRecording()
        }
    }
    
    private func saveContent() {
        if inputMode == .voice && speechService.isRecording {
            // Stop recording and get audio data
            if let audioData = speechService.stopRecording(),
               let fileName = ShareExtensionStore.saveAudioData(audioData) {
                onSave(speechService.transcriptionText, fileName)
            } else {
                onSave(speechService.transcriptionText, nil)
            }
        } else if inputMode == .voice && !speechService.transcriptionText.isEmpty {
            // Use transcribed text without new recording
            onSave(speechService.transcriptionText, nil)
        } else {
            // Text mode
            onSave(noteText, nil)
        }
    }
}

#Preview {
    ShareExtensionRootView(
        displayName: "John Doe",
        onSave: { _, _ in },
        onCancel: { }
    )
}
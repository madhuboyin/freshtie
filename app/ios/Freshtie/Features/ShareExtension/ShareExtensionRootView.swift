import SwiftUI
import Speech
import AVFoundation

/// Simple speech recording service for Share Extension.
@MainActor
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
    
    func checkPermissions() async {
        let speechGranted = await SpeechPermissionService.requestAccess()
        let micGranted = await MicrophonePermissionService.requestAccess()
        hasPermissions = speechGranted && micGranted
    }
    
    func startRecording() {
        guard hasPermissions, !isRecording else { return }
        guard let url = recordingURL else { return }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("🔄 SHARE EXT: Audio session setup failed: \(error)")
            return
        }
        
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
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        try? AVAudioSession.sharedInstance().setActive(false)
        
        guard let url = recordingURL else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            try FileManager.default.removeItem(at: url)
            return data
        } catch {
            print("🔄 SHARE EXT: Failed to read recording: \(error)")
            return nil
        }
    }
    
    private func startSpeechRecognition(url: URL) {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else { return }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = true
        
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
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
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
        } message: {
            Text("Freshtie needs access to your microphone to record voice notes. Please enable access in Settings.")
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
                    ListeningIndicator()
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
            speechService.stopRecording()
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

import SwiftUI

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

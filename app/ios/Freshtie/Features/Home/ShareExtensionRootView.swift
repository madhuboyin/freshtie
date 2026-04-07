import SwiftUI
import AVFoundation

/// Root UI for the FreshtieShare extension.
///
/// Supports text notes and basic voice recording.
/// Audio files are stored in the shared App Group container.
struct ShareExtensionRootView: View {
    let displayName: String
    let onSave: (String, String?) -> Void  // (noteText, audioFileName)
    let onCancel: () -> Void

    @State private var noteText: String = ""
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordedAudioFileName: String?
    @State private var recordingDuration: TimeInterval = 0
    @State private var timer: Timer?

    private let appGroupId = "group.com.madhuboyin.Freshtie"

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
                    onSave(noteText, recordedAudioFileName)
                }
                .fontWeight(.bold)
                .foregroundStyle(AppColors.accent)
                .disabled(isRecording) // Don't allow saving while recording
            }
            .padding(.bottom, AppSpacing.sm)

            // Prompt copy
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("One thing to remember")
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.label)
                Text("about \(displayName).")
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.secondaryLabel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Text input
            TextField(isRecording ? "Listening..." : "Optional note…", text: $noteText, axis: .vertical)
                .font(AppTypography.body)
                .padding(AppSpacing.md)
                .background(AppColors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .lineLimit(3...6)
                .disabled(isRecording)

            Spacer()

            // Voice Capture Section
            VStack(spacing: AppSpacing.md) {
                if isRecording {
                    Text(formatDuration(recordingDuration))
                        .font(AppTypography.headline)
                        .monospacedDigit()
                        .foregroundStyle(AppColors.accent)
                } else if recordedAudioFileName != nil {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Voice captured")
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppColors.secondaryLabel)
                        
                        Button("Remove") {
                            deleteRecording()
                        }
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.accent)
                        .padding(.leading, AppSpacing.sm)
                    }
                }

                MicrophoneButton(isListening: isRecording) {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }
            }
            .padding(.bottom, AppSpacing.xl)
        }
        .padding(AppSpacing.md)
        .background(AppColors.background)
        .onDisappear {
            stopRecording()
        }
    }

    // MARK: - Recording Logic

    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        
        Task {
            let granted = await withCheckedContinuation { continuation in
                session.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
            
            guard granted else {
                print("🔄 SHARE EXT: Microphone permission denied")
                return
            }
            
            await MainActor.run {
                do {
                    try session.setCategory(.playAndRecord, mode: .default)
                    try session.setActive(true)
                    
                    let sharedContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
                    guard let containerURL = sharedContainer else {
                        print("🔄 SHARE EXT: Shared container not found")
                        return
                    }
                    
                    let fileName = "audio_\(UUID().uuidString).m4a"
                    let fileURL = containerURL.appendingPathComponent(fileName)
                    
                    let settings: [String: Any] = [
                        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 12000,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                    ]
                    
                    audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
                    audioRecorder?.record()
                    
                    isRecording = true
                    recordedAudioFileName = fileName
                    recordingDuration = 0
                    
                    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                        recordingDuration += 1
                    }
                    
                } catch {
                    print("🔄 SHARE EXT: Failed to start recording: \(error)")
                }
            }
        }
    }

    private func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        timer?.invalidate()
        timer = nil
        
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    private func deleteRecording() {
        guard let fileName = recordedAudioFileName else { return }
        
        let sharedContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
        if let fileURL = sharedContainer?.appendingPathComponent(fileName) {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        recordedAudioFileName = nil
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Minimal implementation of MicrophoneButton if not shared, 
// but we already have it in DesignSystem/Components or Capture/Components.
// Since this is a different target, we need to ensure it's included in FreshtieShare sources.

#Preview {
    ShareExtensionRootView(
        displayName: "John Doe",
        onSave: { _, _ in },
        onCancel: { }
    )
}

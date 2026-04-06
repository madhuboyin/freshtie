import SwiftUI

/// Single-line text input — always visible as a voice-capture fallback.
/// A send button appears when the field has non-empty content.
struct TextInputField: View {
    @Binding var text: String
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            TextField("Or type something…", text: $text)
                .font(AppTypography.body)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm + AppSpacing.xs)
                .background(AppColors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .submitLabel(.done)
                .onSubmit {
                    if !text.trimmingCharacters(in: .whitespaces).isEmpty { onSubmit() }
                }

            if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                Button(action: onSubmit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(AppColors.accent)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: text.isEmpty)
    }
}

// MARK: - Preview

#Preview {
    TextInputField(text: .constant("Going to Japan next month")) { }
        .padding()
}

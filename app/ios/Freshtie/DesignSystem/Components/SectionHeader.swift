import SwiftUI

/// Small-caps section label used above lists and grouped content.
struct SectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(AppTypography.caption)
            .fontWeight(.semibold)
            .foregroundStyle(AppColors.secondaryLabel)
            .kerning(0.4)
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: AppSpacing.sm) {
        SectionHeader("Recent")
        SectionHeader("Try asking")
        SectionHeader("Last time")
    }
    .padding()
}

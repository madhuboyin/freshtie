import SwiftUI

/// Centralised colour tokens for Freshtie.
/// All views should reference these rather than calling system colours directly.
enum AppColors {

    // MARK: Backgrounds
    static let background               = Color(.systemBackground)
    static let secondaryBackground      = Color(.secondarySystemBackground)
    static let groupedBackground        = Color(.systemGroupedBackground)

    // MARK: Text
    static let label                    = Color(.label)
    static let secondaryLabel           = Color(.secondaryLabel)
    static let tertiaryLabel            = Color(.tertiaryLabel)

    // MARK: Structural
    static let separator                = Color(.separator)

    // MARK: Accent — calm indigo used sparingly
    static let accent: Color            = .indigo

    // MARK: Prompt chips
    static let chipBackground           = Color.indigo.opacity(0.07)
    static let chipBorder               = Color.indigo.opacity(0.18)
    static let chipLabel                = Color.indigo

    // MARK: Avatar
    static let avatarBackground         = Color.indigo.opacity(0.10)
    static let avatarLabel              = Color.indigo
}

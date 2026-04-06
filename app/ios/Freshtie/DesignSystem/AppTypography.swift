import SwiftUI

/// Type-scale tokens used across the app.
/// Adjust weights or designs here to restyle globally.
enum AppTypography {

    // MARK: Display
    static let largeTitle  = Font.system(.largeTitle,  design: .default, weight: .bold)
    static let title       = Font.system(.title,       design: .default, weight: .semibold)
    static let title2      = Font.system(.title2,      design: .default, weight: .semibold)
    static let title3      = Font.system(.title3,      design: .default, weight: .semibold)

    // MARK: Body
    static let headline    = Font.system(.headline)
    static let body        = Font.system(.body)
    static let callout     = Font.system(.callout)
    static let subheadline = Font.system(.subheadline)

    // MARK: Small
    static let footnote    = Font.system(.footnote)
    static let caption     = Font.system(.caption)
}

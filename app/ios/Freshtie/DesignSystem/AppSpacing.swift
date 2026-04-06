import SwiftUI

/// Spacing scale — all layout padding/gap values come from here.
enum AppSpacing {
    static let xxs: CGFloat = 2
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48
}

/// Corner-radius scale.
enum AppRadius {
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
}

/// Fixed-size tokens for common UI elements.
enum AppSize {
    static let avatarMD:     CGFloat = 40
    static let avatarLG:     CGFloat = 52
    static let minTapTarget: CGFloat = 44
}

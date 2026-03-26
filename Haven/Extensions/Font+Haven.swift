import SwiftUI

extension Font {
    // UI Fonts — scale with Dynamic Type
    static let havenHeadline = Font.headline
    static let havenBody = Font.body
    static let havenCaption = Font.caption

    // Content Fonts — serif, scale with Dynamic Type
    static let havenContentTitle = Font.system(.title, design: .serif).weight(.semibold)
    static let havenContentBody = Font.system(.body, design: .serif)
    static let havenContentH2 = Font.system(.title3, design: .serif).weight(.semibold)

    // For custom sizing that still scales
    static func havenUI(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .default).weight(weight)
    }

    static func havenContent(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .serif).weight(weight)
    }
}

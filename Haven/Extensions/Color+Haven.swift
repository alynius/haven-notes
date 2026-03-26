import SwiftUI

extension Color {
    // MARK: - Brand Colors
    static let havenPrimary = Color(red: 0x8B / 255.0, green: 0x6F / 255.0, blue: 0x47 / 255.0)       // #8B6F47
    static let havenSecondary = Color(red: 0xC9 / 255.0, green: 0xB5 / 255.0, blue: 0x9A / 255.0)     // #C9B59A
    static let havenAccent = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0x7B / 255.0, green: 0xAF / 255.0, blue: 0xA2 / 255.0, alpha: 1) // #7BAFA2
            : UIColor(red: 0x6B / 255.0, green: 0x9B / 255.0, blue: 0x8E / 255.0, alpha: 1) // #6B9B8E
    })

    // MARK: - Backgrounds
    static let havenBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0x16 / 255.0, green: 0x15 / 255.0, blue: 0x12 / 255.0, alpha: 1) // #161512
            : UIColor(red: 0xFE / 255.0, green: 0xFD / 255.0, blue: 0xFB / 255.0, alpha: 1) // #FEFDFB
    })

    static let havenSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0x25 / 255.0, green: 0x20 / 255.0, blue: 0x18 / 255.0, alpha: 1) // #252018
            : UIColor(red: 0xFA / 255.0, green: 0xF7 / 255.0, blue: 0xF3 / 255.0, alpha: 1) // #FAF7F3
    })

    // MARK: - Text
    static let havenTextPrimary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0xFA / 255.0, green: 0xF7 / 255.0, blue: 0xF3 / 255.0, alpha: 1) // #FAF7F3
            : UIColor(red: 0x1A / 255.0, green: 0x18 / 255.0, blue: 0x15 / 255.0, alpha: 1) // #1A1815
    })

    static let havenTextSecondary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0xA8 / 255.0, green: 0x9E / 255.0, blue: 0x94 / 255.0, alpha: 1) // #A89E94
            : UIColor(red: 0x6B / 255.0, green: 0x65 / 255.0, blue: 0x60 / 255.0, alpha: 1) // #6B6560
    })

    // MARK: - Borders
    static let havenBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0x3D / 255.0, green: 0x37 / 255.0, blue: 0x30 / 255.0, alpha: 1) // #3D3730
            : UIColor(red: 0xE8 / 255.0, green: 0xE2 / 255.0, blue: 0xDA / 255.0, alpha: 1) // #E8E2DA
    })
}

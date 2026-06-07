import SwiftUI

enum ColorPalette {

    // MARK: - Brand Greens
    static let primaryGreen     = Color(hex: "#1ED760")
    static let deepGreen        = Color(hex: "#17A84A")
    static let lightGreen       = Color(hex: "#4AF780")
    static let mutedGreen       = Color(hex: "#1AA34A")

    // MARK: - Backgrounds
    static let backgroundBlack  = Color(hex: "#000000")
    static let surfaceDark      = Color(hex: "#0A0A0A")
    static let surface          = Color(hex: "#121212")
    static let surface2         = Color(hex: "#1A1A1A")
    static let surface3         = Color(hex: "#282828")
    static let surface4         = Color(hex: "#333333")
    static let elevated         = Color(hex: "#3E3E3E")

    // MARK: - Text
    static let textPrimary      = Color(hex: "#FFFFFF")
    static let textSecondary    = Color(hex: "#B3B3B3")
    static let textTertiary     = Color(hex: "#727272")
    static let textDisabled     = Color(hex: "#535353")

    // MARK: - Accents
    static let accentGreen      = primaryGreen
    static let accentGreenDim   = Color(hex: "#1ED76040")
    static let warningYellow    = Color(hex: "#F5A623")
    static let errorRed         = Color(hex: "#E53935")
    static let infoBlue         = Color(hex: "#2196F3")

    // MARK: - Genre Colors
    static let genrePop         = Color(hex: "#E91E63")
    static let genreRock        = Color(hex: "#FF5722")
    static let genreHipHop      = Color(hex: "#9C27B0")
    static let genreElectronic  = Color(hex: "#00BCD4")
    static let genreJazz        = Color(hex: "#FF9800")
    static let genreClassical   = Color(hex: "#607D8B")
    static let genreRnB         = Color(hex: "#F44336")
    static let genreCountry     = Color(hex: "#8BC34A")
    static let genreReggae      = Color(hex: "#FFEB3B")
    static let genreMetal       = Color(hex: "#424242")
    static let genreFolk        = Color(hex: "#795548")
    static let genreLatino      = Color(hex: "#FF4081")
    static let genreSoul        = Color(hex: "#673AB7")
    static let genrePunk        = Color(hex: "#F50057")
    static let genreIndie       = Color(hex: "#00E5FF")
    static let genreBlues       = Color(hex: "#1565C0")

    // MARK: - Glass
    static let glassFill        = Color.white.opacity(0.07)
    static let glassBorder      = Color.white.opacity(0.12)
    static let glassShadow      = Color.black.opacity(0.4)

    // MARK: - Light Theme
    enum Light {
        static let background   = Color(hex: "#F5F5F5")
        static let surface      = Color(hex: "#FFFFFF")
        static let surface2     = Color(hex: "#EFEFEF")
        static let textPrimary  = Color(hex: "#191414")
        static let textSecondary = Color(hex: "#6E6E6E")
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")))
        var hexNumber: UInt64 = 0
        scanner.scanHexInt64(&hexNumber)
        let r = Double((hexNumber & 0xFF000000) >> 24) / 255
        let g = Double((hexNumber & 0x00FF0000) >> 16) / 255
        let b = Double((hexNumber & 0x0000FF00) >>  8) / 255
        let a = Double( hexNumber & 0x000000FF       ) / 255
        if hex.count == 8 || hex.count == 9 {
            self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
        } else {
            let r2 = Double((hexNumber & 0xFF0000) >> 16) / 255
            let g2 = Double((hexNumber & 0x00FF00) >>  8) / 255
            let b2 = Double( hexNumber & 0x0000FF       ) / 255
            self.init(.sRGB, red: r2, green: g2, blue: b2, opacity: 1)
        }
    }

    var hex: String {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

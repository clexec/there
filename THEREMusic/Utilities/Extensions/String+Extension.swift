import Foundation

// MARK: - String Extensions
extension String {

    var isValidEmail: Bool {
        let regex = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: self)
    }

    var isValidPassword: Bool {
        return count >= AppConstants.Auth.minPasswordLength
            && hasUppercase
            && hasLowercase
            && hasDigit
    }

    var hasUppercase: Bool { rangeOfCharacter(from: .uppercaseLetters) != nil }
    var hasLowercase: Bool { rangeOfCharacter(from: .lowercaseLetters) != nil }
    var hasDigit: Bool     { rangeOfCharacter(from: .decimalDigits) != nil }
    var hasSpecialChar: Bool {
        let special = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;':\",./<>?")
        return rangeOfCharacter(from: special) != nil
    }

    var passwordStrength: PasswordStrength {
        var score = 0
        if count >= 8   { score += 1 }
        if count >= 12  { score += 1 }
        if hasUppercase { score += 1 }
        if hasLowercase { score += 1 }
        if hasDigit     { score += 1 }
        if hasSpecialChar { score += 2 }
        switch score {
        case 0...2: return .weak
        case 3...4: return .medium
        default:    return .strong
        }
    }

    func truncated(to length: Int, trailing: String = "...") -> String {
        guard count > length else { return self }
        return String(prefix(length)) + trailing
    }

    var initials: String {
        let parts = components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(prefix(2)).uppercased()
    }

    func localized(_ args: CVarArg...) -> String {
        let format = NSLocalizedString(self, comment: "")
        return args.isEmpty ? format : String(format: format, arguments: args)
    }

    var containsEmoji: Bool {
        unicodeScalars.contains { $0.properties.isEmoji }
    }

    var wordCount: Int {
        components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }

    func highlighted(query: String) -> AttributedString {
        var attributed = AttributedString(self)
        let lower = lowercased()
        let queryLower = query.lowercased()
        var searchRange = lower.startIndex..<lower.endIndex
        while let range = lower.range(of: queryLower, range: searchRange) {
            let attributedRange = AttributedString.Index(range.lowerBound, within: attributed)!
                ..<AttributedString.Index(range.upperBound, within: attributed)!
            attributed[attributedRange].foregroundColor = .green
            attributed[attributedRange].font = .bold(.body)()
            searchRange = range.upperBound..<lower.endIndex
        }
        return attributed
    }
}

// MARK: - PasswordStrength
enum PasswordStrength {
    case weak, medium, strong

    var title: String {
        switch self {
        case .weak:   return NSLocalizedString("password_weak", comment: "")
        case .medium: return NSLocalizedString("password_medium", comment: "")
        case .strong: return NSLocalizedString("password_strong", comment: "")
        }
    }

    var progress: Double {
        switch self {
        case .weak:   return 0.33
        case .medium: return 0.66
        case .strong: return 1.0
        }
    }

    var color: String {
        switch self {
        case .weak:   return "#E53935"
        case .medium: return "#F5A623"
        case .strong: return "#1ED760"
        }
    }
}

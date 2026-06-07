import SwiftUI

enum UIConstants {

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat   = 4
        static let sm: CGFloat   = 8
        static let md: CGFloat   = 12
        static let base: CGFloat = 16
        static let lg: CGFloat   = 20
        static let xl: CGFloat   = 24
        static let xxl: CGFloat  = 32
        static let xxxl: CGFloat = 48
        static let huge: CGFloat = 64
    }

    // MARK: - Font Sizes
    enum FontSize {
        static let caption2: CGFloat = 10
        static let caption: CGFloat  = 12
        static let footnote: CGFloat = 13
        static let subheadline: CGFloat = 15
        static let body: CGFloat     = 16
        static let callout: CGFloat  = 17
        static let title3: CGFloat   = 20
        static let title2: CGFloat   = 22
        static let title: CGFloat    = 28
        static let largeTitle: CGFloat = 34
    }

    // MARK: - Icon Sizes
    enum IconSize {
        static let xs: CGFloat    = 12
        static let sm: CGFloat    = 16
        static let md: CGFloat    = 20
        static let base: CGFloat  = 24
        static let lg: CGFloat    = 28
        static let xl: CGFloat    = 32
        static let xxl: CGFloat   = 40
        static let xxxl: CGFloat  = 48
        static let huge: CGFloat  = 56
    }

    // MARK: - Corner Radii
    enum Radius {
        static let xs: CGFloat    = 4
        static let sm: CGFloat    = 6
        static let md: CGFloat    = 10
        static let base: CGFloat  = 12
        static let lg: CGFloat    = 16
        static let xl: CGFloat    = 20
        static let xxl: CGFloat   = 28
        static let pill: CGFloat  = 999
    }

    // MARK: - Avatar Sizes
    enum Avatar {
        static let small: CGFloat  = 32
        static let medium: CGFloat = 48
        static let large: CGFloat  = 72
        static let xlarge: CGFloat = 96
    }

    // MARK: - Card Dimensions
    enum Card {
        static let smallWidth: CGFloat   = 130
        static let smallHeight: CGFloat  = 130
        static let mediumWidth: CGFloat  = 160
        static let mediumHeight: CGFloat = 160
        static let largeWidth: CGFloat   = 200
        static let largeHeight: CGFloat  = 200
        static let horizontalHeight: CGFloat = 64
    }

    // MARK: - Tab Bar
    enum TabBar {
        static let height: CGFloat       = 82
        static let iconSize: CGFloat     = 24
        static let labelFontSize: CGFloat = 10
    }

    // MARK: - Mini Player
    enum MiniPlayer {
        static let height: CGFloat       = 64
        static let artworkSize: CGFloat  = 44
        static let cornerRadius: CGFloat = 14
        static let bottomPadding: CGFloat = 90
    }

    // MARK: - Full Player
    enum FullPlayer {
        static let artworkSize: CGFloat  = UIScreen.main.bounds.width - 48
        static let controlsSpacing: CGFloat = 20
        static let progressHeight: CGFloat  = 4
        static let volumeHeight: CGFloat    = 4
    }

    // MARK: - Search
    enum SearchBar {
        static let height: CGFloat       = 44
        static let cornerRadius: CGFloat = 10
        static let iconSize: CGFloat     = 18
    }

    // MARK: - Grid
    enum Grid {
        static let genreColumns: Int     = 2
        static let genreItemHeight: CGFloat = 100
        static let searchColumns: Int    = 2
    }

    // MARK: - Animation
    enum Animation {
        static let fast                  = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let medium                = SwiftUI.Animation.easeInOut(duration: 0.35)
        static let slow                  = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring                = SwiftUI.Animation.spring(response: 0.45, dampingFraction: 0.8)
        static let springBouncy          = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let interactiveSpring     = SwiftUI.Animation.interactiveSpring(response: 0.3, dampingFraction: 0.8)
    }
}

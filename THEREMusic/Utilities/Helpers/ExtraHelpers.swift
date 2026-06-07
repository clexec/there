import SwiftUI
import Combine

// MARK: - FavoritesViewModel
@MainActor
final class FavoritesViewModel: ObservableObject {

    @Published var likedTracks: [Track] = []
    @Published var sortOption: SortOption = .dateAdded
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false

    private let libraryManager: LibraryManager
    private var cancellables = Set<AnyCancellable>()

    init(libraryManager: LibraryManager = .shared) {
        self.libraryManager = libraryManager
        bind()
    }

    var filteredTracks: [Track] {
        let sorted = sort(libraryManager.likedTracks)
        if searchQuery.isEmpty { return sorted }
        return sorted.filter {
            $0.title.localizedCaseInsensitiveContains(searchQuery) ||
            $0.artistName.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    private func sort(_ tracks: [Track]) -> [Track] {
        switch sortOption {
        case .title, .alphabetical: return tracks.sorted { $0.title < $1.title }
        case .artist:               return tracks.sorted { $0.artistName < $1.artistName }
        case .duration:             return tracks.sorted { $0.durationMs > $1.durationMs }
        case .recentlyPlayed:       return tracks.sorted { ($0.lastPlayedAt ?? .distantPast) > ($1.lastPlayedAt ?? .distantPast) }
        default:                    return tracks
        }
    }

    func toggleLike(_ track: Track) async {
        await libraryManager.toggleLike(track: track)
    }

    func isLiked(_ track: Track) -> Bool { libraryManager.isLiked(track) }

    private func bind() {
        libraryManager.$likedTracks
            .receive(on: DispatchQueue.main)
            .assign(to: \.likedTracks, on: self)
            .store(in: &cancellables)
    }
}

// MARK: - RecommendationViewModel
@MainActor
final class RecommendationViewModel: ObservableObject {

    @Published var sections: [Recommendation] = []
    @Published var isLoading: Bool = false
    @Published var error: String?

    private let apiService: ITunesAPIService

    init(apiService: ITunesAPIService = .shared) {
        self.apiService = apiService
    }

    func loadBasedOn(track: Track) async {
        isLoading = true
        do {
            let related = try await apiService.fetchRecommendations(basedOn: track)
            let recommendation = Recommendation(
                section: .recommended,
                title: String(format: NSLocalizedString("section_recommended", comment: ""), track.artistName),
                tracks: related
            )
            sections = [recommendation]
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - HistoryViewModel
@MainActor
final class HistoryViewModel: ObservableObject {

    @Published var recentlyPlayed: [Track] = []
    @Published var isLoading: Bool = false

    private let libraryManager: LibraryManager
    private var cancellables = Set<AnyCancellable>()

    init(libraryManager: LibraryManager = .shared) {
        self.libraryManager = libraryManager
        bind()
    }

    func clearHistory() async {
        await libraryManager.clearHistory()
    }

    private func bind() {
        libraryManager.$recentlyPlayed
            .receive(on: DispatchQueue.main)
            .assign(to: \.recentlyPlayed, on: self)
            .store(in: &cancellables)
    }
}

// MARK: - Image+Extension
import UIKit

extension UIImage {
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }

    func resized(to size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in draw(in: CGRect(origin: .zero, size: size)) }
    }
}

// MARK: - DynamicBackgroundView
struct DynamicBackgroundView: View {
    let artworkURL: URL?
    @State private var dominantColor: Color = ColorPalette.backgroundBlack

    var body: some View {
        ZStack {
            dominantColor.ignoresSafeArea()
            LinearGradient(
                colors: [dominantColor.opacity(0.8), ColorPalette.backgroundBlack],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()
        }
        .task {
            guard let url = artworkURL,
                  let image = try? await ImageCacheService.shared.downloadImage(from: url),
                  let avg = image.averageColor else { return }
            withAnimation(UIConstants.Animation.slow) {
                dominantColor = Color(avg)
            }
        }
    }
}

// MARK: - LoadingView
struct LoadingView: View {
    var message: String = ""

    var body: some View {
        VStack(spacing: UIConstants.Spacing.base) {
            ProgressView()
                .tint(ColorPalette.primaryGreen)
                .scaleEffect(1.3)
            if !message.isEmpty {
                Text(message)
                    .font(.system(size: UIConstants.FontSize.footnote))
                    .foregroundStyle(ColorPalette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.backgroundBlack.opacity(0.7))
    }
}

// MARK: - EmptyStateView
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: UIConstants.Spacing.base) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(ColorPalette.textTertiary)
            VStack(spacing: UIConstants.Spacing.xs) {
                Text(title)
                    .font(.system(size: UIConstants.FontSize.title3, weight: .bold))
                    .foregroundStyle(ColorPalette.textPrimary)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.system(size: UIConstants.FontSize.body))
                    .foregroundStyle(ColorPalette.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .primaryButtonStyle()
                }
                .frame(width: 200)
                .scaleOnPress()
                .padding(.top, UIConstants.Spacing.sm)
            }
        }
        .padding(.horizontal, UIConstants.Spacing.xxl)
    }
}

// MARK: - GlassEffectView
struct GlassEffectView: View {
    var cornerRadius: CGFloat = UIConstants.Radius.lg
    var opacity: Double = 0.07
    var borderOpacity: Double = 0.12

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(borderOpacity), lineWidth: 0.5)
            }
    }
}

// MARK: - PulseAnimation
struct PulseAnimation: ViewModifier {
    @State private var isAnimating = false
    let color: Color
    let duration: Double

    func body(content: Content) -> some View {
        content
            .overlay {
                Circle()
                    .stroke(color.opacity(isAnimating ? 0 : 0.6), lineWidth: 2)
                    .scaleEffect(isAnimating ? 2 : 1)
                    .opacity(isAnimating ? 0 : 1)
                    .animation(.easeOut(duration: duration).repeatForever(autoreverses: false), value: isAnimating)
            }
            .onAppear { isAnimating = true }
    }
}

extension View {
    func pulse(color: Color = ColorPalette.primaryGreen, duration: Double = 1.5) -> some View {
        modifier(PulseAnimation(color: color, duration: duration))
    }
}

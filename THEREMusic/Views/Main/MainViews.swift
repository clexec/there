import SwiftUI

// MARK: - ContentView
struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Group {
            if authManager.isLoading {
                SplashView()
            } else if authManager.isAuthenticated, let user = authManager.currentUser {
                MainTabView(user: user)
                    .transition(.opacity)
            } else {
                AuthenticationView()
                    .transition(.opacity)
            }
        }
        .animation(UIConstants.Animation.medium, value: authManager.isAuthenticated)
        .preferredColorScheme(themeManager.currentTheme == .light ? .light : .dark)
    }
}

// MARK: - SplashView
struct SplashView: View {
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            ColorPalette.backgroundBlack.ignoresSafeArea()
            VStack(spacing: UIConstants.Spacing.base) {
                ZStack {
                    Circle()
                        .fill(ColorPalette.primaryGreen.opacity(0.2))
                        .frame(width: 140, height: 140)
                        .blur(radius: 30)
                    Image(systemName: "music.note.list")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(ColorPalette.primaryGreen)
                }
                .scaleEffect(scale)
                .opacity(opacity)

                Text(AppConstants.appName)
                    .font(.system(size: UIConstants.FontSize.title, weight: .black))
                    .foregroundStyle(ColorPalette.textPrimary)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1; opacity = 1
            }
        }
    }
}

// MARK: - MainTabView
struct MainTabView: View {
    let user: User
    @StateObject private var playerManager = PlayerManager.shared
    @StateObject private var libraryManager = LibraryManager.shared
    @StateObject private var searchViewModel = SearchViewModel()
    @State private var selectedTab: AppTab = .home
    @State private var isSearchPresented: Bool = false

    enum AppTab: Int, CaseIterable {
        case home      = 0
        case favorites = 1
        case create    = 2
        case profile   = 3

        var title: String {
            switch self {
            case .home:      return NSLocalizedString("tab_home", comment: "")
            case .favorites: return NSLocalizedString("tab_favorites", comment: "")
            case .create:    return NSLocalizedString("tab_create", comment: "")
            case .profile:   return NSLocalizedString("tab_profile", comment: "")
            }
        }
        var icon: String {
            switch self {
            case .home:      return "house.fill"
            case .favorites: return "heart.fill"
            case .create:    return "plus.circle.fill"
            case .profile:   return "person.circle.fill"
            }
        }
        var inactiveIcon: String {
            switch self {
            case .home:      return "house"
            case .favorites: return "heart"
            case .create:    return "plus.circle"
            case .profile:   return "person.circle"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 0) {
                if playerManager.isPlayerVisible {
                    MiniPlayerView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                GlassTabBar(selectedTab: $selectedTab, onSearchTap: { isSearchPresented = true })
            }
            .animation(UIConstants.Animation.spring, value: playerManager.isPlayerVisible)
        }
        .fullScreenCover(isPresented: $playerManager.isFullPlayerPresented) {
            FullPlayerView()
                .environmentObject(playerManager)
                .environmentObject(libraryManager)
        }
        .sheet(isPresented: $isSearchPresented) {
            SearchView(viewModel: searchViewModel)
                .preferredColorScheme(.dark)
        }
        .onFirstAppear {
            libraryManager.configure(userID: user.id)
            let homeVM = HomeViewModel()
            Task { await homeVM.load(user: user) }
        }
        .environmentObject(playerManager)
        .environmentObject(libraryManager)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:
            NavigationStack {
                HomeView(user: user)
            }
        case .favorites:
            NavigationStack {
                FavoritesView()
            }
        case .create:
            NavigationStack {
                CreateView()
            }
        case .profile:
            NavigationStack {
                ProfileView()
            }
        }
    }
}

// MARK: - GlassTabBar
struct GlassTabBar: View {
    @Binding var selectedTab: MainTabView.AppTab
    let onSearchTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTabView.AppTab.allCases, id: \.rawValue) { tab in
                TabBarItem(tab: tab, isSelected: selectedTab == tab) {
                    withAnimation(UIConstants.Animation.spring) {
                        selectedTab = tab
                    }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
            }

            Spacer().frame(width: 8)

            Button(action: onSearchTap) {
                VStack(spacing: 3) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: UIConstants.IconSize.md, weight: .semibold))
                        .foregroundStyle(ColorPalette.textSecondary)
                    Text(NSLocalizedString("tab_search", comment: ""))
                        .font(.system(size: UIConstants.FontSize.caption2))
                        .foregroundStyle(ColorPalette.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .scaleOnPress()
        }
        .padding(.horizontal, UIConstants.Spacing.sm)
        .padding(.top, UIConstants.Spacing.sm)
        .padding(.bottom, UIConstants.Spacing.base)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(ColorPalette.glassBorder)
                        .frame(height: 0.5)
                }
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - TabBarItem
struct TabBarItem: View {
    let tab: MainTabView.AppTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(ColorPalette.primaryGreen.opacity(0.15))
                            .frame(width: 44, height: 28)
                            .transition(.scale.combined(with: .opacity))
                    }
                    Image(systemName: isSelected ? tab.icon : tab.inactiveIcon)
                        .font(.system(size: UIConstants.IconSize.md, weight: isSelected ? .bold : .regular))
                        .foregroundStyle(isSelected ? ColorPalette.primaryGreen : ColorPalette.textSecondary)
                }
                Text(tab.title)
                    .font(.system(size: UIConstants.FontSize.caption2, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? ColorPalette.primaryGreen : ColorPalette.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .scaleOnPress(scale: 0.9)
    }
}

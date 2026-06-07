import SwiftUI
import UserNotifications

// MARK: - THEREMusicApp
@main
struct THEREMusicApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager  = AuthenticationManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var playerManager = PlayerManager.shared
    @StateObject private var libraryManager = LibraryManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(themeManager)
                .environmentObject(playerManager)
                .environmentObject(libraryManager)
                .onOpenURL { url in
                    _ = GoogleSignInService.shared.handle(url)
                }
        }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        GoogleSignInService.shared.configure()
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermission()
        setupAppearance()
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        GoogleSignInService.shared.handle(url)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    private func setupAppearance() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = UIColor(ColorPalette.backgroundBlack).withAlphaComponent(0.85)
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = UIColor(ColorPalette.primaryGreen)

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        UITableView.appearance().backgroundColor = UIColor(ColorPalette.backgroundBlack)
        UITableViewCell.appearance().backgroundColor = UIColor(ColorPalette.backgroundBlack)
        UICollectionView.appearance().backgroundColor = UIColor(ColorPalette.backgroundBlack)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

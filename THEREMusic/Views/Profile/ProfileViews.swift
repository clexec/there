import SwiftUI
import PhotosUI

// MARK: - ProfileView
struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject private var libraryManager: LibraryManager
    @State private var showEditProfile: Bool = false
    @State private var showSettings: Bool = false
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        ZStack {
            ColorPalette.backgroundBlack.ignoresSafeArea()
            ScrollView {
                VStack(spacing: UIConstants.Spacing.xl) {
                    profileHeader
                    statsRow
                    actionsGrid
                    recentActivitySection
                    bottomPadding
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(NSLocalizedString("tab_profile", comment: ""))
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarItems }
        .sheet(isPresented: $showEditProfile) { EditProfileView(viewModel: viewModel) }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    private var profileHeader: some View {
        VStack(spacing: UIConstants.Spacing.base) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let data = viewModel.avatarData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage).resizable().scaledToFill()
                    } else {
                        ZStack {
                            Circle().fill(ColorPalette.surface3)
                            Text(viewModel.displayName.initials)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(ColorPalette.textPrimary)
                        }
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(ColorPalette.primaryGreen.opacity(0.5), lineWidth: 2))

                Button { showEditProfile = true } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(ColorPalette.primaryGreen)
                        .background(Circle().fill(ColorPalette.backgroundBlack).frame(width: 24, height: 24))
                }
            }

            VStack(spacing: UIConstants.Spacing.xs) {
                Text(viewModel.displayName)
                    .font(.system(size: UIConstants.FontSize.title3, weight: .bold))
                    .foregroundStyle(ColorPalette.textPrimary)
                if !viewModel.email.isEmpty {
                    Text(viewModel.email)
                        .font(.system(size: UIConstants.FontSize.footnote))
                        .foregroundStyle(ColorPalette.textSecondary)
                }
            }
        }
        .padding(.top, UIConstants.Spacing.base)
    }

    private var statsRow: some View {
        HStack {
            statItem(value: viewModel.likedCount, label: NSLocalizedString("liked", comment: ""))
            Divider().frame(height: 40).background(ColorPalette.surface3)
            statItem(value: viewModel.playlistCount, label: NSLocalizedString("playlists", comment: ""))
            Divider().frame(height: 40).background(ColorPalette.surface3)
            statItem(value: viewModel.followingCount, label: NSLocalizedString("following", comment: ""))
        }
        .padding(.horizontal, UIConstants.Spacing.xl)
        .padding(.vertical, UIConstants.Spacing.base)
        .glassCard()
        .padding(.horizontal, UIConstants.Spacing.base)
    }

    private func statItem(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: UIConstants.FontSize.title3, weight: .bold))
                .foregroundStyle(ColorPalette.textPrimary)
            Text(label)
                .font(.system(size: UIConstants.FontSize.caption))
                .foregroundStyle(ColorPalette.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var actionsGrid: some View {
        VStack(spacing: UIConstants.Spacing.sm) {
            profileActionRow(icon: "heart.fill", color: .pink, title: NSLocalizedString("liked_songs", comment: ""), subtitle: String(format: NSLocalizedString("track_count", comment: ""), viewModel.likedCount)) {
                // Navigate to liked songs
            }
            profileActionRow(icon: "clock.fill", color: ColorPalette.primaryGreen, title: NSLocalizedString("history", comment: ""), subtitle: NSLocalizedString("history_subtitle", comment: "")) {
                // Navigate to history
            }
            profileActionRow(icon: "square.and.arrow.down.fill", color: ColorPalette.infoBlue, title: NSLocalizedString("downloads", comment: ""), subtitle: NSLocalizedString("downloads_subtitle", comment: "")) {
                // Navigate to downloads
            }
        }
        .padding(.horizontal, UIConstants.Spacing.base)
    }

    private func profileActionRow(icon: String, color: Color, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: UIConstants.Spacing.base) {
                ZStack {
                    RoundedRectangle(cornerRadius: UIConstants.Radius.sm).fill(color.opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: icon).font(.system(size: 18)).foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: UIConstants.FontSize.subheadline, weight: .semibold)).foregroundStyle(ColorPalette.textPrimary)
                    Text(subtitle).font(.system(size: UIConstants.FontSize.caption)).foregroundStyle(ColorPalette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 14)).foregroundStyle(ColorPalette.textTertiary)
            }
            .padding(UIConstants.Spacing.base)
            .glassCard()
        }
        .scaleOnPress()
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            Text(NSLocalizedString("recent_activity", comment: ""))
                .font(.system(size: UIConstants.FontSize.title3, weight: .bold))
                .foregroundStyle(ColorPalette.textPrimary)
                .padding(.horizontal, UIConstants.Spacing.base)
            if libraryManager.recentlyPlayed.isEmpty {
                Text(NSLocalizedString("no_recent_activity", comment: ""))
                    .font(.system(size: UIConstants.FontSize.body))
                    .foregroundStyle(ColorPalette.textSecondary)
                    .padding(.horizontal, UIConstants.Spacing.base)
            } else {
                ForEach(libraryManager.recentlyPlayed.prefix(5)) { track in
                    TrackRowView(track: track) {}
                }
            }
        }
    }

    private var bottomPadding: some View {
        Color.clear.frame(height: AppConstants.Player.miniPlayerHeight + AppConstants.UI.tabBarHeight + UIConstants.Spacing.xl)
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill").foregroundStyle(ColorPalette.textPrimary)
            }
        }
    }
}

// MARK: - EditProfileView
struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ZStack {
                ColorPalette.backgroundBlack.ignoresSafeArea()
                VStack(spacing: UIConstants.Spacing.xl) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            Group {
                                if let data = viewModel.avatarData, let img = UIImage(data: data) {
                                    Image(uiImage: img).resizable().scaledToFill()
                                } else {
                                    Circle().fill(ColorPalette.surface3).overlay(
                                        Text(viewModel.displayName.initials).font(.system(size: 36, weight: .bold)).foregroundStyle(ColorPalette.textPrimary)
                                    )
                                }
                            }
                            .frame(width: 100, height: 100).clipShape(Circle())
                            Circle().fill(ColorPalette.primaryGreen).frame(width: 30, height: 30)
                                .overlay(Image(systemName: "camera.fill").font(.system(size: 14)).foregroundStyle(.black))
                        }
                    }
                    .onChange(of: selectedPhoto) { _, item in
                        Task {
                            if let data = try? await item?.loadTransferable(type: Data.self) {
                                viewModel.avatarData = data
                            }
                        }
                    }

                    VStack(spacing: UIConstants.Spacing.md) {
                        AuthTextField(placeholder: NSLocalizedString("name_placeholder", comment: ""), text: $viewModel.displayName, isFocused: .constant(false))
                    }
                    .padding(.horizontal, UIConstants.Spacing.xl)

                    if let error = viewModel.error { ErrorLabel(message: error).padding(.horizontal, UIConstants.Spacing.xl) }

                    Spacer()
                }
                .padding(.top, UIConstants.Spacing.xl)
            }
            .navigationTitle(NSLocalizedString("edit_profile", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "")) { dismiss() }.foregroundStyle(ColorPalette.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("save", comment: "")) {
                        Task { await viewModel.saveProfile(); dismiss() }
                    }
                    .foregroundStyle(ColorPalette.primaryGreen).fontWeight(.semibold)
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - SettingsView
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ColorPalette.backgroundBlack.ignoresSafeArea()
                List {
                    appearanceSection
                    playbackSection
                    storageSection
                    notificationsSection
                    accountSection
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(ColorPalette.backgroundBlack)
            }
            .navigationTitle(NSLocalizedString("settings", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("done", comment: "")) { dismiss() }.foregroundStyle(ColorPalette.primaryGreen)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var appearanceSection: some View {
        Section(NSLocalizedString("settings_appearance", comment: "")) {
            HStack {
                SettingsLabel(icon: "moon.fill", color: ColorPalette.infoBlue, title: NSLocalizedString("theme", comment: ""))
                Spacer()
                Picker("", selection: $viewModel.selectedTheme) {
                    ForEach(Theme.allCases, id: \.rawValue) { theme in
                        Text(theme.localizedTitle).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .onChange(of: viewModel.selectedTheme) { _, t in viewModel.applyTheme(t) }
            }
            HStack {
                SettingsLabel(icon: "globe", color: ColorPalette.primaryGreen, title: NSLocalizedString("language", comment: ""))
                Spacer()
                Picker("", selection: $viewModel.selectedLanguage) {
                    Text("English").tag("en")
                    Text("Русский").tag("ru")
                    Text("System").tag("system")
                }
                .pickerStyle(.menu)
            }
        }
        .listRowBackground(ColorPalette.surface2)
    }

    private var playbackSection: some View {
        Section(NSLocalizedString("settings_playback", comment: "")) {
            HStack {
                SettingsLabel(icon: "waveform", color: ColorPalette.warningYellow, title: NSLocalizedString("stream_quality", comment: ""))
                Spacer()
                Picker("", selection: $viewModel.streamQuality) {
                    ForEach(StreamQuality.allCases, id: \.rawValue) { q in
                        Text(q.localizedTitle).tag(q)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.streamQuality) { _, q in viewModel.setQuality(q) }
            }
            VStack(alignment: .leading, spacing: UIConstants.Spacing.sm) {
                HStack {
                    SettingsLabel(icon: "xmark.circle", color: ColorPalette.errorRed, title: NSLocalizedString("crossfade", comment: ""))
                    Spacer()
                    Text(String(format: "%.0fs", viewModel.crossfadeDuration))
                        .font(.system(size: UIConstants.FontSize.footnote)).foregroundStyle(ColorPalette.textSecondary)
                }
                Slider(value: $viewModel.crossfadeDuration, in: AppConstants.Player.crossfadeRange, step: 1)
                    .tint(ColorPalette.primaryGreen)
                    .onChange(of: viewModel.crossfadeDuration) { _, v in viewModel.setCrossfade(v) }
            }
            Toggle(isOn: $viewModel.downloadOnWifi) {
                SettingsLabel(icon: "wifi", color: ColorPalette.infoBlue, title: NSLocalizedString("download_wifi_only", comment: ""))
            }
            .tint(ColorPalette.primaryGreen)
        }
        .listRowBackground(ColorPalette.surface2)
    }

    private var storageSection: some View {
        Section(NSLocalizedString("settings_storage", comment: "")) {
            HStack {
                SettingsLabel(icon: "internaldrive", color: ColorPalette.warningYellow, title: NSLocalizedString("cache_size", comment: ""))
                Spacer()
                Text(viewModel.cacheSize).font(.system(size: UIConstants.FontSize.footnote)).foregroundStyle(ColorPalette.textSecondary)
            }
            Button {
                Task { await viewModel.clearCache() }
            } label: {
                HStack {
                    SettingsLabel(icon: "trash", color: ColorPalette.errorRed, title: NSLocalizedString("clear_cache", comment: ""))
                    Spacer()
                    if viewModel.isLoading { ProgressView().tint(ColorPalette.primaryGreen) }
                }
            }
            .foregroundStyle(ColorPalette.textPrimary)
        }
        .listRowBackground(ColorPalette.surface2)
    }

    private var notificationsSection: some View {
        Section(NSLocalizedString("settings_notifications", comment: "")) {
            Toggle(isOn: $viewModel.notificationsEnabled) {
                SettingsLabel(icon: "bell.fill", color: ColorPalette.primaryGreen, title: NSLocalizedString("notifications", comment: ""))
            }.tint(ColorPalette.primaryGreen)
            if viewModel.notificationsEnabled {
                Toggle(isOn: $viewModel.discoverNotif) {
                    SettingsLabel(icon: "sparkles", color: ColorPalette.primaryGreen, title: NSLocalizedString("discover_weekly_notif", comment: ""))
                }.tint(ColorPalette.primaryGreen)
                Toggle(isOn: $viewModel.releaseNotif) {
                    SettingsLabel(icon: "music.note.list", color: ColorPalette.primaryGreen, title: NSLocalizedString("release_radar_notif", comment: ""))
                }.tint(ColorPalette.primaryGreen)
            }
        }
        .listRowBackground(ColorPalette.surface2)
    }

    private var accountSection: some View {
        Section(NSLocalizedString("settings_account", comment: "")) {
            NavigationLink(destination: Text(NSLocalizedString("about", comment: "")).foregroundStyle(ColorPalette.textPrimary)) {
                SettingsLabel(icon: "info.circle", color: ColorPalette.infoBlue, title: NSLocalizedString("about", comment: ""))
            }
            Button {
                authManager.signOut()
                dismiss()
            } label: {
                HStack {
                    SettingsLabel(icon: "rectangle.portrait.and.arrow.right", color: ColorPalette.errorRed, title: NSLocalizedString("sign_out", comment: ""))
                    Spacer()
                }
            }
            .foregroundStyle(ColorPalette.errorRed)
        }
        .listRowBackground(ColorPalette.surface2)
    }
}

struct SettingsLabel: View {
    let icon: String
    let color: Color
    let title: String

    var body: some View {
        HStack(spacing: UIConstants.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: UIConstants.Radius.xs).fill(color).frame(width: 30, height: 30)
                Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
            }
            Text(title).font(.system(size: UIConstants.FontSize.body)).foregroundStyle(ColorPalette.textPrimary)
        }
    }
}

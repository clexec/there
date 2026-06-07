import SwiftUI

// MARK: - MiniPlayerView
struct MiniPlayerView: View {
    @EnvironmentObject private var playerManager: PlayerManager
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        Button {
            playerManager.isFullPlayerPresented = true
        } label: {
            HStack(spacing: UIConstants.Spacing.md) {
                AsyncArtworkView(url: playerManager.currentTrack?.artworkURL, size: AppConstants.Player.miniPlayerHeight - 16)
                    .cornerRadius(UIConstants.Radius.sm)
                    .padding(.leading, UIConstants.Spacing.md)

                VStack(alignment: .leading, spacing: 2) {
                    Text(playerManager.currentTrack?.title ?? "")
                        .font(.system(size: UIConstants.FontSize.footnote, weight: .semibold))
                        .foregroundStyle(ColorPalette.textPrimary)
                        .lineLimit(1)
                    Text(playerManager.currentTrack?.artistName ?? "")
                        .font(.system(size: UIConstants.FontSize.caption))
                        .foregroundStyle(ColorPalette.textSecondary)
                        .lineLimit(1)
                }
                Spacer()

                HStack(spacing: UIConstants.Spacing.sm) {
                    Button {
                        playerManager.pauseResume()
                    } label: {
                        Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: UIConstants.IconSize.lg))
                            .foregroundStyle(ColorPalette.textPrimary)
                    }
                    .frame(width: 40, height: 40)

                    Button { playerManager.skipNext() } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: UIConstants.IconSize.md))
                            .foregroundStyle(ColorPalette.textPrimary)
                    }
                    .frame(width: 36, height: 36)
                }
                .padding(.trailing, UIConstants.Spacing.md)
            }
            .frame(height: AppConstants.Player.miniPlayerHeight)
            .background {
                RoundedRectangle(cornerRadius: AppConstants.Player.miniPlayerCornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppConstants.Player.miniPlayerCornerRadius)
                            .strokeBorder(ColorPalette.glassBorder, lineWidth: 0.5)
                    }
                    .shadow(color: ColorPalette.glassShadow, radius: 8, x: 0, y: 2)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, UIConstants.Spacing.sm)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height < 0 { dragOffset = value.translation.height }
                }
                .onEnded { value in
                    if value.translation.height < -50 {
                        playerManager.isFullPlayerPresented = true
                    }
                    withAnimation(UIConstants.Animation.spring) { dragOffset = 0 }
                }
        )
        .overlay(alignment: .bottom) {
            GeometryReader { _ in
                ProgressView(value: playerManager.progress)
                    .tint(ColorPalette.primaryGreen)
                    .frame(height: 2)
                    .padding(.horizontal, UIConstants.Spacing.sm)
                    .padding(.bottom, -1)
            }
            .frame(height: 4)
        }
    }
}

// MARK: - FullPlayerView
struct FullPlayerView: View {
    @EnvironmentObject private var playerManager: PlayerManager
    @EnvironmentObject private var libraryManager: LibraryManager
    @StateObject private var viewModel = PlayerViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var artworkScale: CGFloat = 1
    @State private var showComments: Bool = false
    @State private var showQueue: Bool = false
    @State private var showShare: Bool = false

    var body: some View {
        ZStack {
            artworkBackground
            ScrollView {
                VStack(spacing: UIConstants.Spacing.xl) {
                    navigationBar
                    artworkSection
                    trackInfoSection
                    progressSection
                    controlsSection
                    secondaryControlsSection
                    if viewModel.isPlaying {
                        AudioVisualizerView(bars: viewModel.visualizerBars)
                    }
                    bottomPadding
                }
                .padding(.horizontal, UIConstants.Spacing.xl)
            }
            .scrollIndicators(.hidden)
        }
        .fullScreenCover(isPresented: $showComments) {
            CommentView(trackID: playerManager.currentTrack?.id ?? "")
        }
        .sheet(isPresented: $showQueue) {
            QueueView()
                .environmentObject(playerManager)
        }
        .sheet(isPresented: $showShare) {
            if let text = viewModel.shareTrack() {
                ShareSheet(items: [text])
            }
        }
        .preferredColorScheme(.dark)
    }

    private var artworkBackground: some View {
        ZStack {
            ColorPalette.backgroundBlack.ignoresSafeArea()
            if let url = playerManager.currentTrack?.artworkURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: { Color.clear }
                .ignoresSafeArea()
                .blur(radius: 80)
                .opacity(0.3)
                .clipped()
            }
            LinearGradient(
                colors: [ColorPalette.backgroundBlack.opacity(0.4), ColorPalette.backgroundBlack],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private var navigationBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ColorPalette.textPrimary)
                    .frame(width: 40, height: 40)
                    .glassCard(cornerRadius: UIConstants.Radius.md)
            }
            Spacer()
            VStack(spacing: 2) {
                Text(NSLocalizedString("playing_from", comment: ""))
                    .font(.system(size: UIConstants.FontSize.caption2, weight: .semibold))
                    .foregroundStyle(ColorPalette.textSecondary)
                Text(playerManager.currentTrack?.albumTitle ?? NSLocalizedString("queue", comment: ""))
                    .font(.system(size: UIConstants.FontSize.caption, weight: .bold))
                    .foregroundStyle(ColorPalette.textPrimary)
                    .lineLimit(1)
            }
            Spacer()
            Button { viewModel.isOptionsVisible = true } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18))
                    .foregroundStyle(ColorPalette.textPrimary)
                    .frame(width: 40, height: 40)
                    .glassCard(cornerRadius: UIConstants.Radius.md)
            }
        }
        .padding(.top, UIConstants.Spacing.sm)
    }

    private var artworkSection: some View {
        ZStack {
            AsyncArtworkView(url: playerManager.currentTrack?.artworkURL, size: UIConstants.FullPlayer.artworkSize)
                .cornerRadius(UIConstants.Radius.xl)
                .cardShadow()
                .shadow(color: ColorPalette.primaryGreen.opacity(viewModel.isPlaying ? 0.3 : 0), radius: 30, x: 0, y: 10)
                .scaleEffect(viewModel.isPlaying ? 1 : 0.9)
                .animation(UIConstants.Animation.spring, value: viewModel.isPlaying)
        }
        .frame(width: UIConstants.FullPlayer.artworkSize, height: UIConstants.FullPlayer.artworkSize)
    }

    private var trackInfoSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
                Text(playerManager.currentTrack?.title ?? "")
                    .font(.system(size: UIConstants.FontSize.title2, weight: .bold))
                    .foregroundStyle(ColorPalette.textPrimary)
                    .lineLimit(1)
                NavigationLink(destination: playerManager.currentTrack.map {
                    ArtistDetailView(artist: Artist(name: $0.artistName))
                }) {
                    Text(playerManager.currentTrack?.artistName ?? "")
                        .font(.system(size: UIConstants.FontSize.body))
                        .foregroundStyle(ColorPalette.textSecondary)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
            }
            Spacer()
            Button { Task { await viewModel.toggleLike() } } label: {
                Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                    .font(.system(size: UIConstants.IconSize.xl))
                    .foregroundStyle(viewModel.isLiked ? ColorPalette.primaryGreen : ColorPalette.textSecondary)
                    .scaleEffect(viewModel.isLiked ? 1.15 : 1)
                    .animation(UIConstants.Animation.spring, value: viewModel.isLiked)
            }
        }
    }

    private var progressSection: some View {
        VStack(spacing: UIConstants.Spacing.xs) {
            PlayerProgressBar(
                progress: viewModel.progress,
                isDragging: viewModel.isDraggingProgress,
                onDragStart: { viewModel.startDragging() },
                onDragChange: { viewModel.updateDrag(progress: $0) },
                onDragEnd:   { viewModel.seekTo(progress: viewModel.dragProgress) }
            )
            HStack {
                Text(viewModel.currentTime.formattedDuration)
                    .font(.system(size: UIConstants.FontSize.caption))
                    .foregroundStyle(ColorPalette.textSecondary)
                Spacer()
                Text(viewModel.duration.formattedDuration)
                    .font(.system(size: UIConstants.FontSize.caption))
                    .foregroundStyle(ColorPalette.textSecondary)
            }
        }
    }

    private var controlsSection: some View {
        HStack(spacing: UIConstants.Spacing.xxl) {
            Button { viewModel.toggleShuffle() } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: UIConstants.IconSize.lg))
                    .foregroundStyle(viewModel.isShuffled ? ColorPalette.primaryGreen : ColorPalette.textSecondary)
            }

            Button { viewModel.skipPrevious() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(ColorPalette.textPrimary)
            }
            .scaleOnPress()

            Button { viewModel.playPause() } label: {
                ZStack {
                    Circle()
                        .fill(ColorPalette.textPrimary)
                        .frame(width: 72, height: 72)
                        .shadow(color: ColorPalette.primaryGreen.opacity(0.4), radius: 12)
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(ColorPalette.backgroundBlack)
                        .offset(x: viewModel.isPlaying ? 0 : 2)
                }
            }
            .scaleOnPress()

            Button { viewModel.skipNext() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(ColorPalette.textPrimary)
            }
            .scaleOnPress()

            Button { viewModel.toggleRepeat() } label: {
                Image(systemName: viewModel.repeatMode.systemImageName)
                    .font(.system(size: UIConstants.IconSize.lg))
                    .foregroundStyle(viewModel.repeatMode.isActive ? ColorPalette.primaryGreen : ColorPalette.textSecondary)
            }
        }
    }

    private var secondaryControlsSection: some View {
        HStack(spacing: UIConstants.Spacing.xl) {
            Button { showShare = true } label: {
                VStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                    Text(NSLocalizedString("share", comment: ""))
                        .font(.system(size: UIConstants.FontSize.caption2))
                }
                .foregroundStyle(ColorPalette.textSecondary)
                .frame(width: 50)
            }
            Spacer()
            Button { showComments = true } label: {
                VStack(spacing: 4) {
                    Image(systemName: "bubble.left.fill")
                    Text(NSLocalizedString("comments", comment: ""))
                        .font(.system(size: UIConstants.FontSize.caption2))
                }
                .foregroundStyle(ColorPalette.textSecondary)
                .frame(width: 50)
            }
            Spacer()
            Button { showQueue = true } label: {
                VStack(spacing: 4) {
                    Image(systemName: "list.bullet.rectangle")
                    Text(NSLocalizedString("queue", comment: ""))
                        .font(.system(size: UIConstants.FontSize.caption2))
                }
                .foregroundStyle(ColorPalette.textSecondary)
                .frame(width: 50)
            }
            Spacer()
            Button {} label: {
                VStack(spacing: 4) {
                    Image(systemName: "airpods.gen3")
                    Text(NSLocalizedString("devices", comment: ""))
                        .font(.system(size: UIConstants.FontSize.caption2))
                }
                .foregroundStyle(ColorPalette.textSecondary)
                .frame(width: 50)
            }
        }
        .font(.system(size: UIConstants.IconSize.md))
    }

    private var bottomPadding: some View {
        Color.clear.frame(height: UIConstants.Spacing.xl)
    }
}

// MARK: - PlayerProgressBar
struct PlayerProgressBar: View {
    let progress: Double
    let isDragging: Bool
    let onDragStart: () -> Void
    let onDragChange: (Double) -> Void
    let onDragEnd: () -> Void
    @State private var barHeight: CGFloat = UIConstants.FullPlayer.progressHeight

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(ColorPalette.surface3)
                    .frame(height: barHeight)
                Capsule()
                    .fill(ColorPalette.textPrimary)
                    .frame(width: max(0, min(geo.size.width * progress, geo.size.width)), height: barHeight)
                Circle()
                    .fill(ColorPalette.textPrimary)
                    .frame(width: isDragging ? 16 : 0)
                    .offset(x: max(0, min(geo.size.width * progress - 8, geo.size.width - 8)))
                    .animation(UIConstants.Animation.fast, value: isDragging)
            }
            .frame(height: 20)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        onDragStart()
                        let p = value.location.x / geo.size.width
                        onDragChange(max(0, min(1, p)))
                    }
                    .onEnded { _ in onDragEnd() }
            )
        }
        .frame(height: 20)
        .onHover { isHovered in
            withAnimation(UIConstants.Animation.fast) {
                barHeight = isHovered ? 6 : UIConstants.FullPlayer.progressHeight
            }
        }
    }
}

// MARK: - AudioVisualizerView
struct AudioVisualizerView: View {
    let bars: [CGFloat]

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(Array(bars.enumerated()), id: \.offset) { _, height in
                RoundedRectangle(cornerRadius: 1)
                    .fill(ColorPalette.primaryGreen)
                    .frame(width: 3, height: height * 40)
                    .animation(UIConstants.Animation.fast, value: height)
            }
        }
        .frame(height: 40)
    }
}

// MARK: - QueueView
struct QueueView: View {
    @EnvironmentObject private var playerManager: PlayerManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ColorPalette.backgroundBlack.ignoresSafeArea()
                List {
                    Section {
                        ForEach(Array(playerManager.queue.enumerated()), id: \.element.id) { index, track in
                            QueueTrackRow(
                                track: track,
                                isCurrent: index == playerManager.currentIndex,
                                rank: index
                            ) {
                                playerManager.play(
                                    track: track,
                                    queue: playerManager.queue,
                                    startIndex: index
                                )
                            }
                        }
                        .onDelete { offsets in
                            offsets.forEach { playerManager.removeFromQueue(at: $0) }
                        }
                        .onMove { source, dest in
                            playerManager.moveInQueue(from: source, to: dest)
                        }
                    } header: {
                        Text(NSLocalizedString("queue_next_up", comment: ""))
                            .font(.system(size: UIConstants.FontSize.footnote, weight: .semibold))
                            .foregroundStyle(ColorPalette.textSecondary)
                    }
                }
                .listStyle(.plain)
                .background(ColorPalette.backgroundBlack)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(NSLocalizedString("queue", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(NSLocalizedString("clear", comment: "")) {
                        playerManager.clearQueue()
                    }
                    .foregroundStyle(ColorPalette.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("done", comment: "")) { dismiss() }
                        .foregroundStyle(ColorPalette.primaryGreen)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                        .foregroundStyle(ColorPalette.primaryGreen)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct QueueTrackRow: View {
    let track: Track
    let isCurrent: Bool
    let rank: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: UIConstants.Spacing.md) {
                AsyncArtworkView(url: track.artworkURL, size: 44)
                    .cornerRadius(UIConstants.Radius.xs)
                    .overlay {
                        if isCurrent {
                            RoundedRectangle(cornerRadius: UIConstants.Radius.xs)
                                .strokeBorder(ColorPalette.primaryGreen, lineWidth: 2)
                        }
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: UIConstants.FontSize.subheadline, weight: isCurrent ? .bold : .regular))
                        .foregroundStyle(isCurrent ? ColorPalette.primaryGreen : ColorPalette.textPrimary)
                        .lineLimit(1)
                    Text(track.artistName)
                        .font(.system(size: UIConstants.FontSize.caption))
                        .foregroundStyle(ColorPalette.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                if isCurrent {
                    AudioBarsIndicator(color: ColorPalette.primaryGreen)
                } else {
                    Text(track.formattedDuration)
                        .font(.system(size: UIConstants.FontSize.caption))
                        .foregroundStyle(ColorPalette.textTertiary)
                }
            }
        }
        .listRowBackground(ColorPalette.backgroundBlack)
        .listRowSeparatorTint(ColorPalette.surface3)
    }
}

// MARK: - CommentView
struct CommentView: View {
    let trackID: String
    @StateObject private var viewModel = CommentViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isCommentFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                ColorPalette.backgroundBlack.ignoresSafeArea()
                VStack(spacing: 0) {
                    commentList
                    commentInput
                }
            }
            .navigationTitle(NSLocalizedString("comments", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("done", comment: "")) { dismiss() }
                        .foregroundStyle(ColorPalette.primaryGreen)
                }
            }
        }
        .onFirstAppear { Task { await viewModel.loadComments(trackID: trackID) } }
        .preferredColorScheme(.dark)
    }

    private var commentList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView().tint(ColorPalette.primaryGreen).padding()
                } else if viewModel.comments.isEmpty {
                    VStack(spacing: UIConstants.Spacing.base) {
                        Image(systemName: "bubble.left").font(.system(size: 40)).foregroundStyle(ColorPalette.textTertiary)
                        Text(NSLocalizedString("no_comments", comment: "")).foregroundStyle(ColorPalette.textSecondary)
                    }
                    .padding(.top, UIConstants.Spacing.xxxl)
                } else {
                    ForEach(viewModel.comments) { comment in
                        CommentRowView(comment: comment,
                            onEdit: { viewModel.startEditing(comment) },
                            onDelete: { Task { await viewModel.deleteComment(comment) } }
                        )
                        Divider().background(ColorPalette.surface3).padding(.leading, 56)
                    }
                }
            }
        }
    }

    private var commentInput: some View {
        VStack(spacing: 0) {
            Divider().background(ColorPalette.surface3)
            HStack(spacing: UIConstants.Spacing.md) {
                TextField(NSLocalizedString("write_comment", comment: ""), text: $viewModel.newCommentText, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.system(size: UIConstants.FontSize.body))
                    .foregroundStyle(ColorPalette.textPrimary)
                    .focused($isCommentFocused)
                    .padding(.horizontal, UIConstants.Spacing.md)
                    .padding(.vertical, UIConstants.Spacing.sm)
                    .background {
                        RoundedRectangle(cornerRadius: UIConstants.Radius.lg)
                            .fill(ColorPalette.surface2)
                    }
                Button {
                    Task { await viewModel.postComment(trackID: trackID) }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(viewModel.canPost ? ColorPalette.primaryGreen : ColorPalette.textTertiary)
                }
                .disabled(!viewModel.canPost)
            }
            .padding(.horizontal, UIConstants.Spacing.base)
            .padding(.vertical, UIConstants.Spacing.sm)
            .background(.ultraThinMaterial)
        }
    }
}

struct CommentRowView: View {
    let comment: Comment
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: UIConstants.Spacing.md) {
            if let url = comment.userAvatarURL {
                AsyncArtworkView(url: url, size: 36, isCircle: true)
            } else {
                Circle()
                    .fill(ColorPalette.surface3)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(comment.userName.initials)
                            .font(.system(size: UIConstants.FontSize.caption, weight: .bold))
                            .foregroundStyle(ColorPalette.textPrimary)
                    )
            }
            VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
                HStack {
                    Text(comment.userName)
                        .font(.system(size: UIConstants.FontSize.footnote, weight: .bold))
                        .foregroundStyle(ColorPalette.textPrimary)
                    if comment.isEdited {
                        Text(NSLocalizedString("edited", comment: ""))
                            .font(.system(size: UIConstants.FontSize.caption2))
                            .foregroundStyle(ColorPalette.textTertiary)
                    }
                    Spacer()
                    Text(comment.createdAt.timeAgo)
                        .font(.system(size: UIConstants.FontSize.caption2))
                        .foregroundStyle(ColorPalette.textTertiary)
                }
                Text(comment.text)
                    .font(.system(size: UIConstants.FontSize.body))
                    .foregroundStyle(ColorPalette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, UIConstants.Spacing.base)
        .padding(.vertical, UIConstants.Spacing.md)
        .contextMenu {
            Button(NSLocalizedString("edit", comment: ""), systemImage: "pencil", action: onEdit)
            Button(NSLocalizedString("delete", comment: ""), systemImage: "trash", role: .destructive, action: onDelete)
        }
    }
}

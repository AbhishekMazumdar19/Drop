import SwiftUI

struct FeedView: View {

    @EnvironmentObject private var appState: AppState
    @StateObject private var feedVM = FeedViewModel()
    @State private var selectedPost: FeedPost?
    @State private var showPostDetail = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dropBlack.ignoresSafeArea()

                if feedVM.isLoading && feedVM.feedPosts.isEmpty {
                    feedLoadingState
                } else if feedVM.feedPosts.isEmpty && !feedVM.isLoading {
                    emptyFeedState
                } else {
                    feedContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    feedHeader
                }
                ToolbarItem(placement: .topBarTrailing) {
                    notificationButton
                }
            }
            .sheet(item: $selectedPost) { post in
                PostDetailView(post: post)
                    .environmentObject(appState)
                    .environmentObject(feedVM)
            }
        }
        .task {
            await loadFeed()
        }
    }

    // MARK: - Feed Header
    private var feedHeader: some View {
        HStack(spacing: 8) {
            Text("DROP")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient.dropFireGradient)

            if let drop = appState.activeDrop, drop.isCurrentlyActive {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.dropOnTime)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(DROPFont.label(9))
                        .foregroundColor(.dropOnTime)
                        .tracking(1.5)
                }
            }
        }
    }

    private var notificationButton: some View {
        Button { } label: {
            Image(systemName: "bell.fill")
                .foregroundColor(.dropTextSecondary)
                .font(.system(size: 16))
        }
    }

    // MARK: - Feed Content
    private var feedContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Active drop banner
                if let drop = appState.activeDrop, drop.isAcceptingResponses, !appState.hasPostedToday {
                    ActiveDropBannerView(drop: drop)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }

                // Section picker
                sectionPicker

                // Section content
                switch feedVM.selectedSection {
                case .today:
                    todaySection
                case .scenes:
                    scenesSection
                case .recent:
                    recentSection
                }
            }
        }
        .refreshable {
            await feedVM.refresh(
                campusId: appState.currentUser?.campusId ?? "",
                currentUserId: appState.currentUser?.id ?? "",
                activeDrop: appState.activeDrop
            )
        }
    }

    // MARK: - Section Picker
    private var sectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FeedSection.allCases) { section in
                    Button {
                        withAnimation(.dropSnap) { feedVM.selectedSection = section }
                    } label: {
                        Text(section.rawValue)
                            .font(DROPFont.body(13))
                            .foregroundColor(feedVM.selectedSection == section ? .white : .dropTextSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(feedVM.selectedSection == section ? Color.dropOrange : Color.dropCard)
                            .cornerRadius(Radius.pill)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 14)
    }

    // MARK: - Today Section
    private var todaySection: some View {
        Group {
            if feedVM.todaysPosts.isEmpty {
                VStack(spacing: 12) {
                    Text("📸")
                        .font(.system(size: 48))
                    Text("No posts for today's Drop yet.\nBe the first to show up.")
                        .font(DROPFont.body())
                        .foregroundColor(.dropTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
            } else {
                postList(feedVM.todaysPosts)
            }
        }
    }

    // MARK: - Scenes Section
    private var scenesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(feedVM.activeScenes, id: \.tag) { scene in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(scene.tag.emoji)
                        Text(scene.tag.rawValue)
                            .font(DROPFont.headline())
                            .foregroundColor(.white)
                        Text("·")
                        Text("\(scene.posts.count) drops")
                            .font(DROPFont.body(13))
                            .foregroundColor(.dropTextSecondary)
                    }
                    .padding(.horizontal, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(scene.posts) { post in
                                compactPostCard(post)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }

            if feedVM.activeScenes.isEmpty {
                emptyFeedState.padding(.top, 40)
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: - Recent Section
    private var recentSection: some View {
        postList(feedVM.feedPosts)
    }

    // MARK: - Full Post List
    private func postList(_ posts: [FeedPost]) -> some View {
        LazyVStack(spacing: 2) {
            ForEach(posts) { post in
                PostCard(post: post, currentUserId: appState.currentUser?.id ?? "") {
                    Task {
                        await feedVM.toggleLike(post: post, currentUserId: appState.currentUser?.id ?? "")
                    }
                } onTap: {
                    selectedPost = post
                }
                .padding(.bottom, 2)
            }
        }
        .padding(.bottom, 100)
    }

    // MARK: - Compact horizontal card (for Scenes)
    private func compactPostCard(_ post: FeedPost) -> some View {
        Button {
            selectedPost = post
        } label: {
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: post.response.imageURL)) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        Color.dropCard.shimmer()
                    }
                }
                .frame(width: 140, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))

                LinearGradient.feedBlurGradient
                    .frame(width: 140, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))

                VStack(alignment: .leading, spacing: 3) {
                    Text(post.user.displayName)
                        .font(DROPFont.caption(11))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if let vibe = post.response.vibeTag {
                        Text(vibe)
                            .font(DROPFont.label(9))
                            .foregroundColor(.dropOrange)
                    }
                }
                .padding(10)
            }
            .frame(width: 140, height: 180)
        }
    }

    // MARK: - Empty State
    private var emptyFeedState: some View {
        VStack(spacing: 16) {
            Text("🌎")
                .font(.system(size: 52))
            Text("Nothing dropped yet")
                .font(DROPFont.headline())
                .foregroundColor(.white)
            Text("When your campus drops, it'll show up here.")
                .font(DROPFont.body())
                .foregroundColor(.dropTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 80)
        .padding(.horizontal, 32)
    }

    // MARK: - Loading State
    private var feedLoadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.dropOrange)
                .scaleEffect(1.2)
            Text("Loading campus feed...")
                .font(DROPFont.body())
                .foregroundColor(.dropTextSecondary)
        }
    }

    // MARK: - Data
    private func loadFeed() async {
        await feedVM.loadFeed(
            campusId: appState.currentUser?.campusId ?? "",
            currentUserId: appState.currentUser?.id ?? "",
            activeDrop: appState.activeDrop
        )
    }
}

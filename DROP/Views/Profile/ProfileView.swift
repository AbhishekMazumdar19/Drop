import SwiftUI

// MARK: - Profile View
struct ProfileView: View {

    @EnvironmentObject private var appState: AppState
    @StateObject private var profileVM = ProfileViewModel()
    @State private var showEditProfile = false
    @State private var showBadges = false

    private var isOwnProfile: Bool { true } // Always own for now (nav to others' from PostCard)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dropBlack.ignoresSafeArea()

                if profileVM.isLoading {
                    ProgressView().tint(.dropOrange)
                } else if let user = profileVM.user {
                    ScrollView {
                        VStack(spacing: 0) {
                            profileHeader(user: user)
                            statsBar(user: user)
                            badgesSection(user: user)
                            dropsGrid
                        }
                    }
                    .refreshable {
                        await profileVM.loadProfile(userId: appState.currentUser?.id ?? "")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(DROPFont.headline())
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showEditProfile = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        appState.signOut()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.dropTextSecondary)
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(profileVM: profileVM)
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showBadges) {
                BadgesView(earnedIds: profileVM.user?.badges ?? [])
            }
        }
        .task {
            await profileVM.loadProfile(userId: appState.currentUser?.id ?? "")
        }
    }

    // MARK: - Header
    private func profileHeader(user: UserModel) -> some View {
        VStack(spacing: 16) {
            AvatarView(user: user, size: 90, showStreakRing: true)

            VStack(spacing: 6) {
                Text(user.displayName)
                    .font(DROPFont.display(26))
                    .foregroundColor(.white)

                if let course = user.course, !course.isEmpty {
                    Text(course)
                        .font(DROPFont.body(14))
                        .foregroundColor(.dropTextSecondary)
                }

                if let vibe = user.displayVibe {
                    Text(vibe)
                        .font(DROPFont.body(13))
                        .foregroundColor(.dropOrange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.dropOrange.opacity(0.1))
                        .cornerRadius(Radius.pill)
                }

                if let identity = user.dropIdentity, !identity.isEmpty {
                    Text(identity)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.dropTextSecondary)
                }
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stats Bar
    private func statsBar(user: UserModel) -> some View {
        HStack(spacing: 0) {
            statItem(value: "\(user.totalDrops)", label: "Drops")
            Divider().frame(height: 36).background(Color.dropDivider)
            statItem(value: "\(user.streakCount)🔥", label: "Streak")
            Divider().frame(height: 36).background(Color.dropDivider)
            statItem(value: "\(Int(user.onTimeRate * 100))%", label: "On-Time")
            Divider().frame(height: 36).background(Color.dropDivider)
            statItem(value: "\(user.badges.count)", label: "Badges")
        }
        .padding(.vertical, 16)
        .background(Color.dropCard)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(DROPFont.headline(18))
                .foregroundColor(.white)
            Text(label)
                .font(DROPFont.body(12))
                .foregroundColor(.dropTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Badges Section
    private func badgesSection(user: UserModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("BADGES")
                    .font(DROPFont.label(10))
                    .foregroundColor(.dropTextSecondary)
                    .tracking(3)
                Spacer()
                Button {
                    showBadges = true
                } label: {
                    Text("See All")
                        .font(DROPFont.body(13))
                        .foregroundColor(.dropOrange)
                }
            }

            if user.badges.isEmpty {
                Text("Complete Drops to earn badges.")
                    .font(DROPFont.body(13))
                    .foregroundColor(.dropTextSecondary)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(profileVM.earnedBadges.prefix(5), id: \.id) { badge in
                            BadgeChipView(badge: badge)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    // MARK: - Drops Grid
    private var dropsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MY DROPS")
                .font(DROPFont.label(10))
                .foregroundColor(.dropTextSecondary)
                .tracking(3)
                .padding(.horizontal, 16)

            if profileVM.recentPosts.isEmpty {
                VStack(spacing: 12) {
                    Text("📸")
                        .font(.system(size: 36))
                    Text("Your Drops will appear here.")
                        .font(DROPFont.body())
                        .foregroundColor(.dropTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)],
                    spacing: 2
                ) {
                    ForEach(profileVM.recentPosts, id: \.id) { response in
                        AsyncImage(url: URL(string: response.imageURL)) { phase in
                            if case .success(let img) = phase {
                                img.resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fill)
                                    .clipped()
                            } else {
                                Color.dropCard
                                    .aspectRatio(1, contentMode: .fill)
                            }
                        }
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {

    @ObservedObject var profileVM: ProfileViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedImage: UIImage?
    @State private var showPicker = false
    @State private var displayName: String = ""
    @State private var course: String = ""
    @State private var selectedVibe: VibeOption?
    @FocusState private var focusedField: EditField?

    private enum EditField { case name, course }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dropBlack.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        avatarSection
                        nameSection
                        vibeSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.dropTextSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveEdits() }
                        .foregroundColor(.dropOrange)
                        .fontWeight(.semibold)
                        .disabled(profileVM.isSaving)
                }
            }
            .sheet(isPresented: $showPicker) {
                ImagePicker(image: $selectedImage, source: .library)
            }
        }
        .onAppear { prefill() }
    }

    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                if let img = selectedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())
                } else {
                    AvatarView(user: profileVM.user, size: 90, showStreakRing: false)
                }

                Button {
                    showPicker = true
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.dropOrange)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Color.dropBlack, lineWidth: 2))
                }
            }
        }
    }

    private var nameSection: some View {
        VStack(spacing: 14) {
            DROPTextField(
                placeholder: "Display Name",
                text: $displayName,
                icon: "person.fill"
            )
            DROPTextField(
                placeholder: "Course / Major (optional)",
                text: $course,
                icon: "graduationcap.fill"
            )
        }
    }

    private var vibeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("VIBE")
                .font(DROPFont.label(10))
                .foregroundColor(.dropTextSecondary)
                .tracking(3)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(VibeOption.allCases, id: \.self) { option in
                    Button {
                        selectedVibe = option
                        HapticFeedback.selection()
                    } label: {
                        Text(option.rawValue)
                            .font(DROPFont.body(14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedVibe == option ? Color.dropOrange.opacity(0.2) : Color.dropCard)
                            .cornerRadius(Radius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.md)
                                    .strokeBorder(selectedVibe == option ? Color.dropOrange : Color.clear, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    private func prefill() {
        displayName = profileVM.user?.displayName ?? ""
        course = profileVM.user?.course ?? ""
        if let raw = profileVM.user?.currentVibe {
            selectedVibe = VibeOption(rawValue: raw)
        }
    }

    private func saveEdits() {
        Task {
            await profileVM.saveEdits(
                displayName: displayName.trimmed,
                course: course.trimmed,
                vibe: selectedVibe?.rawValue,
                image: selectedImage,
                userId: appState.currentUser?.id ?? "",
                appState: appState
            )
            dismiss()
        }
    }
}

// MARK: - Badges View (full collection)
struct BadgesView: View {

    let earnedIds: [String]
    @Environment(\.dismiss) private var dismiss

    private let allBadges = BadgeModel.all

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dropBlack.ignoresSafeArea()
                ScrollView {
                    BadgeGridView(earnedIds: earnedIds)
                        .padding(16)
                }
            }
            .navigationTitle("Badges")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.dropOrange)
                }
            }
        }
    }
}

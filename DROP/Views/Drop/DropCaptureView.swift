import SwiftUI
import PhotosUI

// MARK: - Drop Capture View
// Full-screen capture flow shown when a Drop is live.
// Receives drop + shared DropViewModel; navigates internally through capture steps.
struct DropCaptureView: View {

    let drop: DropModel
    @ObservedObject var dropVM: DropViewModel

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    // Capture state
    @State private var capturedImage: UIImage?
    @State private var showImagePicker = false
    @State private var pickerSource: PickerSource = .library
    @State private var caption: String = ""
    @State private var selectedZone: ZoneType?
    @State private var selectedVibe: VibeTag?
    @State private var showZonePicker = false
    @State private var showVibePicker = false
    @State private var captionFocused = false
    @FocusState private var isTyping: Bool

    private var isGrace: Bool { drop.isInGracePeriod }
    private var canSubmit: Bool {
        capturedImage != nil && selectedZone != nil && !dropVM.isSubmitting
    }

    var body: some View {
        ZStack {
            Color.dropBlack.ignoresSafeArea()

            if dropVM.hasSubmitted {
                DropSuccessView(dropVM: dropVM)
                    .environmentObject(appState)
            } else {
                captureContent
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $capturedImage, source: pickerSource)
        }
        .sheet(isPresented: $showZonePicker) {
            zonePicker
        }
        .sheet(isPresented: $showVibePicker) {
            vibePicker
        }
    }

    // MARK: - Main Capture Content
    private var captureContent: some View {
        VStack(spacing: 0) {
            captureHeader
            ScrollView {
                VStack(spacing: 20) {
                    promptCard
                    imageArea
                    metadataSection
                    captionSection
                    submitSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
    }

    // MARK: - Header
    private var captureHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text(isGrace ? "LATE DROP" : "DROP NOW")
                    .font(DROPFont.label(11))
                    .foregroundColor(isGrace ? .dropLate : .dropOrange)
                    .tracking(2)

                MiniCountdownView(
                    timeRemaining: isGrace ? drop.graceTimeRemaining : drop.timeRemaining,
                    isGrace: isGrace
                )
            }

            Spacer()

            // Placeholder to balance layout
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Prompt Card
    private var promptCard: some View {
        HStack(spacing: 12) {
            Text(drop.promptIcon)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 4) {
                Text(drop.title)
                    .font(DROPFont.label(10))
                    .foregroundColor(isGrace ? .dropLate : .dropOrange)
                    .tracking(2)

                Text(drop.prompt)
                    .font(DROPFont.headline(15))
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .padding(14)
        .background(isGrace ? Color.dropLate.opacity(0.1) : Color.dropOrange.opacity(0.1))
        .cornerRadius(Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .strokeBorder(isGrace ? Color.dropLate.opacity(0.3) : Color.dropOrange.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Image Capture Area
    private var imageArea: some View {
        ZStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .clipped()
                    .cornerRadius(Radius.lg)
                    .overlay(
                        // Retake button
                        VStack {
                            HStack {
                                Spacer()
                                Button {
                                    capturedImage = nil
                                } label: {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .padding(12)
                            }
                            Spacer()
                        }
                    )
            } else {
                // Empty capture placeholder
                RoundedRectangle(cornerRadius: Radius.lg)
                    .fill(Color.dropCard)
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .overlay(
                        VStack(spacing: 24) {
                            Text("📸")
                                .font(.system(size: 48))

                            Text("Add your Drop photo")
                                .font(DROPFont.body())
                                .foregroundColor(.dropTextSecondary)

                            HStack(spacing: 12) {
                                cameraButton
                                libraryButton
                            }
                        }
                    )
            }
        }
    }

    private var cameraButton: some View {
        Button {
            pickerSource = .camera
            showImagePicker = true
            HapticFeedback.impact(.medium)
        } label: {
            Label("Camera", systemImage: "camera.fill")
                .font(DROPFont.label(13))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.dropOrange)
                .cornerRadius(Radius.pill)
        }
    }

    private var libraryButton: some View {
        Button {
            pickerSource = .library
            showImagePicker = true
            HapticFeedback.impact(.medium)
        } label: {
            Label("Library", systemImage: "photo.on.rectangle")
                .font(DROPFont.label(13))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(Radius.pill)
        }
    }

    // MARK: - Metadata (Zone + Vibe)
    private var metadataSection: some View {
        HStack(spacing: 12) {
            // Zone picker trigger
            Button {
                showZonePicker = true
                HapticFeedback.selection()
            } label: {
                HStack(spacing: 8) {
                    Text(selectedZone?.emoji ?? "📍")
                    Text(selectedZone?.rawValue.capitalized ?? "Pick Zone")
                        .font(DROPFont.body(14))
                        .foregroundColor(selectedZone != nil ? .white : .dropTextSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.dropTextSecondary)
                }
                .padding(14)
                .background(Color.dropCard)
                .cornerRadius(Radius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .strokeBorder(selectedZone != nil ? Color.dropOrange.opacity(0.5) : Color.clear, lineWidth: 1)
                )
            }

            // Vibe picker trigger
            Button {
                showVibePicker = true
                HapticFeedback.selection()
            } label: {
                HStack(spacing: 8) {
                    Text(selectedVibe?.rawValue ?? "Vibe")
                        .font(DROPFont.body(14))
                        .foregroundColor(selectedVibe != nil ? .white : .dropTextSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.dropTextSecondary)
                }
                .padding(14)
                .background(Color.dropCard)
                .cornerRadius(Radius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .strokeBorder(selectedVibe != nil ? Color.dropOrange.opacity(0.5) : Color.clear, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Caption
    private var captionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Caption")
                    .font(DROPFont.label(11))
                    .foregroundColor(.dropTextSecondary)
                    .tracking(1)
                Spacer()
                Text("\(caption.count)/\(DropConfig.maxCaptionLength)")
                    .font(DROPFont.body(12))
                    .foregroundColor(caption.count > DropConfig.maxCaptionLength - 20 ? .dropOrange : .dropTextSecondary)
            }

            ZStack(alignment: .topLeading) {
                if caption.isEmpty {
                    Text("Say something about your Drop... (optional)")
                        .font(DROPFont.body(15))
                        .foregroundColor(.dropTextSecondary)
                        .padding(.top, 14)
                        .padding(.leading, 16)
                }

                TextEditor(text: $caption)
                    .font(DROPFont.body(15))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80, maxHeight: 120)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .focused($isTyping)
                    .onChange(of: caption) { _, newVal in
                        if newVal.count > DropConfig.maxCaptionLength {
                            caption = String(newVal.prefix(DropConfig.maxCaptionLength))
                        }
                    }
            }
            .background(Color.dropCard)
            .cornerRadius(Radius.md)
        }
    }

    // MARK: - Submit
    private var submitSection: some View {
        VStack(spacing: 12) {
            if dropVM.isSubmitting {
                VStack(spacing: 10) {
                    ProgressView(value: dropVM.submitProgress)
                        .progressViewStyle(.linear)
                        .tint(Color.dropOrange)
                        .padding(.horizontal)

                    Text("Uploading your Drop…")
                        .font(DROPFont.body(13))
                        .foregroundColor(.dropTextSecondary)
                }
            }

            if let err = dropVM.submissionError {
                Text(err)
                    .font(DROPFont.body(13))
                    .foregroundColor(.dropRed)
                    .multilineTextAlignment(.center)
            }

            Button {
                submit()
            } label: {
                HStack(spacing: 10) {
                    if dropVM.isSubmitting {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                    Text(dropVM.isSubmitting ? "Sending…" : "Send Drop")
                        .font(DROPFont.headline(17))
                }
                .foregroundColor(.white)
                .primaryButton()
            }
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.45)
            .padding(.horizontal, 0)

            if isGrace {
                Text("Late Drops unlock the feed but don't add to your streak.")
                    .font(DROPFont.body(12))
                    .foregroundColor(.dropTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Zone Picker Sheet
    private var zonePicker: some View {
        ZStack {
            Color.dropBlack.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Pick your Zone")
                    .font(DROPFont.headline())
                    .foregroundColor(.white)
                    .padding()

                Divider().background(Color.dropDivider)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(ZoneType.allCases, id: \.self) { zone in
                            Button {
                                selectedZone = zone
                                showZonePicker = false
                                HapticFeedback.selection()
                            } label: {
                                HStack(spacing: 14) {
                                    Text(zone.emoji)
                                        .font(.system(size: 28))

                                    Text(zone.rawValue.capitalized)
                                        .font(DROPFont.body())
                                        .foregroundColor(.white)

                                    Spacer()

                                    if selectedZone == zone {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.dropOrange)
                                    }
                                }
                                .padding(14)
                                .background(selectedZone == zone ? Color.dropOrange.opacity(0.1) : Color.dropCard)
                                .cornerRadius(Radius.md)
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Vibe Picker Sheet
    private var vibePicker: some View {
        ZStack {
            Color.dropBlack.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Pick your Vibe")
                    .font(DROPFont.headline())
                    .foregroundColor(.white)
                    .padding()

                Divider().background(Color.dropDivider)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(VibeTag.allCases, id: \.self) { vibe in
                        Button {
                            selectedVibe = vibe
                            showVibePicker = false
                            HapticFeedback.selection()
                        } label: {
                            Text(vibe.rawValue)
                                .font(DROPFont.body(15))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(selectedVibe == vibe ? Color.dropOrange.opacity(0.2) : Color.dropCard)
                                .cornerRadius(Radius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.md)
                                        .strokeBorder(selectedVibe == vibe ? Color.dropOrange : Color.clear, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(16)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Submit Action
    private func submit() {
        guard let image = capturedImage, let zone = selectedZone else { return }

        HapticFeedback.impact(.heavy)
        isTyping = false

        Task {
            await dropVM.submitDrop(
                image: image,
                caption: caption.trimmed,
                zone: zone,
                vibe: selectedVibe,
                userId: appState.currentUser?.id ?? "",
                appState: appState
            )
        }
    }
}

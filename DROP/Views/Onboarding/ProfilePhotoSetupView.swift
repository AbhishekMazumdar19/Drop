import SwiftUI

struct ProfilePhotoSetupView: View {
    @ObservedObject var vm: OnboardingViewModel
    let onContinue: () -> Void

    @State private var showPicker = false
    @State private var pickerSource: ImagePicker.PickerSource = .library

    var body: some View {
        OnboardingStepView(
            title: "Add your DP",
            subtitle: "Let the campus put a face to the name.",
            stepIndex: 3,
            totalSteps: 5
        ) {
            VStack(spacing: 32) {
                // Photo area
                Button {
                    pickerSource = .library
                    showPicker = true
                } label: {
                    ZStack {
                        if let img = vm.profileImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 140, height: 140)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.dropSurface)
                                .frame(width: 140, height: 140)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 28))
                                            .foregroundStyle(LinearGradient.dropFireGradient)

                                        Text("Add photo")
                                            .font(DROPFont.body(13))
                                            .foregroundColor(.dropTextSecondary)
                                    }
                                )
                        }

                        // Orange ring
                        Circle()
                            .strokeBorder(
                                vm.profileImage != nil ? LinearGradient.dropFireGradient : LinearGradient(colors: [Color.dropSurface], startPoint: .top, endPoint: .bottom),
                                lineWidth: 3
                            )
                            .frame(width: 148, height: 148)
                    }
                }
                .animation(.dropSnap, value: vm.profileImage != nil)

                // Source options
                HStack(spacing: 12) {
                    sourceButton(icon: "photo.fill", label: "Library") {
                        pickerSource = .library
                        showPicker = true
                    }
                    sourceButton(icon: "camera.fill", label: "Camera") {
                        pickerSource = .camera
                        showPicker = true
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    if vm.profileImage != nil {
                        Button {
                            Task { await vm.uploadProfilePhoto() }
                        } label: {
                            Group {
                                if vm.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Save & Continue")
                                        .font(DROPFont.headline(17))
                                        .foregroundColor(.white)
                                }
                            }
                            .primaryButton()
                        }
                        .disabled(vm.isLoading)
                        .onChange(of: vm.profileImageURL) { _, url in
                            if url != nil { onContinue() }
                        }
                    }

                    Button(onContinue) {
                        Text(vm.profileImage != nil ? "Skip for now" : "Skip — add later")
                            .font(DROPFont.body(14))
                            .foregroundColor(.dropTextSecondary)
                            .ghostButton()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .padding(.top, 32)
            .sheet(isPresented: $showPicker) {
                ImagePicker(selectedImage: $vm.profileImage, source: pickerSource)
                    .ignoresSafeArea()
            }
        }
    }

    private func sourceButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(label)
                    .font(DROPFont.body(14))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.dropCard)
            .cornerRadius(Radius.sm)
        }
    }
}

import SwiftUI

struct VibeSetupView: View {
    @ObservedObject var vm: OnboardingViewModel
    let onContinue: () -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        OnboardingStepView(
            title: "Set your vibe",
            subtitle: "How are you showing up today?",
            stepIndex: 4,
            totalSteps: 5
        ) {
            VStack(spacing: 24) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(VibeOption.allCases) { vibe in
                        vibeCell(vibe)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        Task {
                            await vm.saveProfile(appState: AppState())
                            onContinue()
                        }
                    } label: {
                        Group {
                            if vm.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Continue")
                                    .font(DROPFont.headline(17))
                                    .foregroundColor(.white)
                            }
                        }
                        .primaryButton(isLoading: vm.isLoading)
                    }
                    .disabled(vm.isLoading)

                    if vm.selectedVibe != nil {
                        Button {
                            vm.selectedVibe = nil
                            onContinue()
                        } label: {
                            Text("Skip")
                                .font(DROPFont.body(14))
                                .foregroundColor(.dropTextSecondary)
                        }
                    } else {
                        Button(onContinue) {
                            Text("Skip for now")
                                .font(DROPFont.body(14))
                                .foregroundColor(.dropTextSecondary)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func vibeCell(_ vibe: VibeOption) -> some View {
        let isSelected = vm.selectedVibe == vibe

        return Button {
            withAnimation(.dropSnap) {
                vm.selectedVibe = isSelected ? nil : vibe
            }
            HapticFeedback.selection()
        } label: {
            VStack(spacing: 8) {
                Text(vibe.emoji)
                    .font(.system(size: 28))

                Text(vibe.rawValue)
                    .font(DROPFont.body(12))
                    .foregroundColor(isSelected ? .white : .dropTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.dropOrange.opacity(0.2) : Color.dropCard)
            .cornerRadius(Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .strokeBorder(isSelected ? Color.dropOrange : Color.clear, lineWidth: 1.5)
            )
        }
    }
}

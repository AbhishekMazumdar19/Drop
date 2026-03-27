import SwiftUI

struct CampusPickerOnboardingView: View {

    @ObservedObject var vm: OnboardingViewModel
    let onContinue: () -> Void

    @State private var searchText: String = ""

    private var filteredCampuses: [CampusModel] {
        if searchText.isEmpty { return vm.campuses }
        return vm.campuses.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.city.localizedCaseInsensitiveContains(searchText) ||
            $0.shortCode.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        OnboardingStepView(
            title: "Your campus",
            subtitle: "Choose where you drop.",
            stepIndex: 1,
            totalSteps: 5
        ) {
            VStack(spacing: 16) {
                // Search
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.dropTextTertiary)
                    TextField("Search campus...", text: $searchText)
                        .font(DROPFont.body())
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                }
                .padding(12)
                .background(Color.dropSurface)
                .cornerRadius(Radius.sm)
                .padding(.horizontal, 24)
                .padding(.top, 24)

                // Campus list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredCampuses) { campus in
                            campusRow(campus)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // Continue
                Button {
                    guard vm.canProceedFromCampus else { return }
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(DROPFont.headline(17))
                        .foregroundColor(.white)
                        .primaryButton()
                }
                .disabled(!vm.canProceedFromCampus)
                .opacity(vm.canProceedFromCampus ? 1 : 0.4)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func campusRow(_ campus: CampusModel) -> some View {
        let isSelected = vm.selectedCampus?.id == campus.id

        return Button {
            vm.selectedCampus = campus
            HapticFeedback.selection()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? LinearGradient.dropFireGradient : LinearGradient(colors: [Color.dropSurface], startPoint: .top, endPoint: .bottom))
                        .frame(width: 40, height: 40)

                    Text(campus.shortCode.prefix(2))
                        .font(DROPFont.label(11))
                        .foregroundColor(isSelected ? .white : .dropTextSecondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(campus.name)
                        .font(DROPFont.body())
                        .foregroundColor(.white)
                    Text(campus.city + ", " + campus.country)
                        .font(DROPFont.caption(11))
                        .foregroundColor(.dropTextSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(LinearGradient.dropFireGradient)
                        .font(.system(size: 20))
                }
            }
            .padding(14)
            .background(isSelected ? Color.dropOrange.opacity(0.1) : Color.dropCard)
            .cornerRadius(Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .strokeBorder(isSelected ? Color.dropOrange : Color.clear, lineWidth: 1)
            )
        }
        .animation(.dropSnap, value: isSelected)
    }
}

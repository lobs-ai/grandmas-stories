import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.warmBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "book.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(AppColors.warmOrange)
                            .accessibilityHidden(true)

                        Text("Grandma's Stories")
                            .font(.largeTitle.bold())

                        Text("What story would you like to tell today?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 40)

                    // Action Buttons
                    VStack(spacing: 16) {
                        NavigationLink(destination: CategorySelectionView()) {
                            HomeActionButton(
                                title: "Record a Story (with question)",
                                icon: "bubble.left.and.text.bubble.right",
                                color: AppColors.warmOrange
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Record a story with a question prompt")
                        .accessibilityHint("Browse categories and get a suggested question to answer")

                        NavigationLink(destination: FreestyleRecordingView()) {
                            HomeActionButton(
                                title: "Record a Story (freestyle)",
                                icon: "mic.circle",
                                color: AppColors.freestyleAccent
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Record a freestyle story")
                        .accessibilityHint("Record any story you want, without a question prompt")

                        NavigationLink(destination: FamilySharingSetupView()) {
                            HomeActionButton(
                                title: "Update Family",
                                icon: "person.2.circle",
                                color: Color(red: 0.3, green: 0.65, blue: 0.4)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Update your family members")
                        .accessibilityHint("Add or change who your stories are shared with")
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct HomeActionButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(.white)
                .frame(width: 44)
                .accessibilityHidden(true)

            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, minHeight: 80)
        .background(color.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

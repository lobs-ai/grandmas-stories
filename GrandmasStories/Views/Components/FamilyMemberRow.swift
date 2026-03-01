import SwiftUI

/// Reusable row displaying a family member's name and phone number.
struct FamilyMemberRow: View {
    let member: FamilyMember
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.purple)

            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.system(size: 17, weight: .semibold))

                if let phone = member.phoneNumber, !phone.isEmpty {
                    Text(phone)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

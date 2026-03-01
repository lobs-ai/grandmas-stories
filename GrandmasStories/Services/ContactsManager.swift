import Contacts
import Foundation

/// Manages contact access and converts CNContacts into FamilyMember candidates.
final class ContactsManager {

    // MARK: - Permission

    enum ContactsPermissionStatus {
        case granted, denied, notDetermined
    }

    var permissionStatus: ContactsPermissionStatus {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:          return .granted
        case .denied, .restricted: return .denied
        case .notDetermined:       return .notDetermined
        @unknown default:          return .denied
        }
    }

    /// Requests contacts permission. Returns true if granted.
    func requestPermission() async -> Bool {
        let store = CNContactStore()
        do {
            return try await store.requestAccess(for: .contacts)
        } catch {
            return false
        }
    }

    // MARK: - Fetch

    /// Fetches contacts that have at least one phone number and returns them as FamilyMember candidates.
    /// Returns an empty array if permission is denied.
    func fetchFamilyMemberCandidates() async -> [FamilyMember] {
        guard permissionStatus == .granted else { return [] }

        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor
        ]

        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        request.sortOrder = .familyName

        var members: [FamilyMember] = []
        let store = CNContactStore()

        do {
            try store.enumerateContacts(with: request) { contact, _ in
                guard !contact.phoneNumbers.isEmpty else { return }
                let phone = contact.phoneNumbers.first?.value.stringValue
                let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                let name = fullName.isEmpty ? contact.identifier : fullName
                let member = FamilyMember(
                    name: name,
                    phoneNumber: phone,
                    contactIdentifier: contact.identifier
                )
                members.append(member)
            }
        } catch {
            return []
        }

        return members
    }
}

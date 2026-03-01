import SwiftUI
import Contacts

/// Setup step for choosing a sharing method and adding family members.
struct FamilySharingSetupView: View {
    @EnvironmentObject var settingsStore: SettingsStore

    // MARK: - State

    @State private var selectedMethod: SharingMethod = .iMessage
    @State private var familyMembers: [FamilyMember] = []

    // Manual add form
    @State private var showManualForm = false
    @State private var manualName = ""
    @State private var manualPhone = ""

    // Contact picker
    @State private var showContactPicker = false

    let onFinish: () -> Void

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                sharingMethodSection
                familyMembersSection

                if showManualForm {
                    manualAddForm
                }

                Spacer(minLength: 24)

                finishButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showContactPicker) {
            ContactPickerView(contactsManager: ContactsManager()) { selected in
                addMemberIfNew(selected)
                showContactPicker = false
            }
        }
    }

    // MARK: - Sharing Method Section

    private var sharingMethodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How would you like to share stories?")
                .font(.system(size: 20, weight: .bold))

            HStack(spacing: 12) {
                sharingButton(method: .iMessage, icon: "message.fill", label: "iMessage")
                sharingButton(method: .whatsApp, icon: "phone.fill", label: "WhatsApp")
            }
        }
    }

    private func sharingButton(method: SharingMethod, icon: String, label: String) -> some View {
        Button(action: { selectedMethod = method }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                if selectedMethod == method {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(selectedMethod == method ? Color.purple.opacity(0.15) : Color(.systemGray6))
            .foregroundStyle(selectedMethod == method ? .purple : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selectedMethod == method ? Color.purple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Family Members Section

    private var familyMembersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Who should receive your stories?")
                .font(.system(size: 20, weight: .bold))

            if familyMembers.isEmpty {
                Text("No family members added yet.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(familyMembers) { member in
                    FamilyMemberRow(member: member) {
                        removeMember(member)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            removeMember(member)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    Divider()
                }
            }

            HStack(spacing: 12) {
                Button(action: { showContactPicker = true }) {
                    Label("Add from Contacts", systemImage: "person.crop.circle.badge.plus")
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button(action: {
                    withAnimation { showManualForm.toggle() }
                }) {
                    Label("Add Manually", systemImage: "pencil")
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Manual Add Form

    private var manualAddForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add Family Member")
                .font(.system(size: 17, weight: .semibold))

            TextField("Name", text: $manualName)
                .textFieldStyle(.roundedBorder)
                .textContentType(.name)

            TextField("Phone Number", text: $manualPhone)
                .textFieldStyle(.roundedBorder)
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)

            HStack {
                Button("Cancel") {
                    withAnimation {
                        showManualForm = false
                        manualName = ""
                        manualPhone = ""
                    }
                }
                .foregroundStyle(.secondary)

                Spacer()

                Button("Add") {
                    let trimmedName = manualName.trimmingCharacters(in: .whitespaces)
                    guard !trimmedName.isEmpty else { return }
                    let member = FamilyMember(
                        name: trimmedName,
                        phoneNumber: manualPhone.trimmingCharacters(in: .whitespaces).isEmpty ? nil : manualPhone.trimmingCharacters(in: .whitespaces)
                    )
                    withAnimation {
                        familyMembers.append(member)
                        manualName = ""
                        manualPhone = ""
                        showManualForm = false
                    }
                }
                .disabled(manualName.trimmingCharacters(in: .whitespaces).isEmpty)
                .fontWeight(.semibold)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Finish Button

    private var finishButton: some View {
        Button(action: finishSetup) {
            Text("Finish Setup")
                .font(.system(size: 20, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
        }
        .buttonStyle(.borderedProminent)
        .tint(.purple)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .disabled(familyMembers.isEmpty)
    }

    // MARK: - Actions

    private func finishSetup() {
        var updated = settingsStore.settings
        updated.sharingMethod = selectedMethod
        updated.familyMembers = familyMembers
        updated.hasCompletedSetup = true
        settingsStore.save(updated)
        onFinish()
    }

    private func removeMember(_ member: FamilyMember) {
        familyMembers.removeAll { $0.id == member.id }
    }

    private func addMemberIfNew(_ member: FamilyMember) {
        guard !familyMembers.contains(where: { $0.id == member.id }) else { return }
        familyMembers.append(member)
    }
}

// MARK: - ContactPickerView

struct ContactPickerView: View {
    let contactsManager: ContactsManager
    let onSelect: (FamilyMember) -> Void

    @State private var contacts: [FamilyMember] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var permissionDenied = false
    @Environment(\.dismiss) private var dismiss

    var filtered: [FamilyMember] {
        guard !searchText.isEmpty else { return contacts }
        return contacts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.phoneNumber?.contains(searchText) == true)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading contacts…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if permissionDenied {
                    ContentUnavailableView(
                        "Contacts Access Denied",
                        systemImage: "person.slash",
                        description: Text("Please enable contacts access in Settings.")
                    )
                } else if contacts.isEmpty {
                    ContentUnavailableView(
                        "No Contacts Found",
                        systemImage: "person.crop.circle",
                        description: Text("No contacts with phone numbers.")
                    )
                } else {
                    List(filtered) { contact in
                        Button(action: { onSelect(contact) }) {
                            FamilyMemberRow(member: contact, onDelete: {})
                        }
                        .buttonStyle(.plain)
                    }
                    .searchable(text: $searchText, prompt: "Search contacts")
                }
            }
            .navigationTitle("Add from Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task {
            await loadContacts()
        }
    }

    private func loadContacts() async {
        let status = contactsManager.permissionStatus
        if status == .notDetermined {
            let granted = await contactsManager.requestPermission()
            if !granted {
                permissionDenied = true
                isLoading = false
                return
            }
        } else if status == .denied {
            permissionDenied = true
            isLoading = false
            return
        }

        let results = await contactsManager.fetchFamilyMemberCandidates()
        contacts = results
        isLoading = false
    }
}

//
//  EditProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI
import SwiftData

/// A view for editing the details of an existing `Prospect`.
///
/// This form allows users to:
/// - Update the prospect’s full name and address
/// - Reassign the prospect to a different list (e.g., "Customers")
/// - View the full knock history of the prospect
struct EditProspectView: View {
    /// The prospect instance to be edited, bound to the form fields.
    @Bindable var prospect: Prospect
    
    /// Used to dismiss the view when editing is finished.
    @Environment(\.presentationMode) var presentationMode

    /// Predefined list categories a prospect can belong to.
    let allLists = ["Prospects", "Customers"]
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var showKnockHistory = false
    @State private var showNotes = false

    var body: some View {
        Form {
            // MARK: - Prospect Info Section
            Section(header: Text("Prospect Details")) {
                TextField("Full Name", text: $prospect.fullName)
                TextField("Address", text: $prospect.address)
            }

            // MARK: - List Selector
            Picker("Current List", selection: $prospect.list) {
                ForEach(allLists, id: \.self) { listName in
                    Text(listName)
                }
            }
            .pickerStyle(.menu)

            // MARK: - Knock History Section (Expandable)
            Section {
                DisclosureGroup(isExpanded: $showKnockHistory) {
                    KnockingHistoryView(prospect: prospect)
                } label: {
                    Text("Knock History")
                        .fontWeight(.semibold)
                }
            }

            // MARK: - Notes Section (Expandable)
            Section {
                DisclosureGroup(isExpanded: $showNotes) {
                    ForEach(prospect.notes.sorted(by: { $0.date > $1.date }), id: \.date) { note in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.content)
                                .font(.body)
                            Text("— \(note.authorEmail), \(note.date.formatted(.dateTime.month().day().hour().minute()))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }

                    AddNoteView(prospect: prospect)
                } label: {
                    Text("Notes")
                        .fontWeight(.semibold)
                }
            }
        }
        .navigationTitle("Edit Prospect")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    deleteProspect()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
    
    private func deleteProspect() {
        // 1. Delete the prospect from SwiftData
        modelContext.delete(prospect)

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete prospect from SwiftData: \(error)")
        }

        // 2. Dismiss the view
        presentationMode.wrappedValue.dismiss()
    }
}

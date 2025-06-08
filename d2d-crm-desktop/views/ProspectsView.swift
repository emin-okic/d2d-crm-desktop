//
//  ProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI
import SwiftData

/// A view that displays and manages a list of prospects associated with the logged-in user.
/// Users can filter by list type (e.g., "Prospects", "Customers"), add new prospects, and tap
/// a prospect to edit its details.
struct ProspectsView: View {
    @Environment(\.modelContext) private var modelContext

    @Binding var selectedList: String
    var onSave: () -> Void
    var userEmail: String

    @State private var showingAddProspect = false
    @State private var selectedProspect: Set<Prospect> = []
    @State private var selectedProspectIDs: Set<PersistentIdentifier> = []

    @Query private var prospects: [Prospect]

    init(selectedList: Binding<String>, userEmail: String, onSave: @escaping () -> Void) {
        _selectedList = selectedList
        self.userEmail = userEmail
        self.onSave = onSave
        _prospects = Query(filter: #Predicate<Prospect> { $0.userEmail == userEmail })
    }

    var filteredProspects: [Prospect] {
        selectedList == "All" ? prospects : prospects.filter { $0.list == selectedList }
    }

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading) {
                // List filter controls
                Picker("List", selection: $selectedList) {
                    Text("All").tag("All")
                    Text("Prospects").tag("Prospects")
                    Text("Customers").tag("Customers")
                }
                .pickerStyle(.segmented)
                .padding()

                // Table-style layout for desktop
                Table(filteredProspects, selection: $selectedProspectIDs) {
                    TableColumn("Name", value: \.fullName)
                    TableColumn("Address", value: \.address)
                    TableColumn("List") { prospect in
                        Text(prospect.list).foregroundColor(.secondary)
                    }
                    TableColumn("Knocks") { prospect in
                        Text("\(prospect.count)")
                    }
                }
                .contextMenu(forSelectionType: Prospect.self) { selection in
                    if let prospect = selection.first {
                        Button("Edit") {
                            selectedProspectIDs = [prospect.persistentModelID]
                        }
                        Button("Delete", role: .destructive) {
                            modelContext.delete(prospect)
                            try? modelContext.save()
                        }
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        showingAddProspect = true
                    } label: {
                        Label("New Prospect", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let selectedID = selectedProspectIDs.first,
               let selected = prospects.first(where: { $0.persistentModelID == selectedID }) {
                EditProspectView(prospect: selected)
            } else {
                ContentUnavailableView("Select a Prospect", systemImage: "person.crop.circle")
            }
        }
        .sheet(isPresented: $showingAddProspect) {
            NewProspectView(
                selectedList: $selectedList,
                onSave: {
                    showingAddProspect = false
                    onSave()
                },
                userEmail: userEmail
            )
        }
    }
}

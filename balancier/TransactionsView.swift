import SwiftUI
import CoreData

struct TransactionsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
    ) private var allEntries: FetchedResults<Entry>

    @State private var searchText = ""
    @State private var showingAddEntry = false

    private var filteredEntries: [Entry] {
        if searchText.isEmpty {
            return Array(allEntries)
        }
        return allEntries.filter { entry in
            entry.displayTitle.localizedCaseInsensitiveContains(searchText) ||
            entry.displayAccount.localizedCaseInsensitiveContains(searchText) ||
            (entry.note?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var groupedEntries: [(date: Date, entries: [Entry])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: filteredEntries) { entry in
            calendar.startOfDay(for: entry.date)
        }
        return groups
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
    }

    private func dayTotal(entries: [Entry]) -> Double {
        entries.reduce(0.0) { acc, entry in
            switch entry.type {
            case .expense: return acc - entry.amount
            case .income: return acc + entry.amount
            case .transfer: return acc
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allEntries.isEmpty {
                    ContentUnavailableView(
                        "Нет операций",
                        systemImage: "list.bullet",
                        description: Text("Добавьте первую операцию через кнопку +")
                    )
                } else {
                    List {
                        ForEach(groupedEntries, id: \.date) { group in
                            Section {
                                ForEach(group.entries) { entry in
                                    EntryRowView(entry: entry)
                                        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 16))
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                deleteEntry(entry)
                                            } label: {
                                                Label("Удалить", systemImage: "trash")
                                            }
                                        }
                                }
                            } header: {
                                HStack {
                                    Text(group.date, style: .date)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    let total = dayTotal(entries: group.entries)
                                    Text(total, format: .currency(code: "RUB"))
                                        .font(.subheadline)
                                        .foregroundStyle(total >= 0 ? .green : .red)
                                }
                                .textCase(nil)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Операции")
            .searchable(text: $searchText, prompt: "Поиск")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddEntry = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddEntryView()
            }
        }
    }

    private func deleteEntry(_ entry: Entry) {
        viewContext.delete(entry)
        try? viewContext.save()
    }
}

#Preview {
    TransactionsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

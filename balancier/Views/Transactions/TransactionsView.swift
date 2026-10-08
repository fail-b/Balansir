import SwiftUI

struct TransactionsView: View {
    @Bindable var viewModel: TransactionsViewModel

    @State private var showingAddEntry = false
    @State private var addEntryVM: AddEntryViewModel?
    @State private var showingEditEntry = false
    @State private var editEntryVM: AddEntryViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.entries.isEmpty {
                    ContentUnavailableView(
                        "Нет операций",
                        systemImage: "list.bullet",
                        description: Text("Добавьте первую операцию через кнопку +")
                    )
                } else {
                    List {
                        ForEach(viewModel.groupedEntries, id: \.date) { group in
                            Section {
                                ForEach(group.entries) { entry in
                                    EntryRowView(entry: entry)
                                        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 16))
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            editEntryVM = viewModel.makeEditEntryViewModel(for: entry)
                                            showingEditEntry = true
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                Task { await viewModel.delete(entry) }
                                            } label: {
                                                Label("Удалить", systemImage: "trash")
                                            }
                                        }
                                }
                            } header: {
                                HStack {
                                    Text(group.date, style: .date)
                                        .font(.subheadline).fontWeight(.semibold).foregroundStyle(.primary)
                                    Spacer()
                                    let total = viewModel.dayTotal(entries: group.entries)
                                    Text((total as NSDecimalNumber).doubleValue, format: .currency(code: "RUB"))
                                        .font(.subheadline)
                                        .foregroundStyle(total >= 0 ? Theme.Colors.income : Theme.Colors.expense)
                                }
                                .textCase(nil)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Операции")
            .searchable(text: $viewModel.searchText, prompt: "Поиск")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addEntryVM = viewModel.makeAddEntryViewModel()
                        showingAddEntry = true
                    } label: {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry, onDismiss: { Task { await viewModel.load() } }) {
                if let vm = addEntryVM {
                    AddEntryView(viewModel: vm)
                }
            }
            .sheet(isPresented: $showingEditEntry, onDismiss: { Task { await viewModel.load() } }) {
                if let vm = editEntryVM {
                    AddEntryView(viewModel: vm)
                }
            }
            .task { await viewModel.load() }
            .alert("Ошибка", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

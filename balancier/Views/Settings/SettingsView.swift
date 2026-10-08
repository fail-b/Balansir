import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    @State private var showingAddAccount = false
    @State private var showingEditAccount = false
    @State private var addAccountVM: AccountFormViewModel?
    @State private var editAccountVM: AccountFormViewModel?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(viewModel.accounts) { account in
                        AccountSettingsRow(account: account, balance: viewModel.balances[account.id] ?? 0)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editAccountVM = viewModel.makeAccountFormViewModel(for: account)
                                showingEditAccount = true
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await viewModel.archive(account) }
                                } label: {
                                    Label("Скрыть", systemImage: "archivebox")
                                }
                            }
                    }
                    Button {
                        addAccountVM = viewModel.makeAccountFormViewModel(for: nil)
                        showingAddAccount = true
                    } label: {
                        Label("Добавить счёт", systemImage: "plus.circle")
                    }
                } header: { Text("Счета") }

                Section {
                    Picker("Тип", selection: $viewModel.selectedCategoryType) {
                        ForEach(CategoryType.allCases, id: \.self) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                    ForEach(viewModel.filteredCategories) { category in
                        HStack(spacing: Theme.Spacing.m) {
                            ZStack {
                                Circle()
                                    .fill((Color(hex: category.colorHex) ?? .orange).opacity(0.15))
                                    .frame(width: 32, height: 32)
                                AppIcon.image(named: category.iconName)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(hex: category.colorHex) ?? .orange)
                            }
                            Text(category.name).font(.callout)
                        }
                    }
                } header: { Text("Категории") }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Счета")
            .sheet(isPresented: $showingAddAccount, onDismiss: { Task { await viewModel.load() } }) {
                if let vm = addAccountVM { AccountFormView(viewModel: vm) }
            }
            .sheet(isPresented: $showingEditAccount, onDismiss: { Task { await viewModel.load() } }) {
                if let vm = editAccountVM { AccountFormView(viewModel: vm) }
            }
            .task { await viewModel.load() }
        }
    }
}

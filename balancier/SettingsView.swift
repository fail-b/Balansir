import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "sortOrder", ascending: true)],
        predicate: NSPredicate(format: "isArchived == NO")
    ) private var accounts: FetchedResults<Account>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "sortOrder", ascending: true)],
        predicate: NSPredicate(format: "isArchived == NO")
    ) private var categories: FetchedResults<Category>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
    ) private var allEntries: FetchedResults<Entry>

    @State private var showingAddAccount = false
    @State private var editingAccount: Account?
    @State private var selectedCategoryType = CategoryType.expense

    private var balances: [UUID: Double] {
        var result: [UUID: Double] = [:]
        for account in accounts {
            result[account.id] = account.initialBalance
        }
        for entry in allEntries {
            if let id = entry.fromAccount?.id { result[id, default: 0] -= entry.amount }
            if let id = entry.toAccount?.id { result[id, default: 0] += entry.amount }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            List {
                // Accounts section
                Section {
                    ForEach(accounts) { account in
                        AccountSettingsRow(
                            account: account,
                            balance: balances[account.id] ?? 0
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { editingAccount = account }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                archiveAccount(account)
                            } label: {
                                Label("Скрыть", systemImage: "archivebox")
                            }
                        }
                    }

                    Button {
                        showingAddAccount = true
                    } label: {
                        Label("Добавить счёт", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Счета")
                }

                // Categories section
                Section {
                    Picker("Тип", selection: $selectedCategoryType) {
                        ForEach(CategoryType.allCases, id: \.self) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                    ForEach(categories.filter { $0.categoryType == selectedCategoryType.rawValue }) { category in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(category.color.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: category.iconName)
                                    .font(.system(size: 14))
                                    .foregroundStyle(category.color)
                            }
                            Text(category.name)
                                .font(.callout)
                        }
                    }
                } header: {
                    Text("Категории")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Счета")
            .sheet(isPresented: $showingAddAccount) {
                AccountFormView()
            }
            .sheet(item: $editingAccount) { account in
                AccountFormView(account: account)
            }
        }
    }

    private func archiveAccount(_ account: Account) {
        account.isArchived = true
        try? viewContext.save()
    }
}

struct AccountSettingsRow: View {
    let account: Account
    let balance: Double

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(account.color)
                    .frame(width: 36, height: 36)
                Image(systemName: account.iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.callout)
                    .fontWeight(.medium)
                Text(account.type.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(balance, format: .currency(code: account.currency))
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(balance >= 0 ? Color.primary : Color.red)
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

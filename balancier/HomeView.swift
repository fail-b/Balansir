import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "sortOrder", ascending: true)],
        predicate: NSPredicate(format: "isArchived == NO")
    ) private var accounts: FetchedResults<Account>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
    ) private var allEntries: FetchedResults<Entry>

    @State private var showingAddEntry = false
    @State private var showingAddAccount = false

    private var balances: [UUID: Double] {
        var result: [UUID: Double] = [:]
        for account in accounts {
            result[account.id] = account.initialBalance
        }
        for entry in allEntries {
            if let id = entry.fromAccount?.id {
                result[id, default: 0] -= entry.amount
            }
            if let id = entry.toAccount?.id {
                result[id, default: 0] += entry.amount
            }
        }
        return result
    }

    private var totalBalance: Double {
        balances.values.reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    totalBalanceCard
                    accountsSection
                    recentEntriesSection
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Кошелёк")
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
            .sheet(isPresented: $showingAddAccount) {
                AccountFormView()
            }
        }
    }

    private var totalBalanceCard: some View {
        VStack(spacing: 6) {
            Text("Общий баланс")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(totalBalance, format: .currency(code: "RUB"))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(totalBalance >= 0 ? Color.primary : Color.red)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Счета")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(accounts) { account in
                        AccountCard(account: account, balance: balances[account.id] ?? 0)
                    }
                    Button {
                        showingAddAccount = true
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.title3)
                            Text("Добавить")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                        .frame(width: 140, height: 90)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Последние операции")
                .font(.headline)
                .padding(.horizontal)

            if allEntries.isEmpty {
                Text("Пока нет операций.\nНажмите + чтобы добавить.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(40)
            } else {
                let recent = Array(allEntries.prefix(20))
                LazyVStack(spacing: 0) {
                    ForEach(recent) { entry in
                        EntryRowView(entry: entry)
                        if entry.id != recent.last?.id {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }
        }
    }
}

struct AccountCard: View {
    let account: Account
    let balance: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: account.iconName)
                .font(.title3)
                .foregroundStyle(.white)
            Spacer()
            Text(account.name)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
            Text(balance, format: .currency(code: account.currency))
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding()
        .frame(width: 140, height: 90)
        .background(account.color.gradient, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct EntryRowView: View {
    let entry: Entry

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(entry.displayColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: entry.displayIcon)
                    .font(.system(size: 17))
                    .foregroundStyle(entry.displayColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayTitle)
                    .font(.callout)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    Text(entry.displayAccount)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let note = entry.note, !note.isEmpty {
                        Text("· \(note)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.formattedAmount)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(entry.amountColor)
                Text(entry.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

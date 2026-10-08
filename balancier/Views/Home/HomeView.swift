import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel

    @State private var showingAddEntry = false
    @State private var addEntryVM: AddEntryViewModel?
    @State private var showingAddAccount = false
    @State private var accountFormVM: AccountFormViewModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                    totalBalanceCard
                    accountsSection
                    recentEntriesSection
                }
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .navigationTitle("Кошелёк")
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
            .sheet(isPresented: $showingAddAccount, onDismiss: { Task { await viewModel.load() } }) {
                if let vm = accountFormVM {
                    AccountFormView(viewModel: vm)
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

    private var totalBalanceCard: some View {
        VStack(spacing: 6) {
            Text("Общий баланс").font(.subheadline).foregroundStyle(.secondary)
            Text(
                (viewModel.totalBalance as NSDecimalNumber).doubleValue,
                format: .currency(code: "RUB")
            )
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .foregroundStyle(viewModel.totalBalance >= 0 ? Color.primary : Theme.Colors.negativeBalance)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xxxl)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.xl))
        .padding(.horizontal)
    }

    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Счета").font(.headline).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.m) {
                    ForEach(viewModel.accounts) { account in
                        AccountCard(account: account, balance: viewModel.balances[account.id] ?? 0)
                    }
                    Button {
                        accountFormVM = viewModel.makeAccountFormViewModel()
                        showingAddAccount = true
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "plus").font(.title3)
                            Text("Добавить").font(.caption)
                        }
                        .foregroundStyle(.secondary)
                        .frame(width: 140, height: 90)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.l))
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Последние операции").font(.headline).padding(.horizontal)
            if viewModel.recentEntries.isEmpty {
                Text("Пока нет операций.\nНажмите + чтобы добавить.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity).padding(40)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.recentEntries) { entry in
                        EntryRowView(entry: entry)
                        if entry.id != viewModel.recentEntries.last?.id {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.l))
                .padding(.horizontal)
            }
        }
    }
}

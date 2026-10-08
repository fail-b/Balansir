import SwiftUI

struct AddEntryView: View {
    @Bindable var viewModel: AddEntryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Тип", selection: $viewModel.selectedType) {
                    ForEach(EntryType.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, Theme.Spacing.m)
                .onChange(of: viewModel.selectedType) { _, _ in viewModel.selectedCategory = nil }

                Text(viewModel.amountString == "0" ? "0 ₽" : formatAmount())
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(typeColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.l)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Divider()
                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        accountSection
                        if viewModel.selectedType == .transfer { toAccountSection } else { categorySection }
                        noteAndDateSection
                    }
                    .padding(.vertical, Theme.Spacing.l)
                }
                Divider()
                NumpadView(amountString: $viewModel.amountString)
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.top, Theme.Spacing.s)
                    .padding(.bottom, Theme.Spacing.xs)
            }
            .navigationTitle(viewModel.isEditing ? "Редактировать операцию" : "Новая операция")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") {
                        Task {
                            await viewModel.save()
                            if viewModel.errorMessage == nil { dismiss() }
                        }
                    }
                        .fontWeight(.semibold)
                        .disabled(!viewModel.canSave)
                }
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

    private var typeColor: Color {
        switch viewModel.selectedType {
        case .expense: return Theme.Colors.expense
        case .income: return Theme.Colors.income
        case .transfer: return Theme.Colors.transfer
        }
    }

    private func formatAmount() -> String {
        let value = (viewModel.amount as NSDecimalNumber).doubleValue
        return value.formatted(.currency(code: "RUB")
            .precision(.fractionLength(viewModel.amountString.contains(".") ? 2 : 0)))
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.selectedType == .transfer ? "Откуда" : "Счёт")
                .font(.subheadline).foregroundStyle(.secondary).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.accounts) { account in
                        AccountPillButton(account: account, isSelected: viewModel.selectedAccount?.id == account.id) {
                            viewModel.selectedAccount = account
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var toAccountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Куда").font(.subheadline).foregroundStyle(.secondary).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.accounts.filter { $0.id != viewModel.selectedAccount?.id }) { account in
                        AccountPillButton(account: account, isSelected: viewModel.selectedToAccount?.id == account.id) {
                            viewModel.selectedToAccount = account
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Категория").font(.subheadline).foregroundStyle(.secondary).padding(.horizontal)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(viewModel.filteredCategories) { category in
                    CategoryButton(category: category, isSelected: viewModel.selectedCategory?.id == category.id) {
                        viewModel.selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var noteAndDateSection: some View {
        VStack(spacing: Theme.Spacing.m) {
            HStack {
                Image(systemName: "text.quote").foregroundStyle(.secondary).frame(width: 24)
                TextField("Заметка", text: $viewModel.note)
            }
            .padding(.horizontal).padding(.vertical, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)

            DatePicker("Дата", selection: $viewModel.date, displayedComponents: .date)
                .padding(.horizontal).padding(.vertical, 10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
        }
    }
}

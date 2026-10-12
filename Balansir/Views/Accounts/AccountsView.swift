import SwiftUI

/// Вкладка «Счета» (§4.5): «Всего на счетах», список счетов, «+ Добавить счёт», категории.
struct AccountsView: View {
    @Bindable var viewModel: AccountsViewModel
    @Binding var isScrolled: Bool
    /// Тап по счёту → Главная с фильтром по нему (обрабатывает `ContentView`).
    let onSelectAccount: (UUID) -> Void

    @State private var accountFormVM: AccountFormViewModel?

    @State private var showingAddCategory = false
    @State private var showingEditCategory = false
    @State private var addCategoryVM: CategoryFormViewModel?
    @State private var editCategoryVM: CategoryFormViewModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    totalCard
                    if !viewModel.accounts.isEmpty {
                        accountsCard
                    }
                    addButton("Добавить счёт") {
                        viewModel.dismissUndo()
                        accountFormVM = viewModel.makeAccountFormViewModel(for: nil)
                    }
                    Text("Нажмите на счёт, чтобы увидеть его операции на главной.")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Colors.ink2)
                        .padding(.horizontal, Theme.Spacing.xs)

                    categoriesSection
                        .padding(.top, Theme.Spacing.xl)
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.top, Theme.Spacing.s)
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .background(Theme.Colors.background)
            .clearsBottomAccessory()
            .reportsScroll(to: $isScrolled)
            .navigationTitle("Счета")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        AppIcon.image(named: AppIcon.settings)
                    }
                }
            }
            .sheet(item: $accountFormVM, onDismiss: { Task { await viewModel.load() } }) { vm in
                AccountFormView(viewModel: vm)
            }
            .sheet(isPresented: $showingAddCategory, onDismiss: { Task { await viewModel.load() } }) {
                if let vm = addCategoryVM { CategoryFormView(viewModel: vm) }
            }
            .sheet(isPresented: $showingEditCategory, onDismiss: { Task { await viewModel.load() } }) {
                if let vm = editCategoryVM { CategoryFormView(viewModel: vm) }
            }
            .task { await viewModel.load() }
            .overlay(alignment: .bottom) { undoToast }
            .animation(.snappy, value: viewModel.recentlyArchived?.id)
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

    // MARK: - Всего на счетах

    private var totalCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Всего на счетах")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Colors.ink2)
            Text(MoneyFormatter.balance(viewModel.totalBalance))
                .font(Theme.Font.heroAmount)
                .tracking(Theme.Font.Tracking.heroAmount)
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(1)
                .minimumScaleFactor(Theme.Size.summaryMinScale)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: Theme.Radius.hero))
    }

    // MARK: - Список счетов

    private var accountsCard: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.accounts) { account in
                Button {
                    viewModel.dismissUndo()
                    onSelectAccount(account.id)
                } label: {
                    AccountRow(account: account, balance: viewModel.balance(for: account))
                        // Фон у строки — чтобы превью контекстного меню не было прозрачным.
                        .background(Theme.Colors.card)
                }
                .buttonStyle(.plain)
                // Долгое нажатие → меню; можно не отпуская провести палец на пункт (§«Минимум тапов»).
                .contextMenu {
                    Button {
                        viewModel.dismissUndo()
                        accountFormVM = viewModel.makeAccountFormViewModel(for: account)
                    } label: {
                        Label { Text("Изменить") } icon: { AppIcon.image(named: AppIcon.edit) }
                    }
                    Button(role: .destructive) {
                        Task { await viewModel.archive(account) }
                    } label: {
                        Label { Text("Скрыть") } icon: { AppIcon.image(named: AppIcon.archive) }
                    }
                }
                if account.id != viewModel.accounts.last?.id {
                    separator(inset: Theme.Accounts.separatorInset)
                }
            }
        }
        .background(Theme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    /// Плашка «Счёт скрыт · Отменить».
    @ViewBuilder
    private var undoToast: some View {
        if let archived = viewModel.recentlyArchived {
            UndoToast(title: "Счёт «\(archived.name)» скрыт") {
                Task { await viewModel.undoArchive() }
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.s)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            // Новый id — новый отсчёт; уход с экрана отменяет таймер.
            .task(id: archived.id) {
                guard (try? await Task.sleep(for: .seconds(Theme.Swipe.undoDuration))) != nil else { return }
                viewModel.dismissUndo()
            }
        }
    }

    // MARK: - Категории

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Категории")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Colors.ink)
                .padding(.leading, Theme.Spacing.xs)

            Picker("Тип", selection: $viewModel.selectedCategoryType) {
                ForEach(CategoryType.allCases, id: \.self) { type in
                    Text(type.title).tag(type)
                }
            }
            .pickerStyle(.segmented)

            if !viewModel.filteredCategories.isEmpty {
                VStack(spacing: 0) {
                    ForEach(viewModel.filteredCategories) { category in
                        categoryRow(category)
                        if category.id != viewModel.filteredCategories.last?.id {
                            separator(inset: Theme.Row.separatorInset)
                        }
                    }
                }
                .background(Theme.Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            }

            addButton("Добавить категорию") {
                addCategoryVM = viewModel.makeCategoryFormViewModel(for: nil)
                showingAddCategory = true
            }
        }
    }

    private func categoryRow(_ category: CategoryModel) -> some View {
        Button {
            editCategoryVM = viewModel.makeCategoryFormViewModel(for: category)
            showingEditCategory = true
        } label: {
            HStack(spacing: Theme.Spacing.m) {
                CategoryIcon(category: category, size: Theme.Row.iconSize)
                Text(category.name)
                    .font(Theme.Font.rowTitle)
                    .foregroundStyle(Theme.Colors.ink)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Row.verticalPadding)
            .background(Theme.Colors.card)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                editCategoryVM = viewModel.makeCategoryFormViewModel(for: category)
                showingEditCategory = true
            } label: {
                Label { Text("Изменить") } icon: { AppIcon.image(named: AppIcon.edit) }
            }
            Button(role: .destructive) {
                Task { await viewModel.archive(category) }
            } label: {
                Label { Text("Скрыть") } icon: { AppIcon.image(named: AppIcon.archive) }
            }
        }
    }

    // MARK: - Общие элементы

    /// Кнопка-карточка «+ Добавить …» (`accent`).
    private func addButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.s) {
                AppIcon.image(named: AppIcon.add)
                Text(title)
            }
            .font(Theme.Font.actionButton)
            .foregroundStyle(Theme.Colors.accent)
            .frame(maxWidth: .infinity)
            .frame(height: Theme.Accounts.addButtonHeight)
            .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
        .buttonStyle(.plain)
    }

    private func separator(inset: CGFloat) -> some View {
        Rectangle()
            .fill(Theme.Colors.separator)
            .frame(height: Theme.Size.hairline)
            .padding(.leading, inset)
    }
}

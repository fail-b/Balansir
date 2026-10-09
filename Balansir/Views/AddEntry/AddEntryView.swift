import SwiftUI

struct AddEntryView: View {
    @Bindable var viewModel: AddEntryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var path: [AccountPickerTarget] = []
    @State private var showDatePicker = false

    var body: some View {
        NavigationStack(path: $path) {
            mainContent
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: AccountPickerTarget.self) { target in
                    pickerView(for: target)
                        .toolbar(.hidden, for: .navigationBar)
                }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(Theme.Radius.sheet)
        .presentationDragIndicator(.visible)
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

    // MARK: - Основной экран

    private var mainContent: some View {
        VStack(spacing: 0) {
            header
            typeSegment
                .padding(.top, Theme.Spacing.l)
            amountView
                .padding(.top, Theme.Spacing.xl)
            card
                .padding(.top, Theme.Spacing.l)
            Spacer(minLength: Theme.Spacing.l)
            NumpadView(
                onDigit: { viewModel.inputDigit($0) },
                onSeparator: { viewModel.inputSeparator() },
                onBackspace: { viewModel.backspace() }
            )
            saveButton
                .padding(.top, Theme.Spacing.m)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.bottom, Theme.Spacing.s)
        .background(Theme.Colors.background)
    }

    // MARK: - Шапка

    private var header: some View {
        ZStack {
            Text(viewModel.isEditing ? "Редактировать" : "Новая операция")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.Colors.ink)
            HStack {
                Button { dismiss() } label: {
                    AppIcon.image(named: AppIcon.close)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink)
                        .frame(width: 44, height: 44)
                        .glassEffect(in: .circle)
                }
                .buttonStyle(.plain)
                Spacer()
                dateChip
            }
        }
        .padding(.top, Theme.Spacing.s)
    }

    private var dateChip: some View {
        Button { showDatePicker = true } label: {
            HStack(spacing: 6) {
                AppIcon.image(named: AppIcon.calendar).font(.system(size: 15))
                Text(dateLabel).font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(Theme.Colors.ink)
            .padding(.horizontal, Theme.Spacing.m)
            .frame(height: 44)
            .glassEffect(in: .capsule)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showDatePicker) {
            DatePicker("Дата", selection: $viewModel.date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding()
                .presentationCompactAdaptation(.popover)
        }
    }

    private var dateLabel: String {
        if Calendar.current.isDateInToday(viewModel.date) { return "Сегодня" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMM"
        return f.string(from: viewModel.date)
    }

    // MARK: - Сегмент типа

    private var typeSegment: some View {
        HStack(spacing: 0) {
            ForEach(EntryType.allCases, id: \.self) { type in
                let isActive = viewModel.selectedType == type
                Button {
                    viewModel.selectedType = type
                    viewModel.onTypeChanged()
                } label: {
                    Text(type.title)
                        .font(.system(size: 15, weight: isActive ? .semibold : .regular))
                        .foregroundStyle(isActive ? Theme.Colors.ink : Theme.Colors.ink2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background {
                            if isActive {
                                RoundedRectangle(cornerRadius: Theme.Radius.s)
                                    .fill(Theme.Colors.card)
                                    .shadow(color: Theme.Colors.shadow, radius: 4, y: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.Spacing.xs)
        .background(Theme.Colors.fill, in: RoundedRectangle(cornerRadius: Theme.Radius.m))
    }

    // MARK: - Сумма

    private var amountView: some View {
        HStack(alignment: .center, spacing: 6) {
            Text(viewModel.formattedAmount)
                .font(Theme.Font.amountInput)
                .tracking(Theme.Font.Tracking.amountInput)
                .foregroundStyle(viewModel.amountString == "0" ? Theme.Colors.ink2 : Theme.Colors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(viewModel.currencySymbol)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Theme.Colors.ink2)
            caret
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var caret: some View {
        // phaseAnimator анимирует только opacity и не вмешивается в раскладку,
        // поэтому каретка мигает на месте, а не «прилетает» из угла экрана.
        RoundedRectangle(cornerRadius: 1.5)
            .fill(Theme.Colors.accent)
            .frame(width: 3, height: 52)
            .phaseAnimator([1.0, 0.0]) { view, opacity in
                view.opacity(opacity)
            } animation: { _ in .easeInOut(duration: 0.6) }
    }

    // MARK: - Карточка

    private var card: some View {
        VStack(spacing: 0) {
            if viewModel.selectedType != .transfer {
                categoryStrip
                    .padding(.vertical, Theme.Spacing.m)
                Divider().padding(.leading, Theme.Spacing.l)
                accountRow(target: .from, label: "Счёт")
            } else {
                accountRow(target: .from, label: "Со счёта")
                Divider().padding(.leading, Theme.Spacing.l)
                accountRow(target: .to, label: "На счёт")
            }
            Divider().padding(.leading, Theme.Spacing.l)
            noteRow
        }
        .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(viewModel.filteredCategories) { category in
                    categoryCell(category)
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, Theme.Spacing.s)
        }
        .scrollTargetBehavior(.viewAligned)
    }

    private func categoryCell(_ category: CategoryModel) -> some View {
        let isSelected = viewModel.selectedCategory?.id == category.id
        return Button {
            viewModel.selectedCategory = category
        } label: {
            VStack(spacing: 6) {
                // Фрейм 52×52 резервирует место под кольцо, чтобы оно не обрезалось.
                ZStack {
                    if isSelected {
                        Circle().strokeBorder(Theme.Colors.accent, lineWidth: 2)
                    }
                    CategoryIcon(category: category, style: .dot, size: 46)
                }
                .frame(width: 52, height: 52)
                Text(category.name)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Theme.Colors.ink : Theme.Colors.ink2)
                    .lineLimit(1)
            }
            .frame(width: 68)
        }
        .buttonStyle(.plain)
    }

    private func accountRow(target: AccountPickerTarget, label: String) -> some View {
        let account = target == .from ? viewModel.selectedAccount : viewModel.selectedToAccount
        return Button {
            path.append(target)
        } label: {
            HStack(spacing: Theme.Spacing.m) {
                AccountColorCard(colorHex: account?.colorHex ?? "#CCCCCC")
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Colors.ink2)
                    Text(account.map { viewModel.subtitle(for: $0) } ?? "Выберите счёт")
                        .font(Theme.Font.rowTitle)
                        .foregroundStyle(Theme.Colors.ink)
                }
                Spacer()
                AppIcon.image(named: AppIcon.forward)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink2)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.m)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var noteRow: some View {
        HStack(spacing: Theme.Spacing.m) {
            AppIcon.image(named: AppIcon.note)
                .font(.system(size: 17))
                .foregroundStyle(Theme.Colors.ink2)
            TextField("Заметка", text: $viewModel.note)
                .font(Theme.Font.rowTitle)
                .foregroundStyle(Theme.Colors.ink)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.m)
    }

    // MARK: - Сохранить

    private var saveButton: some View {
        Button {
            Task {
                await viewModel.save()
                if viewModel.errorMessage == nil { dismiss() }
            }
        } label: {
            Text("Сохранить")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.Colors.onColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Theme.Colors.accent, in: RoundedRectangle(cornerRadius: Theme.Radius.l))
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSave)
        .opacity(viewModel.canSave ? 1 : 0.4)
    }

    // MARK: - Выбор счёта

    private func pickerView(for target: AccountPickerTarget) -> some View {
        let title: String
        let selectedId: UUID?
        switch target {
        case .from:
            title = viewModel.selectedType == .transfer ? "Со счёта" : "Счёт"
            selectedId = viewModel.selectedAccount?.id
        case .to:
            title = "На счёт"
            selectedId = viewModel.selectedToAccount?.id
        }
        return AccountPickerView(
            title: title,
            accounts: viewModel.accounts,
            selectedId: selectedId,
            balanceText: { MoneyFormatter.format(viewModel.balance(for: $0), currency: $0.currency) },
            onSelect: { account in
                if target == .from { viewModel.selectedAccount = account } else { viewModel.selectedToAccount = account }
                if !path.isEmpty { path.removeLast() }
            },
            onBack: { if !path.isEmpty { path.removeLast() } }
        )
    }
}

import CoreData

enum SeedData {
    static func populate(in context: NSManagedObjectContext) {
        addAccounts(to: context)
        addCategories(to: context)
        try? context.save()
    }

    private static func addAccounts(to context: NSManagedObjectContext) {
        let data: [(String, String, String, String)] = [
            ("Тинькофф", "creditcard", "#FFDD00", AccountType.debit.rawValue),
            ("Альфа", "creditcard", "#EF3124", AccountType.debit.rawValue),
            ("Наличка", "banknote", "#4CAF50", AccountType.cash.rawValue),
            ("ВТБ", "creditcard", "#009FDF", AccountType.debit.rawValue),
        ]
        for (i, (name, icon, color, type)) in data.enumerated() {
            let a = Account(context: context)
            a.id = UUID()
            a.name = name
            a.iconName = icon
            a.colorHex = color
            a.accountType = type
            a.initialBalance = 0
            a.currency = "RUB"
            a.sortOrder = Int32(i)
            a.createdAt = Date()
            a.updatedAt = Date()
            a.isArchived = false
        }
    }

    private static func addCategories(to context: NSManagedObjectContext) {
        let expense: [(String, String, String)] = [
            ("Еда", "fork.knife", "#FF6B6B"),
            ("Продукты", "cart", "#FF8C42"),
            ("Транспорт", "tram", "#4ECDC4"),
            ("Поездки", "airplane", "#45B7D1"),
            ("Машина", "car", "#96CEB4"),
            ("Услуги", "wrench.and.screwdriver", "#DDA0DD"),
            ("Одежда", "tshirt", "#F7DC6F"),
            ("Кредиты", "creditcard", "#E74C3C"),
            ("Подписки", "star", "#9B59B6"),
            ("Развлечения", "gamecontroller", "#1ABC9C"),
            ("Здоровье", "heart.text.square", "#E91E63"),
            ("Аптеки", "pills", "#00BCD4"),
            ("Подарки", "gift", "#FF5722"),
            ("Хозтовары", "house", "#795548"),
            ("Бизнес", "briefcase", "#607D8B"),
            ("Электроника", "iphone", "#2196F3"),
            ("Связь", "phone", "#4CAF50"),
            ("Физкультура", "figure.run", "#FF9800"),
            ("За квартиру", "building.2", "#3F51B5"),
        ]
        let income: [(String, String, String)] = [
            ("Зарплата", "dollarsign.circle", "#4CAF50"),
            ("Фриланс", "laptopcomputer", "#2196F3"),
            ("Кешбэк", "percent", "#FF9800"),
            ("Возврат", "arrow.uturn.left", "#9C27B0"),
            ("Другое", "ellipsis.circle", "#607D8B"),
        ]

        for (i, (name, icon, color)) in expense.enumerated() {
            let c = Category(context: context)
            c.id = UUID()
            c.name = name
            c.categoryType = CategoryType.expense.rawValue
            c.iconName = icon
            c.colorHex = color
            c.sortOrder = Int32(i)
            c.createdAt = Date()
            c.updatedAt = Date()
            c.isArchived = false
        }
        for (i, (name, icon, color)) in income.enumerated() {
            let c = Category(context: context)
            c.id = UUID()
            c.name = name
            c.categoryType = CategoryType.income.rawValue
            c.iconName = icon
            c.colorHex = color
            c.sortOrder = Int32(i)
            c.createdAt = Date()
            c.updatedAt = Date()
            c.isArchived = false
        }
    }
}

import CoreData

enum SeedData {
    /// Только категории, названия — на языке интерфейса в момент первого запуска (дальше это данные пользователя).
    /// Счета пользователь заводит сам в онбординге (§4.9) — демо-счетов нет.
    static func populate(in context: NSManagedObjectContext) {
        addCategories(to: context)
        try? context.save()
    }

    private static func addCategories(to context: NSManagedObjectContext) {
        let expense: [(String, String, String)] = [
            (String(localized: "Food"), "fork.knife", "#FF6B6B"),
            (String(localized: "Groceries"), "cart", "#FF8C42"),
            (String(localized: "Transport"), "tram", "#4ECDC4"),
            (String(localized: "Travel"), "airplane", "#45B7D1"),
            (String(localized: "Car"), "car", "#96CEB4"),
            (String(localized: "Services"), "wrench.and.screwdriver", "#DDA0DD"),
            (String(localized: "Clothing"), "tshirt", "#E0B83A"),
            (String(localized: "Loans"), "creditcard", "#E74C3C"),
            (String(localized: "Subscriptions"), "star", "#9B59B6"),
            (String(localized: "Entertainment"), "gamecontroller", "#1ABC9C"),
            (String(localized: "Health"), "heart.text.square", "#E91E63"),
            (String(localized: "Pharmacy"), "pills", "#00BCD4"),
            (String(localized: "Gifts"), "gift", "#FF5722"),
            (String(localized: "Household"), "house", "#795548"),
            (String(localized: "Business"), "briefcase", "#607D8B"),
            (String(localized: "Electronics"), "iphone", "#2196F3"),
            (String(localized: "Phone & Internet"), "phone", "#2E9E5B"),
            (String(localized: "Fitness"), "figure.run", "#FF9800"),
            (String(localized: "Rent & Utilities"), "building.2", "#3F51B5"),
        ]
        let income: [(String, String, String)] = [
            (String(localized: "Salary"), "banknote", "#4CAF50"),
            (String(localized: "Freelance"), "laptopcomputer", "#2196F3"),
            (String(localized: "Cashback"), "percent", "#00BCD4"),
            (String(localized: "Refunds"), "arrow.uturn.left", "#9C27B0"),
            (String(localized: "Other income"), "ellipsis.circle", "#607D8B"),
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

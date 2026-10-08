import Testing
import Foundation
@testable import balancier

@Suite("BalanceService")
@MainActor
struct BalanceServiceTests {

    @Test func пустые_счета_возвращают_пустой_результат() {
        let result = BalanceService.computeBalances(accounts: [], entries: [])
        #expect(result.isEmpty)
    }

    @Test func начальный_баланс_без_операций() {
        let a = AccountModel.makeTest(initialBalance: 500)
        let result = BalanceService.computeBalances(accounts: [a], entries: [])
        #expect(result[a.id] == 500)
    }

    @Test func расход_уменьшает_баланс() {
        let a = AccountModel.makeTest(initialBalance: 1000)
        let entry = EntryModel.makeTest(type: .expense, amount: 300, from: a)
        let result = BalanceService.computeBalances(accounts: [a], entries: [entry])
        #expect(result[a.id] == 700)
    }

    @Test func доход_увеличивает_баланс() {
        let a = AccountModel.makeTest(initialBalance: 100)
        let entry = EntryModel.makeTest(type: .income, amount: 400, to: a)
        let result = BalanceService.computeBalances(accounts: [a], entries: [entry])
        #expect(result[a.id] == 500)
    }

    @Test func перевод_уменьшает_источник_увеличивает_получателя() {
        let a1 = AccountModel.makeTest(name: "A1", initialBalance: 1000)
        let a2 = AccountModel.makeTest(name: "A2", initialBalance: 200)
        let entry = EntryModel.makeTest(type: .transfer, amount: 300, from: a1, to: a2)
        let result = BalanceService.computeBalances(accounts: [a1, a2], entries: [entry])
        #expect(result[a1.id] == 700)
        #expect(result[a2.id] == 500)
    }

    @Test func несколько_операций_суммируются() {
        let a = AccountModel.makeTest(initialBalance: 1000)
        let entries: [EntryModel] = [
            .makeTest(type: .income, amount: 500, to: a),
            .makeTest(type: .expense, amount: 200, from: a),
            .makeTest(type: .expense, amount: 100, from: a),
        ]
        let result = BalanceService.computeBalances(accounts: [a], entries: entries)
        // 1000 + 500 - 200 - 100 = 1200
        #expect(result[a.id] == 1200)
    }
}

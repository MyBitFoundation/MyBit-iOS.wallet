// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import Result
import APIKit
import RealmSwift
import BigInt
import Moya
import TrustCore

enum TokenAction {
    case disable(Bool)
    case updateInfo
}

class TokensDataStore {
    var tokens: Results<TokenObject> {
        return realm.objects(TokenObject.self)
            .filter(NSPredicate(format: "isDisabled == NO"))
            .sorted(byKeyPath: "contract", ascending: true)
            .filter(NSPredicate(format: "contract CONTAINS[cd] %@ || contract CONTAINS[cd] %@", TokensDataStore.etherToken().contract, TokensDataStore.myBitToken()?.contract ?? ""))
    }
    var nonFungibleTokens: Results<NonFungibleTokenCategory> {
        return realm.objects(NonFungibleTokenCategory.self)
            .sorted(byKeyPath: "name", ascending: true)
            .filter(NSPredicate(format: "contract CONTAINS[cd] %@ || contract CONTAINS[cd] %@", TokensDataStore.etherToken().contract, TokensDataStore.myBitToken() ?? ""))
    }
    let config: Config
    let realm: Realm
    var objects: [TokenObject] {
        return realm.objects(TokenObject.self)
            .sorted(byKeyPath: "contract", ascending: true)
            .filter { !$0.contract.isEmpty }
            .filter { $0 == TokensDataStore.etherToken() || $0 == TokensDataStore.myBitToken() }
    }
    var enabledObject: [TokenObject] {
        return realm.objects(TokenObject.self)
            .sorted(byKeyPath: "contract", ascending: true)
            .filter { !$0.isDisabled }
            .filter { $0 == TokensDataStore.etherToken() || $0 == TokensDataStore.myBitToken() }
    }
    var nonFungibleObjects: [NonFungibleTokenObject] {
        return realm.objects(NonFungibleTokenObject.self).map { $0 }
    }

    init(
        realm: Realm,
        config: Config
    ) {
        self.config = config
        self.realm = realm
        self.addEthToken()
        self.addMyBitToken()
    }

    private func addEthToken() {
        let etherToken = TokensDataStore.etherToken(for: config)
        if objects.first(where: { $0 == etherToken }) == nil {
            add(tokens: [etherToken])
        }
    }
    
    private func addMyBitToken() {
        guard let myBitToken = TokensDataStore.myBitToken(for: config) else {
            return
        }
        
        if objects.first(where: { $0.contract.caseInsensitiveCompare(myBitToken.contract) == .orderedSame }) == nil {
            add(tokens: [myBitToken])
        }
    }

    func coinTicker(for token: TokenObject) -> CoinTicker? {
        return tickers().first(where: { $0.contract.caseInsensitiveCompare(token.contract) == .orderedSame })
    }

    func addCustom(token: ERC20Token) {
        let newToken = TokenObject(
            contract: token.contract.description,
            name: token.name,
            symbol: token.symbol,
            decimals: token.decimals,
            value: "0",
            isCustom: true
        )
        add(tokens: [newToken])
    }

    func add(tokens: [Object]) {
        try? realm.write {
            if let tokenObjects = tokens as? [TokenObject] {
                let tokenObjectsWithBalance = tokenObjects.map { tokenObject -> TokenObject in
                    tokenObject.balance = self.getBalance(for: tokenObject, with: self.tickers())
                    return tokenObject
                }
                realm.add(tokenObjectsWithBalance, update: true)
            } else {
                realm.add(tokens, update: true)
            }
        }
    }

    func delete(tokens: [Object]) {
        try? realm.write {
            realm.delete(tokens)
        }
    }

    func deleteAll() {
        deleteAllExistingTickers()

        try? realm.write {
            realm.delete(realm.objects(TokenObject.self))
            realm.delete(realm.objects(NonFungibleTokenObject.self))
            realm.delete(realm.objects(NonFungibleTokenCategory.self))
        }
    }

    //Background update of the Realm model.
    func update(balance: BigInt, for address: Address) {
        if let tokenToUpdate = enabledObject.first(where: { $0.contract.caseInsensitiveCompare(address.description) == .orderedSame }) {
            let tokenBalance = self.getBalance(for: tokenToUpdate)

            self.realm.writeAsync(obj: tokenToUpdate) { (realm, _ ) in
                let update = self.objectToUpdate(for: (address, balance), tokenBalance: tokenBalance)
                realm.create(TokenObject.self, value: update, update: true)
            }
        }
    }

    func update(balances: [Address: BigInt]) {
        for balance in balances {
            let token = realm.object(ofType: TokenObject.self, forPrimaryKey: balance.key.description)
            let tokenBalance = self.getBalance(for: token)

            try? realm.write {
                let update = objectToUpdate(for: balance, tokenBalance: tokenBalance)
                realm.create(TokenObject.self, value: update, update: true)
            }
        }
    }

    private func objectToUpdate(for balance: (key: Address, value: BigInt), tokenBalance: Double) -> [String: Any] {
        return [
            "contract": balance.key.description,
            "lovercaseContract": balance.key.description.lowercased(),
            "value": balance.value.description,
            "balance": tokenBalance,
        ]
    }

    func update(tokens: [TokenObject], action: TokenAction) {
        try? realm.write {
            for token in tokens {
                switch action {
                case .disable(let value):
                    token.isDisabled = value
                case .updateInfo:
                    let update: [String: Any] = [
                        "contract": token.address.description,
                        "lovercaseContract": token.address.description.lowercased(),
                        "name": token.name,
                        "symbol": token.symbol,
                        "decimals": token.decimals,
                    ]
                    realm.create(TokenObject.self, value: update, update: true)
                }
            }
        }
    }

    func saveTickers(tickers: [CoinTicker]) {
        guard !tickers.isEmpty else {
            return
        }
        try? realm.write {
            realm.add(tickers, update: true)
        }
    }

    func tickers() -> [CoinTicker] {
        let coinTickers: [CoinTicker] = tickerResultsByTickersKey.map { $0 }

        guard !coinTickers.isEmpty else {
            return [CoinTicker]()
        }

        return coinTickers
    }

    private var tickerResultsByTickersKey: Results<CoinTicker> {
        return realm.objects(CoinTicker.self).filter("tickersKey == %@", config.tickersKey)
    }

    func deleteAllExistingTickers() {
        try? realm.write {
            realm.delete(tickerResultsByTickersKey)
        }
    }

    static func etherToken(for config: Config = .current) -> TokenObject {
        return TokenObject(
            contract: config.server.address,
            name: config.server.name,
            symbol: config.server.symbol,
            decimals: config.server.decimals,
            value: "0",
            isCustom: false
        )
    }

    static func myBitToken(for config: Config = .current) -> TokenObject? {

        guard let contract = MyBitTokenParameters.getContractAddress(for: config) else {
            return nil
        }

        return TokenObject(
            contract: contract,
            name: MyBitTokenParameters.name,
            symbol: MyBitTokenParameters.symbol,
            decimals: MyBitTokenParameters.decimals,
            value: "0",
            isCustom: false
        )
    }

    func getBalance(for token: TokenObject?) -> Double {
        return getBalance(for: token, with: self.tickers())
    }

    func getBalance(for token: TokenObject?, with tickers: [CoinTicker]) -> Double {
        guard let token = token else {
            return TokenObject.DEFAULT_BALANCE
        }

        guard let ticker = tickers.first(where: { $0.contract.caseInsensitiveCompare(token.contract) == .orderedSame }) else {
            return TokenObject.DEFAULT_BALANCE
        }

        guard let amountInBigInt = BigInt(token.value), let price = Double(ticker.price) else {
            return TokenObject.DEFAULT_BALANCE
        }

        guard let amountInDecimal = EtherNumberFormatter.full.decimal(from: amountInBigInt, decimals: token.decimals) else {
            return TokenObject.DEFAULT_BALANCE
        }

        return amountInDecimal.doubleValue * price
    }
}
// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import TrustCore

enum WalletAction {
    case none
    case addToken(Address)
}

enum Tabs {
    case transactions
    case wallet(WalletAction)
    case settings

    var index: Int {
        switch self {
        case .wallet: return 0
        case .transactions: return 1
        case .settings: return 2
        }
    }
}

extension Tabs: Equatable {
    static func == (lhs: Tabs, rhs: Tabs) -> Bool {
        switch (lhs, rhs) {
        case (.transactions, .transactions),
             (.wallet, .wallet),
             (.settings, .settings):
            return true
        case (_, .transactions),
             (_, .wallet),
             (_, .settings):
            return false
        }
    }
}

// Copyright SIX DAY LLC. All rights reserved.

import Foundation

struct MyBitTokenParameters {
    
    static let decimals: Int = 8
    static let symbol: String = "MYB"
    static let name: String = "MyBit"
    
    fileprivate static let mainContractAddress = "0x94298F1e0Ab2DFaD6eEFfB1426846a3c29D98090"
    fileprivate static let ropsternContractAddress = "0x8abaf4191951d4b92c688182a36628ec5f19f769"
    
    static func getContractAddress(for config: Config = .current) -> String? {
        
        switch config.server {
        case .ropsten:
            return ropsternContractAddress
        case .main:
            return mainContractAddress
        default:
            return nil
        }
    }
}

// Copyright SIX DAY LLC. All rights reserved.

import Foundation

struct MyBitTokenParameters {
    
    static let decimals: Int = 18
    static let symbol: String = "MYB"
    static let name: String = "MyBit"
    
    fileprivate static let mainContractAddress = "0x5d60d8d7ef6d37e16ebabc324de3be57f135e0bc"
    fileprivate static let ropsternContractAddress = "0xbb07c8c6e7cd15e2e6f944a5c2cac056c5476151"
    
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

// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import TrustCore
import JSONRPCKit
import PromiseKit
import APIKit

enum ENSError: LocalizedError {
    case decodeError
}

// move to TrustCore later
final class PublicResolverEncoder {
    public static func encodeAddr(node: Data) -> Data {
        let function = Function(name: "addr", parameters: [.bytes(32)])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [node])
        return encoder.data
    }
}

typealias ENSResolveResult = (resolver: Address, address: Address)

struct ENSClient {

    static let ensContrct = Address(string: "0x314159265dd8dbb310642f98f50c066173c1259b")!
    static let publicResolverContract = Address(string: "0x5fbb459c49bb06083c33109fa4f14810ec2cf358")!
    static let reverseResolverContract = Address(string: "0x5fbb459c49bb06083c33109fa4f14810ec2cf358")!
    static let reverseSuffix = "addr.reverse"

    func resolve(name: String) -> Promise<ENSResolveResult> {
        return firstly {
            return self.resolverOf(name: name)
        }.then { resolver -> Promise<ENSResolveResult> in
            if resolver == Address.zero {
                return Promise { $0.resolve((resolver: resolver, address: resolver), nil) }
            }
            let encoded = PublicResolverEncoder.encodeAddr(node: namehash(name))
            let request = EtherServiceRequest(
                batch: BatchFactory().create(CallRequest(to: resolver.description, data: encoded.hexEncoded))
            )
            return self.sendAddr(request: request).compactMap { address -> ENSResolveResult in
                return (resolver: resolver, address: address)
            }
        }
    }

    func resolverOf(name: String) -> Promise<Address> {
        let node = namehash(name)
        let encoded = ENSEncoder.encodeResolver(node: node)
        let request = EtherServiceRequest(
            batch: BatchFactory().create(CallRequest(to: ENSClient.ensContrct.description, data: encoded.hexEncoded))
        )
        return self.sendAddr(request: request)
    }

    func ownerOf(name: String) -> Promise<Address> {
        let node = namehash(name)
        let encoded = ENSEncoder.encodeOwner(node: node)
        let request = EtherServiceRequest(
            batch: BatchFactory().create(CallRequest(to: ENSClient.ensContrct.description, data: encoded.hexEncoded))
        )
        return self.sendAddr(request: request)
    }

    private func sendAddr(request: EtherServiceRequest<Batch1<CallRequest>>) -> Promise<Address> {
        return Promise { seal in
            Session.send(request) { result in
                switch result {
                case .success(let response):
                    let data = Data(hex: response)
                    guard data.count == 32 else {
                        return seal.reject(ENSError.decodeError)
                    }
                    //take the last 20 bytes for Address
                    let sub = data.suffix(20)
                    seal.fulfill(Address(data: sub))
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }

    func lookup(address: Address) -> Promise<String> {
        let addr = [address.data.hex, ENSClient.reverseSuffix].joined(separator: ".")
        let node = namehash(addr)
        let encoded = ReverseResolverEncoder.encodeName(node)
        let request = EtherServiceRequest(
            batch: BatchFactory().create(CallRequest(to: ENSClient.reverseResolverContract.description, data: encoded.hexEncoded))
        )
        return Promise { seal in
            Session.send(request) { result in
                switch result {
                case .success(let response):
                    let data = Data(hex: response)
                    if data.isEmpty {
                        return seal.reject(ENSError.decodeError)
                    }
                    let decoder = ABIDecoder(data: data)
                    let decoded = try? decoder.decodeTuple(types: [.string])
                    guard let string = decoded?.first?.nativeValue as? String else {
                        return seal.reject(ENSError.decodeError)
                    }
                    seal.fulfill(string)
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }
}

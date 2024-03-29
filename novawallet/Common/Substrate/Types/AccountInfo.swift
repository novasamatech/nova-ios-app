import Foundation
import SubstrateSdk
import BigInt

struct AccountInfo: Codable, Equatable {
    @StringCodable var nonce: UInt32
    let data: AccountData
}

struct AccountData: Codable, Equatable {
    @StringCodable var free: BigUInt
    @StringCodable var reserved: BigUInt
    @StringCodable var miscFrozen: BigUInt
    @StringCodable var feeFrozen: BigUInt
}

extension AccountData {
    var total: BigUInt { free + reserved }
    var frozen: BigUInt { reserved + locked }
    var locked: BigUInt { max(miscFrozen, feeFrozen) }
    var available: BigUInt { free > locked ? free - locked : 0 }
}

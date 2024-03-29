import Foundation

struct PayoutsInfo {
    let activeEra: EraIndex
    let historyDepth: UInt32
    let payouts: [PayoutInfo]
}

struct PayoutInfo: Hashable {
    let era: EraIndex
    let validator: Data
    let reward: Decimal
    let identity: AccountIdentity?
}

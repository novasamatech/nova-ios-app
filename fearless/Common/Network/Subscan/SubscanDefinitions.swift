import Foundation
import IrohaCrypto

struct SubscanApi {
    static let price = "api/open/price"
    static let transfers = "api/scan/transfers"
    static let rewards = "api/scan/account/reward_slash"
}

extension WalletAssetId {
    var subscanUrl: URL? {
        switch self {
        case .dot:
            return URL(string: "https://polkadot.subscan.io/")
        case .kusama:
            return URL(string: "https://kusama.subscan.io/")
        case .westend:
            return URL(string: "https://westend.subscan.io/")
        default:
            return nil
        }
    }

    var hasPrice: Bool {
        switch self {
        case .dot, .kusama:
            return true
        case .usd, .westend:
            return false
        }
    }
}

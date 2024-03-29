import Foundation
import SubstrateSdk
import BigInt

extension ParachainStaking {
    struct Delegator: Codable, Equatable {
        let delegations: [ParachainStaking.Bond]
        @StringCodable var total: BigUInt
        @StringCodable var lessTotal: BigUInt

        var staked: BigUInt {
            total >= lessTotal ? total - lessTotal : 0
        }

        func collators() -> [AccountId] {
            delegations.map(\.owner)
        }

        func delegationsDict() -> [AccountId: ParachainStaking.Bond] {
            delegations.reduce(into: [AccountId: ParachainStaking.Bond]()) {
                $0[$1.owner] = $1
            }
        }
    }

    struct ScheduledRequest: Decodable, Encodable, Equatable {
        @BytesCodable var delegator: AccountId
        @StringCodable var whenExecutable: RoundIndex
        let action: DelegationAction
    }

    enum DelegationAction: Decodable, Encodable, Equatable {
        static let revokeField = "Revoke"
        static let decreaseField = "Decrease"

        case revoke(amount: BigUInt)
        case decrease(amount: BigUInt)

        public init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            let type = try container.decode(String.self)
            let amount = try container.decode(StringScaleMapper<BigUInt>.self).value

            switch type {
            case Self.revokeField:
                self = .revoke(amount: amount)
            case Self.decreaseField:
                self = .decrease(amount: amount)
            default:
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unexpected type"
                )
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()

            switch self {
            case let .revoke(amount):
                try container.encode(Self.revokeField)
                try container.encode(StringScaleMapper(value: amount))
            case let .decrease(amount):
                try container.encode(Self.decreaseField)
                try container.encode(StringScaleMapper(value: amount))
            }
        }
    }
}

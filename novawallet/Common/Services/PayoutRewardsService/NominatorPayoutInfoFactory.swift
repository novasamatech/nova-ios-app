import Foundation
import IrohaCrypto

final class NominatorPayoutInfoFactory: PayoutInfoFactoryProtocol {
    let chainAssetInfo: ChainAssetDisplayInfo

    init(chainAssetInfo: ChainAssetDisplayInfo) {
        self.chainAssetInfo = chainAssetInfo
    }

    func calculate(
        for accountId: AccountId,
        era: EraIndex,
        validatorInfo: EraValidatorInfo,
        erasRewardDistribution: ErasRewardDistribution,
        identities: [AccountAddress: AccountIdentity]
    ) throws -> PayoutInfo? {
        guard
            let totalRewardAmount = erasRewardDistribution.totalValidatorRewardByEra[era],
            let totalReward = Decimal.fromSubstrateAmount(
                totalRewardAmount,
                precision: chainAssetInfo.asset.assetPrecision
            ),
            let points = erasRewardDistribution.validatorPointsDistributionByEra[era] else {
            return nil
        }

        guard
            let nominatorStakeAmount = validatorInfo.exposure.others
            .first(where: { $0.who == accountId })?.value,
            let nominatorStake = Decimal.fromSubstrateAmount(
                nominatorStakeAmount,
                precision: chainAssetInfo.asset.assetPrecision
            ),
            let comission = Decimal.fromSubstratePerbill(value: validatorInfo.prefs.commission),
            let validatorPoints = points.individual
            .first(where: { $0.accountId == validatorInfo.accountId })?.rewardPoint,
            let totalStake = Decimal.fromSubstrateAmount(
                validatorInfo.exposure.total,
                precision: chainAssetInfo.asset.assetPrecision
            ) else {
            return nil
        }

        let rewardFraction = points.total > 0 ? Decimal(validatorPoints) / Decimal(points.total) : 0
        let validatorTotalReward = totalReward * rewardFraction
        let nominatorPortion = totalStake > 0 ? nominatorStake / totalStake : 0
        let nominatorReward = validatorTotalReward * (1 - comission) * nominatorPortion

        let validatorAddress = try validatorInfo.accountId.toAddress(using: chainAssetInfo.chain)

        return PayoutInfo(
            era: era,
            validator: validatorInfo.accountId,
            reward: nominatorReward,
            identity: identities[validatorAddress]
        )
    }
}

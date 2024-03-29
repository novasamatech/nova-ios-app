import Foundation

class BaseStashNextState: BaseStakingState {
    let stashItem: StashItem
    private(set) var totalReward: TotalRewardItem?
    private(set) var payee: RewardDestinationArg?
    private(set) var bagListNode: BagList.Node?

    init(
        stateMachine: StakingStateMachineProtocol,
        commonData: StakingStateCommonData,
        stashItem: StashItem,
        totalReward: TotalRewardItem?,
        payee: RewardDestinationArg?,
        bagListNode: BagList.Node?
    ) {
        self.stashItem = stashItem
        self.totalReward = totalReward
        self.payee = payee
        self.bagListNode = bagListNode

        super.init(stateMachine: stateMachine, commonData: commonData)
    }

    override func process(stashItem: StashItem?) {
        guard self.stashItem != stashItem else {
            stateMachine?.transit(to: self)
            return
        }

        guard let stateMachine = stateMachine else {
            return
        }

        let newState: StakingStateProtocol

        if let stashItem = stashItem {
            newState = StashState(
                stateMachine: stateMachine,
                commonData: commonData,
                stashItem: stashItem,
                ledgerInfo: nil,
                totalReward: nil,
                bagListNode: nil
            )
        } else {
            newState = NoStashState(
                stateMachine: stateMachine,
                commonData: commonData
            )
        }

        stateMachine.transit(to: newState)
    }

    override func process(totalReward: TotalRewardItem?) {
        self.totalReward = totalReward

        stateMachine?.transit(to: self)
    }

    override func process(payee: RewardDestinationArg?) {
        self.payee = payee

        stateMachine?.transit(to: self)
    }

    override func process(bagListNode: BagList.Node?) {
        self.bagListNode = bagListNode

        stateMachine?.transit(to: self)
    }
}

import UIKit
import SubstrateSdk
import RobinHood
import BigInt

final class ParaStkStakeConfirmInteractor: RuntimeConstantFetching {
    weak var presenter: ParaStkStakeConfirmInteractorOutputProtocol?

    let chainAsset: ChainAsset
    let selectedAccount: MetaChainAccountResponse
    let selectedCollator: DisplayAddress
    let walletLocalSubscriptionFactory: WalletLocalSubscriptionFactoryProtocol
    let priceLocalSubscriptionFactory: PriceProviderFactoryProtocol
    let extrinsicService: ExtrinsicServiceProtocol
    let feeProxy: ExtrinsicFeeProxyProtocol
    let connection: JSONRPCEngine
    let runtimeProvider: RuntimeCodingServiceProtocol
    let stakingLocalSubscriptionFactory: ParachainStakingLocalSubscriptionFactoryProtocol
    let stakingDurationFactory: ParaStkDurationOperationFactoryProtocol
    let blockEstimationService: BlockTimeEstimationServiceProtocol
    let signer: SigningWrapperProtocol
    let operationQueue: OperationQueue

    private var balanceProvider: StreamableProvider<AssetBalance>?
    private var priceProvider: AnySingleValueProvider<PriceData>?
    private var collatorProvider: AnyDataProvider<ParachainStaking.DecodedCandidateMetadata>?
    private var delegatorProvider: AnyDataProvider<ParachainStaking.DecodedDelegator>?
    private var extrinsicSubscriptionId: UInt16?

    init(
        chainAsset: ChainAsset,
        selectedAccount: MetaChainAccountResponse,
        selectedCollator: DisplayAddress,
        stakingLocalSubscriptionFactory: ParachainStakingLocalSubscriptionFactoryProtocol,
        walletLocalSubscriptionFactory: WalletLocalSubscriptionFactoryProtocol,
        priceLocalSubscriptionFactory: PriceProviderFactoryProtocol,
        extrinsicService: ExtrinsicServiceProtocol,
        feeProxy: ExtrinsicFeeProxyProtocol,
        signer: SigningWrapperProtocol,
        connection: JSONRPCEngine,
        runtimeProvider: RuntimeCodingServiceProtocol,
        stakingDurationFactory: ParaStkDurationOperationFactoryProtocol,
        blockEstimationService: BlockTimeEstimationServiceProtocol,
        operationQueue: OperationQueue
    ) {
        self.chainAsset = chainAsset
        self.selectedAccount = selectedAccount
        self.selectedCollator = selectedCollator
        self.stakingLocalSubscriptionFactory = stakingLocalSubscriptionFactory
        self.walletLocalSubscriptionFactory = walletLocalSubscriptionFactory
        self.priceLocalSubscriptionFactory = priceLocalSubscriptionFactory
        self.extrinsicService = extrinsicService
        self.feeProxy = feeProxy
        self.signer = signer
        self.connection = connection
        self.runtimeProvider = runtimeProvider
        self.operationQueue = operationQueue
        self.stakingDurationFactory = stakingDurationFactory
        self.blockEstimationService = blockEstimationService
    }

    deinit {
        cancelExtrinsicSubscriptionIfNeeded()
    }

    private func subscribeAccountBalance() {
        balanceProvider = subscribeToAssetBalanceProvider(
            for: selectedAccount.chainAccount.accountId,
            chainId: chainAsset.chain.chainId,
            assetId: chainAsset.asset.assetId
        )
    }

    private func subscribePriceIfNeeded() {
        if let priceId = chainAsset.asset.priceId {
            priceProvider = subscribeToPrice(for: priceId)
        } else {
            presenter?.didReceivePrice(nil)
        }
    }

    private func subscribeDelegator() {
        delegatorProvider = subscribeToDelegatorState(
            for: chainAsset.chain.chainId,
            accountId: selectedAccount.chainAccount.accountId
        )
    }

    private func subscribeCollatorMetadata() {
        guard let collatorId = try? selectedCollator.address.toAccountId() else {
            presenter?.didReceiveError(CommonError.dataCorruption)
            return
        }

        collatorProvider = subscribeToCandidateMetadata(
            for: chainAsset.chain.chainId,
            accountId: collatorId
        )
    }

    private func provideMinTechStake() {
        fetchConstant(
            for: ParachainStaking.minDelegatorStk,
            runtimeCodingService: runtimeProvider,
            operationManager: OperationManager(operationQueue: operationQueue)
        ) { [weak self] (result: Result<BigUInt, Error>) in
            switch result {
            case let .success(minStake):
                self?.presenter?.didReceiveMinTechStake(minStake)
            case let .failure(error):
                self?.presenter?.didReceiveError(error)
            }
        }
    }

    private func provideStakingDuration() {
        let wrapper = stakingDurationFactory.createDurationOperation(
            from: runtimeProvider,
            blockTimeEstimationService: blockEstimationService
        )

        wrapper.targetOperation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                do {
                    let duration = try wrapper.targetOperation.extractNoCancellableResultData()
                    self?.presenter?.didReceiveStakingDuration(duration)
                } catch {
                    self?.presenter?.didReceiveError(error)
                }
            }
        }

        operationQueue.addOperations(wrapper.allOperations, waitUntilFinished: false)
    }

    private func cancelExtrinsicSubscriptionIfNeeded() {
        if let extrinsicSubscriptionId = extrinsicSubscriptionId {
            extrinsicService.cancelExtrinsicWatch(for: extrinsicSubscriptionId)
            self.extrinsicSubscriptionId = nil
        }
    }
}

extension ParaStkStakeConfirmInteractor: ParaStkStakeConfirmInteractorInputProtocol {
    func setup() {
        feeProxy.delegate = self

        subscribeAccountBalance()
        subscribePriceIfNeeded()
        subscribeDelegator()
        subscribeCollatorMetadata()

        provideMinTechStake()
        provideStakingDuration()
    }

    func estimateFee(
        _ amount: BigUInt,
        collator: AccountId,
        collatorDelegationsCount: UInt32,
        delegationsCount: UInt32
    ) {
        let call = ParachainStaking.DelegateCall(
            candidate: collator,
            amount: amount,
            candidateDelegationCount: collatorDelegationsCount,
            delegationCount: delegationsCount
        )

        feeProxy.estimateFee(
            using: extrinsicService,
            reuseIdentifier: call.extrinsicIdentifier
        ) { builder in
            try builder.adding(call: call.runtimeCall)
        }
    }

    func confirm(
        _ amount: BigUInt,
        collator: AccountId,
        collatorDelegationsCount: UInt32,
        delegationsCount: UInt32
    ) {
        let call = ParachainStaking.DelegateCall(
            candidate: collator,
            amount: amount,
            candidateDelegationCount: collatorDelegationsCount,
            delegationCount: delegationsCount
        )

        let builderClosure: (ExtrinsicBuilderProtocol) throws -> ExtrinsicBuilderProtocol = { builder in
            try builder.adding(call: call.runtimeCall)
        }

        let subscriptionIdClosure: ExtrinsicSubscriptionIdClosure = { [weak self] subscriptionId in
            self?.extrinsicSubscriptionId = subscriptionId

            return self != nil
        }

        let notificationClosure: ExtrinsicSubscriptionStatusClosure = { [weak self] result in
            switch result {
            case let .success(status):
                if case let .inBlock(extrinsicHash) = status {
                    self?.cancelExtrinsicSubscriptionIfNeeded()
                    self?.presenter?.didCompleteExtrinsicSubmission(for: .success(extrinsicHash))
                }
            case let .failure(error):
                self?.cancelExtrinsicSubscriptionIfNeeded()
                self?.presenter?.didCompleteExtrinsicSubmission(for: .failure(error))
            }
        }

        extrinsicService.submitAndWatch(
            builderClosure,
            signer: signer,
            runningIn: .main,
            subscriptionIdClosure: subscriptionIdClosure,
            notificationClosure: notificationClosure
        )
    }
}

extension ParaStkStakeConfirmInteractor: WalletLocalStorageSubscriber, WalletLocalSubscriptionHandler {
    func handleAssetBalance(
        result: Result<AssetBalance?, Error>,
        accountId _: AccountId,
        chainId _: ChainModel.Id,
        assetId _: AssetModel.Id
    ) {
        switch result {
        case let .success(balance):
            presenter?.didReceiveAssetBalance(balance)
        case let .failure(error):
            presenter?.didReceiveError(error)
        }
    }
}

extension ParaStkStakeConfirmInteractor: PriceLocalStorageSubscriber, PriceLocalSubscriptionHandler {
    func handlePrice(
        result: Result<PriceData?, Error>,
        priceId _: AssetModel.PriceId
    ) {
        switch result {
        case let .success(priceData):
            presenter?.didReceivePrice(priceData)
        case let .failure(error):
            presenter?.didReceiveError(error)
        }
    }
}

extension ParaStkStakeConfirmInteractor: ParastakingLocalStorageSubscriber, ParastakingLocalStorageHandler {
    func handleParastakingDelegatorState(
        result: Result<ParachainStaking.Delegator?, Error>,
        for _: ChainModel.Id,
        accountId _: AccountId
    ) {
        switch result {
        case let .success(delegator):
            presenter?.didReceiveDelegator(delegator)
        case let .failure(error):
            presenter?.didReceiveError(error)
        }
    }

    func handleParastakingCandidateMetadata(
        result: Result<ParachainStaking.CandidateMetadata?, Error>,
        for _: ChainModel.Id,
        accountId _: AccountId
    ) {
        switch result {
        case let .success(metadata):
            presenter?.didReceiveCollator(metadata: metadata)
        case let .failure(error):
            presenter?.didReceiveError(error)
        }
    }
}

extension ParaStkStakeConfirmInteractor: ExtrinsicFeeProxyDelegate {
    func didReceiveFee(result: Result<RuntimeDispatchInfo, Error>, for _: ExtrinsicFeeId) {
        presenter?.didReceiveFee(result)
    }
}

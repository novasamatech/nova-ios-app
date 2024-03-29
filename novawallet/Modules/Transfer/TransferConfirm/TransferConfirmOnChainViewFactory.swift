import Foundation
import SoraFoundation
import SoraKeystore

// swiftlint:disable function_body_length
struct TransferConfirmOnChainViewFactory {
    static func createView(
        chainAsset: ChainAsset,
        recepient: AccountAddress,
        amount: OnChainTransferAmount<Decimal>
    ) -> TransferConfirmOnChainViewProtocol? {
        let walletSettings = SelectedWalletSettings.shared

        guard
            let wallet = walletSettings.value,
            let selectedAccount = wallet.fetch(for: chainAsset.chain.accountRequest()),
            let senderAccountAddress = selectedAccount.toAddress(),
            let currencyManager = CurrencyManager.shared,
            let interactor = createInteractor(
                for: chainAsset,
                account: selectedAccount,
                accountMetaId: wallet.metaId
            ) else {
            return nil
        }

        let wireframe = TransferConfirmWireframe()

        let localizationManager = LocalizationManager.shared

        let networkViewModelFactory = NetworkViewModelFactory()
        let priceAssetInfoFactory = PriceAssetInfoFactory(currencyManager: currencyManager)
        let sendingBalanceViewModelFactory = BalanceViewModelFactory(
            targetAssetInfo: chainAsset.assetDisplayInfo,
            priceAssetInfoFactory: priceAssetInfoFactory
        )

        let utilityBalanceViewModelFactory: BalanceViewModelFactoryProtocol?

        if
            let utilityAsset = chainAsset.chain.utilityAssets().first,
            utilityAsset.assetId != chainAsset.asset.assetId {
            let utilityAssetInfo = utilityAsset.displayInfo(with: chainAsset.chain.icon)
            utilityBalanceViewModelFactory = BalanceViewModelFactory(
                targetAssetInfo: utilityAssetInfo,
                priceAssetInfoFactory: priceAssetInfoFactory
            )
        } else {
            utilityBalanceViewModelFactory = nil
        }

        let dataValidatingFactory = TransferDataValidatorFactory(
            presentable: wireframe,
            assetDisplayInfo: chainAsset.assetDisplayInfo,
            utilityAssetInfo: chainAsset.chain.utilityAssets().first?.displayInfo,
            priceAssetInfoFactory: priceAssetInfoFactory
        )

        let presenter = TransferOnChainConfirmPresenter(
            interactor: interactor,
            wireframe: wireframe,
            wallet: wallet,
            recepient: recepient,
            amount: amount,
            displayAddressViewModelFactory: DisplayAddressViewModelFactory(),
            chainAsset: chainAsset,
            networkViewModelFactory: networkViewModelFactory,
            sendingBalanceViewModelFactory: sendingBalanceViewModelFactory,
            utilityBalanceViewModelFactory: utilityBalanceViewModelFactory,
            senderAccountAddress: senderAccountAddress,
            dataValidatingFactory: dataValidatingFactory,
            localizationManager: localizationManager
        )

        let view = TransferConfirmViewController(
            presenter: presenter,
            localizationManager: localizationManager
        )

        presenter.view = view
        dataValidatingFactory.view = view
        interactor.presenter = presenter

        return view
    }

    private static func createInteractor(
        for chainAsset: ChainAsset,
        account: ChainAccountResponse,
        accountMetaId: String
    ) -> (OnChainTransferBaseInteractor & TransferConfirmOnChainInteractorInputProtocol)? {
        if chainAsset.asset.isEvm {
            return createEvmInteractor(for: chainAsset, account: account)
        } else {
            return createSubstrateInteractor(for: chainAsset, account: account, accountMetaId: accountMetaId)
        }
    }

    private static func createEvmInteractor(
        for chainAsset: ChainAsset,
        account: ChainAccountResponse
    ) -> TransferEvmOnChainConfirmInteractor? {
        let chainRegistry = ChainRegistryFacade.sharedRegistry
        let chain = chainAsset.chain
        let asset = chainAsset.asset

        guard
            let ethereumResponse = SelectedWalletSettings.shared.value?.fetchEthereum(for: account.accountId),
            let connection = chainRegistry.getConnection(for: chain.chainId),
            let currencyManager = CurrencyManager.shared else {
            return nil
        }

        let operationQueue = OperationManagerFacade.sharedDefaultQueue

        let extrinsicService = EvmTransactionService(
            accountId: account.accountId,
            operationFactory: EvmWebSocketOperationFactory(connection: connection),
            chain: chain,
            operationQueue: operationQueue
        )

        let signingWrapper = SigningWrapperFactory().createSigningWrapper(for: ethereumResponse)

        let repositoryFactory = SubstrateRepositoryFactory()
        let transactionStorage = repositoryFactory.createTxRepository()
        let persistentExtrinsicService = PersistentExtrinsicService(
            repository: transactionStorage,
            operationQueue: OperationManagerFacade.sharedDefaultQueue
        )

        return TransferEvmOnChainConfirmInteractor(
            selectedAccount: account,
            chain: chain,
            asset: asset,
            feeProxy: EvmTransactionFeeProxy(),
            extrinsicService: extrinsicService,
            walletLocalSubscriptionFactory: WalletLocalSubscriptionFactory.shared,
            priceLocalSubscriptionFactory: PriceProviderFactory.shared,
            signingWrapper: signingWrapper,
            persistExtrinsicService: persistentExtrinsicService,
            eventCenter: EventCenter.shared,
            currencyManager: currencyManager,
            operationQueue: operationQueue
        )
    }

    private static func createSubstrateInteractor(
        for chainAsset: ChainAsset,
        account: ChainAccountResponse,
        accountMetaId: String
    ) -> TransferOnChainConfirmInteractor? {
        let chainRegistry = ChainRegistryFacade.sharedRegistry
        let chain = chainAsset.chain
        let asset = chainAsset.asset

        guard
            let runtimeProvider = chainRegistry.getRuntimeProvider(for: chain.chainId),
            let connection = chainRegistry.getConnection(for: chain.chainId),
            let currencyManager = CurrencyManager.shared else {
            return nil
        }

        let repositoryFactory = SubstrateRepositoryFactory()

        let walletRemoteSubscriptionService = WalletServiceFacade.sharedRemoteSubscriptionService

        let walletRemoteSubscriptionWrapper = WalletRemoteSubscriptionWrapper(
            remoteSubscriptionService: walletRemoteSubscriptionService,
            chainRegistry: chainRegistry,
            repositoryFactory: repositoryFactory,
            eventCenter: EventCenter.shared,
            operationQueue: OperationManagerFacade.sharedDefaultQueue,
            logger: Logger.shared
        )

        let extrinsicService = ExtrinsicServiceFactory(
            runtimeRegistry: runtimeProvider,
            engine: connection,
            operationManager: OperationManagerFacade.sharedManager
        ).createService(account: account, chain: chain)

        let signingWrapper = SigningWrapperFactory().createSigningWrapper(
            for: accountMetaId,
            accountResponse: account
        )

        let transactionStorage = repositoryFactory.createTxRepository()
        let persistentExtrinsicService = PersistentExtrinsicService(
            repository: transactionStorage,
            operationQueue: OperationManagerFacade.sharedDefaultQueue
        )

        return TransferOnChainConfirmInteractor(
            selectedAccount: account,
            chain: chain,
            asset: asset,
            runtimeService: runtimeProvider,
            feeProxy: ExtrinsicFeeProxy(),
            extrinsicService: extrinsicService,
            signingWrapper: signingWrapper,
            persistExtrinsicService: persistentExtrinsicService,
            eventCenter: EventCenter.shared,
            walletRemoteWrapper: walletRemoteSubscriptionWrapper,
            walletLocalSubscriptionFactory: WalletLocalSubscriptionFactory.shared,
            priceLocalSubscriptionFactory: PriceProviderFactory.shared,
            substrateStorageFacade: SubstrateDataStorageFacade.shared,
            currencyManager: currencyManager,
            operationQueue: OperationManagerFacade.sharedDefaultQueue
        )
    }
}

// swiftlint:enable function_body_length

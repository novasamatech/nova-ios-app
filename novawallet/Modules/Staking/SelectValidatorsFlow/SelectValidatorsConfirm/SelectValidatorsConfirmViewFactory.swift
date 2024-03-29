import Foundation
import SoraKeystore
import SoraFoundation
import RobinHood
import SubstrateSdk

final class SelectValidatorsConfirmViewFactory {
    static func createInitiatedBondingView(
        for state: PreparedNomination<InitiatedBonding>,
        stakingState: StakingSharedState
    ) -> SelectValidatorsConfirmViewProtocol? {
        let keystore = Keychain()

        guard
            let metaAccount = SelectedWalletSettings.shared.value,
            let chainAsset = stakingState.settings.value,
            let metaAccountResponse = metaAccount.fetchMetaChainAccount(for: chainAsset.chain.accountRequest()),
            let currencyManager = CurrencyManager.shared,
            let interactor = createInitiatedBondingInteractor(
                state,
                selectedMetaAccount: metaAccountResponse,
                stakingState: stakingState,
                keystore: keystore
            ) else {
            return nil
        }

        let wireframe = SelectValidatorsConfirmWireframe()

        let title = LocalizableResource { locale in
            R.string.localizable.stakingStartTitle(preferredLanguages: locale.rLanguages)
        }

        return createView(
            for: interactor,
            wireframe: wireframe,
            stakingState: stakingState,
            title: title,
            priceAssetInfoFactory: PriceAssetInfoFactory(currencyManager: currencyManager)
        )
    }

    static func createChangeTargetsView(
        for state: PreparedNomination<ExistingBonding>,
        stakingState: StakingSharedState
    ) -> SelectValidatorsConfirmViewProtocol? {
        let wireframe = SelectValidatorsConfirmWireframe()
        return createExistingBondingView(for: state, wireframe: wireframe, stakingState: stakingState)
    }

    static func createChangeYourValidatorsView(
        for state: PreparedNomination<ExistingBonding>,
        stakingState: StakingSharedState
    ) -> SelectValidatorsConfirmViewProtocol? {
        let wireframe = YourValidatorList.SelectValidatorsConfirmWireframe()
        return createExistingBondingView(for: state, wireframe: wireframe, stakingState: stakingState)
    }

    private static func createExistingBondingView(
        for state: PreparedNomination<ExistingBonding>,
        wireframe: SelectValidatorsConfirmWireframeProtocol,
        stakingState: StakingSharedState
    ) -> SelectValidatorsConfirmViewProtocol? {
        let keystore = Keychain()

        guard let currencyManager = CurrencyManager.shared,
              let interactor = createChangeTargetsInteractor(
                  state,
                  state: stakingState,
                  keystore: keystore
              ) else {
            return nil
        }

        let title = LocalizableResource { locale in
            R.string.localizable.stakingChangeValidators(preferredLanguages: locale.rLanguages)
        }

        return createView(
            for: interactor,
            wireframe: wireframe,
            stakingState: stakingState,
            title: title,
            priceAssetInfoFactory: PriceAssetInfoFactory(currencyManager: currencyManager)
        )
    }

    private static func createView(
        for interactor: SelectValidatorsConfirmInteractorBase,
        wireframe: SelectValidatorsConfirmWireframeProtocol,
        stakingState: StakingSharedState,
        title: LocalizableResource<String>,
        priceAssetInfoFactory: PriceAssetInfoFactoryProtocol
    ) -> SelectValidatorsConfirmViewProtocol? {
        guard let chainAsset = stakingState.settings.value else {
            return nil
        }

        let confirmViewModelFactory = SelectValidatorsConfirmViewModelFactory()

        let assetInfo = chainAsset.assetDisplayInfo
        let balanceViewModelFactory = BalanceViewModelFactory(
            targetAssetInfo: assetInfo,
            priceAssetInfoFactory: priceAssetInfoFactory
        )

        let dataValidatingFactory = StakingDataValidatingFactory(
            presentable: wireframe,
            balanceFactory: balanceViewModelFactory
        )

        let presenter = SelectValidatorsConfirmPresenter(
            interactor: interactor,
            wireframe: wireframe,
            confirmationViewModelFactory: confirmViewModelFactory,
            balanceViewModelFactory: balanceViewModelFactory,
            dataValidatingFactory: dataValidatingFactory,
            assetInfo: assetInfo,
            chain: chainAsset.chain,
            logger: Logger.shared
        )

        let view = SelectValidatorsConfirmViewController(
            presenter: presenter,
            localizableTitle: title,
            quantityFormatter: .quantity,
            localizationManager: LocalizationManager.shared
        )

        presenter.view = view
        interactor.presenter = presenter
        dataValidatingFactory.view = view

        return view
    }

    private static func createInitiatedBondingInteractor(
        _ nomination: PreparedNomination<InitiatedBonding>,
        selectedMetaAccount: MetaChainAccountResponse,
        stakingState: StakingSharedState,
        keystore: KeystoreProtocol
    ) -> SelectValidatorsConfirmInteractorBase? {
        let chainRegistry = ChainRegistryFacade.sharedRegistry

        let operationManager = OperationManagerFacade.sharedManager

        guard
            let chainAsset = stakingState.settings.value,
            let connection = chainRegistry.getConnection(for: chainAsset.chain.chainId),
            let runtimeService = chainRegistry.getRuntimeProvider(for: chainAsset.chain.chainId),
            let selectedAccount = try? selectedMetaAccount.toWalletDisplayAddress(),
            let currencyManager = CurrencyManager.shared,
            let stakingDurationFactory = try? stakingState.createStakingDurationOperationFactory(
                for: chainAsset.chain
            ) else {
            return nil
        }

        let extrinsicService = ExtrinsicServiceFactory(
            runtimeRegistry: runtimeService,
            engine: connection,
            operationManager: operationManager
        ).createService(account: selectedMetaAccount.chainAccount, chain: chainAsset.chain)

        let signer = SigningWrapperFactory(keystore: keystore).createSigningWrapper(
            for: selectedMetaAccount.metaId,
            accountResponse: selectedMetaAccount.chainAccount
        )

        return InitiatedBondingConfirmInteractor(
            selectedAccount: selectedAccount,
            chainAsset: chainAsset,
            stakingLocalSubscriptionFactory: stakingState.stakingLocalSubscriptionFactory,
            walletLocalSubscriptionFactory: WalletLocalSubscriptionFactory.shared,
            priceLocalSubscriptionFactory: PriceProviderFactory.shared,
            extrinsicService: extrinsicService,
            runtimeService: runtimeService,
            durationOperationFactory: stakingDurationFactory,
            operationManager: operationManager,
            signer: signer,
            nomination: nomination,
            currencyManager: currencyManager
        )
    }

    private static func createChangeTargetsInteractor(
        _ nomination: PreparedNomination<ExistingBonding>,
        state: StakingSharedState,
        keystore: KeystoreProtocol
    ) -> SelectValidatorsConfirmInteractorBase? {
        let chainRegistry = ChainRegistryFacade.sharedRegistry

        let operationManager = OperationManagerFacade.sharedManager

        guard
            let chainAsset = state.settings.value,
            let currencyManager = CurrencyManager.shared,
            let connection = chainRegistry.getConnection(for: chainAsset.chain.chainId),
            let runtimeService = chainRegistry.getRuntimeProvider(for: chainAsset.chain.chainId),
            let stakingDurationFactory = try? state.createStakingDurationOperationFactory(
                for: chainAsset.chain
            ) else {
            return nil
        }

        let extrinsicSender = nomination.bonding.controllerAccount

        let extrinsicService = ExtrinsicServiceFactory(
            runtimeRegistry: runtimeService,
            engine: connection,
            operationManager: operationManager
        ).createService(account: extrinsicSender.chainAccount, chain: chainAsset.chain)

        let signer = SigningWrapperFactory(keystore: keystore).createSigningWrapper(
            for: extrinsicSender.metaId,
            accountResponse: extrinsicSender.chainAccount
        )

        let accountRepository = AccountRepositoryFactory(storageFacade: UserDataStorageFacade.shared)

        return ChangeTargetsConfirmInteractor(
            chainAsset: chainAsset,
            stakingLocalSubscriptionFactory: state.stakingLocalSubscriptionFactory,
            walletLocalSubscriptionFactory: WalletLocalSubscriptionFactory.shared,
            priceLocalSubscriptionFactory: PriceProviderFactory.shared,
            extrinsicService: extrinsicService,
            runtimeService: runtimeService,
            durationOperationFactory: stakingDurationFactory,
            operationManager: operationManager,
            signer: signer,
            accountRepositoryFactory: accountRepository,
            nomination: nomination,
            currencyManager: currencyManager
        )
    }
}

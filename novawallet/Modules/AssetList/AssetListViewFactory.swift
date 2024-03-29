import Foundation
import SoraFoundation
import SoraKeystore

struct AssetListViewFactory {
    static func createView() -> AssetListViewProtocol? {
        guard let currencyManager = CurrencyManager.shared else {
            return nil
        }

        let interactor = AssetListInteractor(
            selectedWalletSettings: SelectedWalletSettings.shared,
            chainRegistry: ChainRegistryFacade.sharedRegistry,
            walletLocalSubscriptionFactory: WalletLocalSubscriptionFactory.shared,
            nftLocalSubscriptionFactory: NftLocalSubscriptionFactory.shared,
            crowdloansLocalSubscriptionFactory: CrowdloanContributionLocalSubscriptionFactory.shared,
            priceLocalSubscriptionFactory: PriceProviderFactory.shared,
            eventCenter: EventCenter.shared,
            settingsManager: SettingsManager.shared,
            currencyManager: currencyManager,
            logger: Logger.shared
        )

        let walletUpdater = WalletDetailsUpdater(
            eventCenter: EventCenter.shared,
            crowdloansLocalSubscriptionFactory: interactor.crowdloansLocalSubscriptionFactory,
            walletLocalSubscriptionFactory: interactor.walletLocalSubscriptionFactory,
            walletSettings: interactor.selectedWalletSettings
        )

        let wireframe = AssetListWireframe(walletUpdater: walletUpdater)

        let nftDownloadService = NftFileDownloadService(
            cacheBasePath: ApplicationConfig.shared.fileCachePath,
            fileRepository: FileRepository(),
            fileDownloadFactory: FileDownloadOperationFactory(),
            operationQueue: OperationManagerFacade.fileDownloadQueue
        )

        let priceAssetInfoFactory = PriceAssetInfoFactory(currencyManager: currencyManager)
        let viewModelFactory = AssetListViewModelFactory(
            priceAssetInfoFactory: priceAssetInfoFactory,
            assetFormatterFactory: AssetBalanceFormatterFactory(),
            percentFormatter: NumberFormatter.signedPercent.localizableResource(),
            quantityFormatter: NumberFormatter.quantity.localizableResource(),
            nftDownloadService: nftDownloadService,
            currencyManager: currencyManager
        )
        let localizationManager = LocalizationManager.shared

        let presenter = AssetListPresenter(
            interactor: interactor,
            wireframe: wireframe,
            viewModelFactory: viewModelFactory,
            localizationManager: localizationManager
        )

        let view = AssetListViewController(
            presenter: presenter,
            localizationManager: localizationManager
        )

        presenter.view = view
        interactor.presenter = presenter

        return view
    }
}

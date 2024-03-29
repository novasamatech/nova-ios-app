import Foundation
import CommonWallet
import SoraFoundation
import IrohaCrypto

struct WalletCommonConfigurator {
    let localizationManager: LocalizationManagerProtocol
    let currencyManager: CurrencyManagerProtocol
    let chainAccount: ChainAccountResponse
    let assets: [WalletAsset]

    init(
        chainAccount: ChainAccountResponse,
        localizationManager: LocalizationManagerProtocol,
        currencyManager: CurrencyManagerProtocol,
        assets: [WalletAsset]
    ) {
        self.localizationManager = localizationManager
        self.currencyManager = currencyManager
        self.chainAccount = chainAccount
        self.assets = assets
    }

    func configure(builder: CommonWalletBuilderProtocol) {
        let language = WalletLanguage(rawValue: localizationManager.selectedLocalization)
            ?? WalletLanguage.defaultLanguage

        let decoratorFactory = WalletCommandDecoratorFactory(
            localizationManager: localizationManager,
            dataStorageFacade: SubstrateDataStorageFacade.shared
        )

        let qrCoderFactory = WalletQRCoderFactory(
            addressPrefix: chainAccount.addressPrefix,
            chainFormat: chainAccount.chainFormat,
            publicKey: chainAccount.publicKey,
            username: chainAccount.name,
            assets: assets
        )

        let singleProviderIdFactory = WalletSingleProviderIdFactory(
            currencyId: currencyManager.selectedCurrency.id
        )

        let transactionTypes = TransactionType.allCases.map { $0.toWalletType() }

        builder
            .with(language: language)
            .with(commandDecoratorFactory: decoratorFactory)
            .with(logger: Logger.shared)
            .with(transactionTypeList: transactionTypes)
            .with(amountFormatterFactory: AmountFormatterFactory())
            .with(singleProviderIdentifierFactory: singleProviderIdFactory)
            .with(qrCoderFactory: qrCoderFactory)
    }
}

import Foundation
import SoraFoundation

extension ImportChainAccount {
    final class AccountImportPresenter: BaseAccountImportPresenter {
        let metaAccountModel: MetaAccountModel
        let chainModelId: ChainModel.Id
        let isEthereumBased: Bool

        init(
            secretSource: SecretSource,
            metaAccountModel: MetaAccountModel,
            chainModelId: ChainModel.Id,
            isEthereumBased: Bool
        ) {
            self.metaAccountModel = metaAccountModel
            self.chainModelId = chainModelId
            self.isEthereumBased = isEthereumBased

            super.init(secretSource: secretSource)
        }

        private func proceedWithSubstrate() {
            guard
                let selectedCryptoType = selectedSubstrateCryptoType,
                let sourceViewModel = sourceViewModel
            else {
                return
            }

            if let error = validateSourceViewModel() {
                _ = wireframe.present(
                    error: error,
                    from: view,
                    locale: localizationManager?.selectedLocale
                )
                return
            }

            let substrateDerivationPath = self.substrateDerivationPath ?? ""

            switch selectedSourceType {
            case .mnemonic:
                let mnemonic = sourceViewModel.inputHandler.normalizedValue
                let request = ChainAccountImportMnemonicRequest(
                    mnemonic: mnemonic,
                    derivationPath: substrateDerivationPath,
                    cryptoType: selectedCryptoType
                )

                interactor.importAccountWithMnemonic(
                    chainId: chainModelId,
                    request: request,
                    into: metaAccountModel
                )

            case .seed:
                let seed = sourceViewModel.inputHandler.value
                let request = ChainAccountImportSeedRequest(
                    seed: seed,
                    derivationPath: substrateDerivationPath,
                    cryptoType: selectedCryptoType
                )

                interactor.importAccountWithSeed(
                    chainId: chainModelId,
                    request: request,
                    into: metaAccountModel
                )

            case .keystore:
                let keystore = sourceViewModel.inputHandler.value
                let password = passwordViewModel?.inputHandler.value ?? ""
                let request = ChainAccountImportKeystoreRequest(
                    keystore: keystore,
                    password: password,
                    cryptoType: selectedCryptoType
                )

                interactor.importAccountWithKeystore(
                    chainId: chainModelId,
                    request: request,
                    into: metaAccountModel
                )
            }
        }

        private func proceedWithEthereum() {
            guard let sourceViewModel = sourceViewModel else {
                return
            }

            if let error = validateSourceViewModel() {
                _ = wireframe.present(
                    error: error,
                    from: view,
                    locale: localizationManager?.selectedLocale
                )
                return
            }

            let cryptoType: MultiassetCryptoType = .ethereumEcdsa

            let ethereumDerivationPath = self.ethereumDerivationPath ?? ""

            switch selectedSourceType {
            case .mnemonic:
                let mnemonic = sourceViewModel.inputHandler.normalizedValue
                let request = ChainAccountImportMnemonicRequest(
                    mnemonic: mnemonic,
                    derivationPath: ethereumDerivationPath,
                    cryptoType: cryptoType
                )

                interactor.importAccountWithMnemonic(
                    chainId: chainModelId,
                    request: request,
                    into: metaAccountModel
                )

            case .seed:
                let seed = sourceViewModel.inputHandler.value
                let request = ChainAccountImportSeedRequest(
                    seed: seed,
                    derivationPath: ethereumDerivationPath,
                    cryptoType: cryptoType
                )

                interactor.importAccountWithSeed(
                    chainId: chainModelId,
                    request: request,
                    into: metaAccountModel
                )

            case .keystore:
                let keystore = sourceViewModel.inputHandler.value
                let password = passwordViewModel?.inputHandler.value ?? ""
                let request = ChainAccountImportKeystoreRequest(
                    keystore: keystore,
                    password: password,
                    cryptoType: cryptoType
                )

                interactor.importAccountWithKeystore(
                    chainId: chainModelId,
                    request: request,
                    into: metaAccountModel
                )
            }
        }

        override func processProceed() {
            if isEthereumBased {
                proceedWithEthereum()
            } else {
                proceedWithSubstrate()
            }
        }

        override func applyUsernameViewModel(_: String = "") {
            view?.setName(viewModel: nil)
        }

        override func showUploadWarningIfNeeded(_ preferredInfo: MetaAccountImportPreferredInfo) {
            if (try? Data(hexString: chainModelId)) != preferredInfo.genesisHash {
                let message = R.string.localizable
                    .accountImportWrongNetwork(preferredLanguages: selectedLocale.rLanguages)
                view?.setUploadWarning(message: message)
                return
            }
        }

        override func shouldUseEthereumSeed() -> Bool { isEthereumBased }

        override func getAdvancedSettings() -> AdvancedWalletSettings? {
            if isEthereumBased {
                return .ethereum(derivationPath: ethereumDerivationPath)
            } else {
                guard let metadata = metadata else {
                    return nil
                }

                let substrateSettings = AdvancedNetworkTypeSettings(
                    availableCryptoTypes: metadata.availableCryptoTypes,
                    selectedCryptoType: selectedSubstrateCryptoType ?? metadata.defaultCryptoType,
                    derivationPath: substrateDerivationPath
                )

                return .substrate(settings: substrateSettings)
            }
        }
    }
}

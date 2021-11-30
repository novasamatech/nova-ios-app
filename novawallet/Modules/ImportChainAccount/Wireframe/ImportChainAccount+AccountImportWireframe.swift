import Foundation
import IrohaCrypto

extension ImportChainAccount {
    final class AccountImportWireframe: AccountImportWireframeProtocol {
        func proceed(from view: AccountImportViewProtocol?) {
            guard let navigationController = view?.controller.navigationController else {
                return
            }

            MainTransitionHelper.transitToMainTabBarController(
                closing: navigationController,
                animated: true
            )
        }

        func showAdvancedSettings(
            from view: AccountImportViewProtocol?,
            secretSource: SecretSource,
            settings: AdvancedWalletSettings,
            delegate: AdvancedWalletSettingsDelegate
        ) {
            guard let advancedView = AdvancedWalletViewFactory.createView(
                for: secretSource,
                advancedSettings: settings,
                delegate: delegate
            ) else {
                return
            }

            let navigationController = FearlessNavigationController(rootViewController: advancedView.controller)

            view?.controller.present(navigationController, animated: true)
        }
    }
}

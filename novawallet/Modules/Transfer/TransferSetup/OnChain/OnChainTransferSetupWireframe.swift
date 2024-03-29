import Foundation
import CommonWallet

final class OnChainTransferSetupWireframe: OnChainTransferSetupWireframeProtocol {
    weak var commandFactory: WalletCommandFactoryProtocol?

    func showConfirmation(
        from _: TransferSetupChildViewProtocol?,
        chainAsset: ChainAsset,
        sendingAmount: OnChainTransferAmount<Decimal>,
        recepient: AccountAddress
    ) {
        guard let confirmView = TransferConfirmOnChainViewFactory.createView(
            chainAsset: chainAsset,
            recepient: recepient,
            amount: sendingAmount
        ) else {
            return
        }

        let command = commandFactory?.preparePresentationCommand(for: confirmView.controller)
        command?.presentationStyle = .push(hidesBottomBar: true)
        try? command?.execute()
    }
}

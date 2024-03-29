import Foundation

extension SwitchAccount {
    final class ParitySignerWelcomeWireframe: ParitySignerWelcomeWireframeProtocol {
        func showScanQR(from view: ParitySignerWelcomeViewProtocol?) {
            guard let scanView = ParitySignerScanViewFactory.createSwitchAccountView() else {
                return
            }

            view?.controller.navigationController?.pushViewController(scanView.controller, animated: true)
        }
    }
}

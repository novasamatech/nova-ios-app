import UIKit

class WalletManageViewLayout: WalletsListViewLayout {
    let addWalletButton: TriangularedButton = {
        let button = TriangularedButton()
        button.applyDefaultStyle()
        button.changesContentOpacityWhenHighlighted = true
        return button
    }()

    let editButton: UIBarButtonItem = {
        let button = UIBarButtonItem()
        button.style = .plain

        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: R.color.colorButtonTextAccent()!,
            .font: UIFont.regularBody
        ]

        button.setTitleTextAttributes(attributes, for: .normal)
        button.setTitleTextAttributes(attributes, for: .highlighted)

        return button
    }()

    override func setupLayout() {
        super.setupLayout()

        addSubview(addWalletButton)
        addWalletButton.snp.makeConstraints { make in
            make.height.equalTo(UIConstants.actionHeight)
            make.leading.trailing.equalToSuperview().inset(UIConstants.horizontalInset)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(UIConstants.actionBottomInset)
        }

        let bottomInset = UIConstants.actionBottomInset + UIConstants.actionHeight + 16.0
        tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: bottomInset, right: 0.0)
    }
}

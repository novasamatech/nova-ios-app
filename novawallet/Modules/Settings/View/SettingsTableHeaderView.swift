import UIKit

final class SettingsTableHeaderView: UIView {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = R.color.colorTextPrimary()
        label.font = .boldLargeTitle
        return label
    }()

    let walletSwitch = WalletSwitchControl()

    let accountDetailsView: DetailsTriangularedView = {
        let detailsView = DetailsTriangularedView()
        detailsView.layout = .singleTitle
        detailsView.iconRadius = UIConstants.normalAddressIconSize.height / 2.0
        detailsView.titleLabel.lineBreakMode = .byTruncatingTail
        detailsView.titleLabel.font = .regularSubheadline
        detailsView.titleLabel.textColor = R.color.colorTextPrimary()
        detailsView.actionImage = R.image.iconChevronRight()?.tinted(with: R.color.colorIconSecondary()!)
        detailsView.fillColor = R.color.colorBlockBackground()!
        detailsView.highlightedFillColor = R.color.colorCellBackgroundPressed()!
        detailsView.horizontalSpacing = 12.0
        detailsView.contentInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return detailsView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(walletSwitch)
        walletSwitch.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10.0)
            make.trailing.equalToSuperview().inset(UIConstants.horizontalInset)
            make.size.equalTo(UIConstants.walletSwitchSize)
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(UIConstants.horizontalInset)
            make.centerY.equalTo(walletSwitch.snp.centerY)
        }

        addSubview(accountDetailsView)
        accountDetailsView.snp.makeConstraints { make in
            make.top.equalTo(walletSwitch.snp.bottom).offset(16.0)
            make.leading.trailing.equalToSuperview().inset(UIConstants.horizontalInset)
            make.height.equalTo(52.0)
        }
    }
}

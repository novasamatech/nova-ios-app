import UIKit

final class GovernanceRemoveVotesConfirmViewLayout: UIView {
    let containerView: ScrollableContainerView = {
        let view = ScrollableContainerView(axis: .vertical, respectsSafeArea: true)
        view.stackView.layoutMargins = UIEdgeInsets(top: 16.0, left: 16.0, bottom: 0.0, right: 16.0)
        view.stackView.isLayoutMarginsRelativeArrangement = true
        view.stackView.alignment = .fill
        return view
    }()

    let senderTableView = StackTableView()

    let walletCell = StackTableCell()

    let accountCell: StackInfoTableCell = .create {
        $0.detailsLabel.lineBreakMode = .byTruncatingMiddle
    }

    let feeCell = StackNetworkFeeCell()

    let tracksTableView = StackTableView()

    let actionLoadableView = LoadableActionView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = R.color.colorSecondaryScreenBackground()

        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @discardableResult
    func setNotSelectableTracks(for title: String, tracks: String) -> StackTableCell {
        tracksTableView.clear()

        return tracksTableView.addTitleValueCell(for: title, value: tracks)
    }

    func setSelectableTracks(for title: String, tracks: String) -> StackInfoTableCell {
        tracksTableView.clear()

        return tracksTableView.addInfoCell(for: title, value: tracks)
    }

    private func setupLayout() {
        addSubview(actionLoadableView)
        actionLoadableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(UIConstants.horizontalInset)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(UIConstants.actionBottomInset)
            make.height.equalTo(UIConstants.actionHeight)
        }

        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(actionLoadableView.snp.top).offset(-8.0)
        }

        containerView.stackView.addArrangedSubview(senderTableView)
        containerView.stackView.setCustomSpacing(8.0, after: senderTableView)

        senderTableView.addArrangedSubview(walletCell)
        senderTableView.addArrangedSubview(accountCell)
        senderTableView.addArrangedSubview(feeCell)

        containerView.stackView.addArrangedSubview(tracksTableView)
    }
}

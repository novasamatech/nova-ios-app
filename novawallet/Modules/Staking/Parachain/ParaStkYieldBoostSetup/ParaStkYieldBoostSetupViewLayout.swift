import UIKit

final class ParaStkYieldBoostSetupViewLayout: UIView {
    private enum Constants {
        static let hasYieldBoostSpacing: CGFloat = 16.0
        static let noYieldBoostSpacing: CGFloat = 8.0
    }

    let containerView: ScrollableContainerView = {
        let view = ScrollableContainerView(axis: .vertical, respectsSafeArea: true)
        view.stackView.layoutMargins = UIEdgeInsets(top: 8.0, left: 16.0, bottom: 0.0, right: 16.0)
        view.stackView.isLayoutMarginsRelativeArrangement = true
        view.stackView.alignment = .fill
        return view
    }()

    let actionLoadableView = LoadableActionView()

    var actionButton: TriangularedButton {
        actionLoadableView.actionButton
    }

    let collatorTitleLabel: UILabel = .create {
        $0.font = .semiBoldBody
        $0.textColor = R.color.colorTextPrimary()
        $0.numberOfLines = 0
    }

    let collatorTableView: StackTableView = .create {
        $0.cellHeight = 34.0
        $0.contentInsets = UIEdgeInsets(top: 7.0, left: 16.0, bottom: 7.0, right: 16.0)
    }

    let collatorActionView = StackAccountSelectionCell()

    let rewardComparisonTitleLabel: UILabel = .create {
        $0.font = .semiBoldBody
        $0.textColor = R.color.colorTextPrimary()
        $0.numberOfLines = 0
    }

    let withoutYieldBoostOptionView = RewardSelectionView()
    let withYieldBoostOptionView = RewardSelectionView()

    let thresholdDetailsLabel: UILabel = .create {
        $0.font = .semiBoldBody
        $0.textColor = R.color.colorTextPrimary()
        $0.numberOfLines = 0
    }

    let amountView = TitleHorizontalMultiValueView()

    let amountInputView = NewAmountInputView()

    let networkFeeView: NetworkFeeView = {
        let view = UIFactory.default.createNetworkFeeView()
        view.verticalOffset = 13.0
        return view
    }()

    let poweredByView: UIImageView = .create {
        $0.image = R.image.imageYieldBoostPowered()
        $0.contentMode = .center
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = R.color.colorSecondaryScreenBackground()

        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(isYieldBoosted: Bool) {
        withoutYieldBoostOptionView.isChoosen = !isYieldBoosted
        withYieldBoostOptionView.isChoosen = isYieldBoosted

        thresholdDetailsLabel.isHidden = !isYieldBoosted
        amountView.isHidden = !isYieldBoosted
        amountInputView.isHidden = !isYieldBoosted
        poweredByView.isHidden = !isYieldBoosted

        if isYieldBoosted {
            containerView.stackView.setCustomSpacing(Constants.hasYieldBoostSpacing, after: withYieldBoostOptionView)
        } else {
            containerView.stackView.setCustomSpacing(Constants.noYieldBoostSpacing, after: withYieldBoostOptionView)
        }
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

        containerView.stackView.addArrangedSubview(collatorTitleLabel)
        containerView.stackView.setCustomSpacing(8.0, after: collatorTitleLabel)

        containerView.stackView.addArrangedSubview(collatorTableView)
        collatorTableView.addArrangedSubview(collatorActionView)

        containerView.stackView.setCustomSpacing(16.0, after: collatorTableView)

        containerView.stackView.addArrangedSubview(rewardComparisonTitleLabel)
        containerView.stackView.setCustomSpacing(8.0, after: rewardComparisonTitleLabel)

        containerView.stackView.addArrangedSubview(withoutYieldBoostOptionView)
        withoutYieldBoostOptionView.snp.makeConstraints { make in
            make.height.equalTo(56.0)
        }

        containerView.stackView.setCustomSpacing(12.0, after: withoutYieldBoostOptionView)

        containerView.stackView.addArrangedSubview(withYieldBoostOptionView)
        withYieldBoostOptionView.snp.makeConstraints { make in
            make.height.equalTo(56.0)
        }

        containerView.stackView.setCustomSpacing(Constants.hasYieldBoostSpacing, after: withYieldBoostOptionView)

        containerView.stackView.addArrangedSubview(thresholdDetailsLabel)

        containerView.stackView.addArrangedSubview(amountView)
        amountView.snp.makeConstraints { make in
            make.height.equalTo(36.0)
        }

        containerView.stackView.addArrangedSubview(amountInputView)
        amountInputView.snp.makeConstraints { make in
            make.height.equalTo(64.0)
        }

        containerView.stackView.setCustomSpacing(8.0, after: amountInputView)

        containerView.stackView.addArrangedSubview(networkFeeView)

        containerView.stackView.setCustomSpacing(8.0, after: networkFeeView)

        containerView.stackView.addArrangedSubview(poweredByView)
    }
}

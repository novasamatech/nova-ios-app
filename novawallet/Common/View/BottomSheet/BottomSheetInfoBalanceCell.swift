import UIKit

final class BottomSheetInfoBalanceCell: BottomSheetInfoTableCell, ModalPickerCellProtocol {
    enum Constants {
        static let verticalInset: CGFloat = 8.0
    }

    typealias Model = StakingAmountViewModel

    var checkmarked: Bool = false

    let amountLabel: UILabel = {
        let label = UILabel()
        label.font = .regularSubheadline
        label.textColor = R.color.colorTextPrimary()
        return label
    }()

    let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .regularFootnote
        label.textColor = R.color.colorTextSecondary()
        return label
    }()

    override func setupLayout() {
        super.setupLayout()
        contentView.addSubview(amountLabel)
        amountLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(UIConstants.horizontalInset)
            make.top.equalToSuperview().inset(Constants.verticalInset)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(UIConstants.horizontalInset)
        }

        contentView.addSubview(priceLabel)
        priceLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(UIConstants.horizontalInset)
            make.bottom.equalToSuperview().inset(Constants.verticalInset)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(UIConstants.horizontalInset)
            make.top.equalTo(amountLabel.snp.bottom)
        }
    }

    func bind(model: StakingAmountViewModel) {
        titleLabel.text = model.title
        amountLabel.text = model.balance.amount
        priceLabel.text = model.balance.price ?? ""

        setNeedsLayout()
    }
}

import UIKit

final class ReferendumVotersTableViewCell: UITableViewCell {
    enum Constants {
        static let rowHeight: CGFloat = 44.0
        static let titleValueSpacing: CGFloat = 32.0
        static let addressNameSpacing: CGFloat = 12.0
        static let addressIndicatorSpacing: CGFloat = 4.0
        static let iconSize = CGSize(width: 24.0, height: 24.0)
        static let indicatorSize = CGSize(width: 16.0, height: 16.0)
    }

    typealias ContentView = GenericTitleValueView<IconDetailsGenericView<IconDetailsView>, MultiValueView>

    let baseView = ContentView()

    var iconView: UIImageView {
        baseView.titleView.imageView
    }

    var nameLabel: UILabel {
        baseView.titleView.detailsView.detailsLabel
    }

    var indicatorView: UIImageView {
        baseView.titleView.detailsView.imageView
    }

    var votesLabel: UILabel {
        baseView.valueView.valueTop
    }

    var detailsLabel: UILabel {
        baseView.valueView.valueBottom
    }

    private var iconViewModel: ImageViewModelProtocol?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupLayout()
        applyStyle()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(viewModel: ReferendumVotersViewModel) {
        iconViewModel?.cancel(on: iconView)
        iconViewModel = viewModel.displayAddress.imageViewModel

        let imageSize = CGSize(width: baseView.titleView.iconWidth, height: baseView.titleView.iconWidth)
        iconViewModel?.loadImage(on: iconView, targetSize: imageSize, animated: true)

        let cellViewModel = viewModel.displayAddress.cellViewModel
        nameLabel.text = cellViewModel.details
        nameLabel.lineBreakMode = viewModel.displayAddress.lineBreakMode

        votesLabel.text = viewModel.votes
        detailsLabel.text = viewModel.preConviction

        setNeedsLayout()
    }

    private func applyStyle() {
        backgroundColor = .clear

        baseView.spacing = Constants.titleValueSpacing
        baseView.titleView.mode = .iconDetails
        baseView.titleView.iconWidth = Constants.iconSize.width
        baseView.titleView.spacing = Constants.addressNameSpacing

        baseView.titleView.detailsView.spacing = Constants.addressIndicatorSpacing
        baseView.titleView.detailsView.iconWidth = Constants.indicatorSize.width
        baseView.titleView.detailsView.mode = .detailsIcon

        baseView.valueView.stackView.alignment = .fill

        nameLabel.numberOfLines = 1
        nameLabel.apply(style: .footnoteSecondary)
        indicatorView.image = R.image.iconInfoFilled()?.tinted(with: R.color.colorIconSecondary()!)

        votesLabel.apply(style: .footnotePrimary)
        detailsLabel.apply(style: .caption1Secondary)

        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = R.color.colorCellBackgroundPressed()
        self.selectedBackgroundView = selectedBackgroundView
    }

    private func setupLayout() {
        contentView.addSubview(baseView)

        baseView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(UIConstants.horizontalInset)
            make.top.bottom.equalToSuperview()
        }
    }
}
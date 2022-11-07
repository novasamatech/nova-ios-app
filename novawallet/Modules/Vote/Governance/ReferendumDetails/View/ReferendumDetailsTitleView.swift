import UIKit
import SoraUI
import MarkdownView

final class ReferendumDetailsTitleView: UIView {
    var accountIconSize: CGSize {
        let size = accountContainerView.rowContentView.detailsView.iconWidth
        return CGSize(width: size, height: size)
    }

    var accountLabel: UILabel { accountContainerView.rowContentView.detailsView.detailsLabel }
    var accountImageView: UIImageView { accountContainerView.rowContentView.detailsView.imageView }

    let accountContainerView: RowView<IconDetailsGenericView<IconDetailsView>> = .create { view in
        view.roundedBackgroundView.highlightedFillColor = .clear
        view.changesContentOpacityWhenHighlighted = true
        view.borderView.borderType = .none

        view.preferredHeight = 36.0
        view.rowContentView.mode = .detailsIcon
        view.rowContentView.iconWidth = 16.0
        view.rowContentView.spacing = 6
        view.contentInsets = UIEdgeInsets(top: 9, left: 0, bottom: 9, right: 0)
        view.rowContentView.imageView.image = R.image.iconInfoFilled()?.tinted(with: R.color.colorWhite48()!)

        let addressView = view.rowContentView.detailsView
        addressView.spacing = 7
        addressView.detailsLabel.numberOfLines = 1
        addressView.detailsLabel.textColor = R.color.colorTransparentText()
        addressView.detailsLabel.font = .regularFootnote
        addressView.iconWidth = 18.0
    }

    private var addressImageViewModel: ImageViewModelProtocol?

    let titleLabel: UILabel = .create {
        $0.textColor = R.color.colorWhite()
        $0.font = .boldTitle1
        $0.numberOfLines = 0
    }

    let descriptionView: MarkdownView = .create {
        $0.isScrollEnabled = false
    }

    let moreButton: RoundedButton = .create { button in
        button.applyIconStyle()

        let color = R.color.colorAccent()!
        button.imageWithTitleView?.titleColor = color
        button.imageWithTitleView?.titleFont = .regularFootnote

        button.imageWithTitleView?.iconImage = R.image.iconLinkChevron()?.tinted(with: color)
        button.imageWithTitleView?.layoutType = .horizontalLabelFirst
        button.contentInsets = .zero

        button.imageWithTitleView?.spacingBetweenLabelAndIcon = 4.0
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        let content = UIView.vStack(
            alignment: .leading,
            spacing: 8,
            [
                accountContainerView,
                titleLabel,
                descriptionView,
                moreButton
            ]
        )
        content.setCustomSpacing(0, after: accountContainerView)
        addSubview(content)
        content.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        descriptionView.onRendered = { [weak self] contentHeight in
            self?.updateMarkdownView(height: contentHeight)
        }
    }

    private func updateMarkdownView(height: CGFloat) {
        descriptionView.snp.updateConstraints {
            $0.height.equalTo(height)
            $0.leading.trailing.equalToSuperview()
        }
    }
}

extension ReferendumDetailsTitleView {
    struct Model {
        let account: DisplayAddressViewModel?
        let details: Details?
    }

    struct Details {
        let title: String
        let description: String
        let shouldReadMore: Bool
    }

    func bind(viewModel: Model, locale: Locale) {
        addressImageViewModel?.cancel(on: accountImageView)
        addressImageViewModel = viewModel.account?.imageViewModel

        if let account = viewModel.account {
            accountContainerView.isHidden = false

            accountLabel.text = account.name ?? account.address.truncated

            account.imageViewModel?.loadImage(
                on: accountImageView,
                targetSize: accountIconSize,
                animated: true
            )

        } else {
            accountContainerView.isHidden = true
        }

        bind(details: viewModel.details, locale: locale)
    }

    private func bind(details: Details?, locale: Locale) {
        guard let details = details else {
            titleLabel.isHidden = true
            descriptionView.isHidden = true
            moreButton.isHidden = true
            return
        }
        titleLabel.isHidden = false
        titleLabel.text = details.title

        if !details.description.isEmpty {
            descriptionView.isHidden = false
            descriptionView.loadLimitedText(
                markdownText: details.description,
                maxLinesCount: 4
            )
        }

        moreButton.imageWithTitleView?.title = R.string.localizable.commonReadMore(
            preferredLanguages: locale.rLanguages
        )
        moreButton.isHidden = !details.shouldReadMore
    }
}

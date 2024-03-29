import UIKit
import SoraUI

final class AssetListChainView: UIView {
    let backgroundView: RoundedView = {
        let view = RoundedView()
        view.apply(style: .chips)
        view.cornerRadius = 7.0
        return view
    }()

    let iconView: UIImageView = {
        let view = UIImageView()
        return view
    }()

    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = R.color.colorChipText()
        label.font = .semiBoldCaps1
        return label
    }()

    let iconSize = CGSize(width: 24.0, height: 24.0)

    private var iconViewModel: ImageViewModelProtocol?

    convenience init() {
        let defaultFrame = CGRect(origin: .zero, size: CGSize(width: 48.0, height: 24.0))
        self.init(frame: defaultFrame)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear

        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(viewModel: NetworkViewModel) {
        nameLabel.text = viewModel.name.uppercased()

        iconViewModel?.cancel(on: iconView)
        iconViewModel = viewModel.icon
        viewModel.icon?.loadImage(on: iconView, targetSize: iconSize, animated: true)

        setNeedsLayout()
    }

    private func setupLayout() {
        addSubview(backgroundView)
        addSubview(iconView)
        addSubview(nameLabel)

        iconView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.size.equalTo(iconSize)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(8.0)
            make.trailing.equalToSuperview().inset(8.0)
            make.centerY.equalTo(iconView)
        }

        backgroundView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview().inset(1.0)
            make.trailing.equalToSuperview()
        }
    }
}

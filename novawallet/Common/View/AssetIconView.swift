import SoraUI

final class AssetIconView: UIView {
    let backgroundView: RoundedView = {
        let view = RoundedView()
        view.apply(style: .assetContainer)
        return view
    }()

    let imageView = UIImageView()

    var contentInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6) {
        didSet {
            updateInsets()
        }
    }

    private var viewModel: ImageViewModelProtocol?

    var shouldTintView: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear

        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(viewModel: ImageViewModelProtocol?, size: CGSize) {
        self.viewModel?.cancel(on: imageView)

        self.viewModel = viewModel

        imageView.image = nil
        viewModel?.loadImage(on: imageView, targetSize: size, animated: true)
    }

    func bind(viewModel: ImageViewModelProtocol?, settings: ImageViewModelSettings) {
        self.viewModel?.cancel(on: imageView)

        self.viewModel = viewModel

        imageView.image = nil

        let updatedSettings: ImageViewModelSettings

        if shouldTintView {
            imageView.tintColor = settings.tintColor

            updatedSettings = ImageViewModelSettings(
                targetSize: settings.targetSize,
                cornerRadius: settings.cornerRadius,
                tintColor: nil,
                renderingMode: .alwaysTemplate
            )
        } else {
            imageView.tintColor = nil
            updatedSettings = settings
        }

        viewModel?.loadImage(on: imageView, settings: updatedSettings, animated: true)
    }

    private func updateInsets() {
        imageView.snp.updateConstraints { make in
            make.top.equalToSuperview().inset(contentInsets.top)
            make.bottom.equalToSuperview().inset(contentInsets.bottom)
            make.leading.equalToSuperview().inset(contentInsets.left)
            make.trailing.equalToSuperview().inset(contentInsets.right)
        }
    }

    private func setupLayout() {
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(contentInsets.top)
            make.bottom.equalToSuperview().inset(contentInsets.bottom)
            make.leading.equalToSuperview().inset(contentInsets.left)
            make.trailing.equalToSuperview().inset(contentInsets.right)
        }
    }
}

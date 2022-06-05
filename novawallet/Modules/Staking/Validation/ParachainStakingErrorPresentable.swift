import Foundation

protocol ParachainStakingErrorPresentable: BaseErrorPresentable {
    func presentDelegatorExists(_ view: ControllerBackedProtocol, locale: Locale?)
    func presentDelegatorFull(_ view: ControllerBackedProtocol, maxAllowed: String, locale: Locale?)
    func presentCantStakeCollator(_ view: ControllerBackedProtocol, minStake: String, locale: Locale?)
    func presentStakeAmountTooLow(_ view: ControllerBackedProtocol, minStake: String, locale: Locale?)

    func presentUnstakingAmountTooHigh(_ view: ControllerBackedProtocol, locale: Locale?)

    func presentWontReceiveRewards(
        _ view: ControllerBackedProtocol,
        minStake: String,
        action: @escaping () -> Void,
        locale: Locale?
    )

    func presentWontReceiveRewardsAfterUnstaking(
        _ view: ControllerBackedProtocol,
        minStake: String,
        action: @escaping () -> Void,
        locale: Locale?
    )

    func presentUnstakeAll(
        _ view: ControllerBackedProtocol,
        minStake: String,
        action: @escaping () -> Void,
        locale: Locale?
    )

    func presentNoUnstakingOptions(_ view: ControllerBackedProtocol, locale: Locale?)
}

extension ParachainStakingErrorPresentable where Self: AlertPresentable & ErrorPresentable {
    func presentDelegatorExists(_ view: ControllerBackedProtocol, locale: Locale?) {
        let title = R.string.localizable.parachainStakingDelegatorExistsTitle(
            preferredLanguages: locale?.rLanguages
        )

        let message = R.string.localizable.parachainStakingDelegatorExistsMessage(
            preferredLanguages: locale?.rLanguages
        )

        let closeAction = R.string.localizable.commonClose(preferredLanguages: locale?.rLanguages)

        present(message: message, title: title, closeAction: closeAction, from: view)
    }

    func presentCantStakeCollator(_ view: ControllerBackedProtocol, minStake: String, locale: Locale?) {
        let title = R.string.localizable.amountTooLow(preferredLanguages: locale?.rLanguages)

        let message = R.string.localizable.parachainStakingCollatorGreaterMinstkMessage(
            minStake,
            preferredLanguages: locale?.rLanguages
        )

        let closeAction = R.string.localizable.commonClose(preferredLanguages: locale?.rLanguages)

        present(message: message, title: title, closeAction: closeAction, from: view)
    }

    func presentStakeAmountTooLow(_ view: ControllerBackedProtocol, minStake: String, locale: Locale?) {
        let title = R.string.localizable.amountTooLow(preferredLanguages: locale?.rLanguages)

        let message = R.string.localizable.parachainStakingCantStakeMessage(
            minStake,
            preferredLanguages: locale?.rLanguages
        )

        let closeAction = R.string.localizable.commonClose(preferredLanguages: locale?.rLanguages)

        present(message: message, title: title, closeAction: closeAction, from: view)
    }

    func presentWontReceiveRewards(
        _ view: ControllerBackedProtocol,
        minStake: String,
        action: @escaping () -> Void,
        locale: Locale?
    ) {
        let title = R.string.localizable.commonNoRewardsTitle(preferredLanguages: locale?.rLanguages)
        let message = R.string.localizable.parachainStakingCollatorGreaterMinstkMessage(
            minStake,
            preferredLanguages: locale?.rLanguages
        )

        presentWarning(
            for: title,
            message: message,
            action: action,
            view: view,
            locale: locale
        )
    }

    func presentDelegatorFull(_ view: ControllerBackedProtocol, maxAllowed: String, locale: Locale?) {
        let title = R.string.localizable.parachainStakingFullTitle(
            preferredLanguages: locale?.rLanguages
        )

        let message = R.string.localizable.parachainStakingFullMessage(
            maxAllowed,
            preferredLanguages: locale?.rLanguages
        )

        let closeAction = R.string.localizable.commonClose(preferredLanguages: locale?.rLanguages)

        present(message: message, title: title, closeAction: closeAction, from: view)
    }

    func presentUnstakingAmountTooHigh(_ view: ControllerBackedProtocol, locale: Locale?) {
        let title = R.string.localizable.parastkCantUnstakeTitle(preferredLanguages: locale?.rLanguages)
        let message = R.string.localizable.parastkCantUnstakeAmountMessage(preferredLanguages: locale?.rLanguages)

        let closeAction = R.string.localizable.commonClose(preferredLanguages: locale?.rLanguages)

        present(message: message, title: title, closeAction: closeAction, from: view)
    }

    func presentWontReceiveRewardsAfterUnstaking(
        _ view: ControllerBackedProtocol,
        minStake: String,
        action: @escaping () -> Void,
        locale: Locale?
    ) {
        let title = R.string.localizable.commonNoRewardsTitle(preferredLanguages: locale?.rLanguages)
        let message = R.string.localizable.parachainStakingCollatorLessMinstkMessage(
            minStake,
            preferredLanguages: locale?.rLanguages
        )

        presentWarning(
            for: title,
            message: message,
            action: action,
            view: view,
            locale: locale
        )
    }

    func presentUnstakeAll(
        _ view: ControllerBackedProtocol,
        minStake: String,
        action: @escaping () -> Void,
        locale: Locale?
    ) {
        let title = R.string.localizable.parastkUnstakeAllTitle(preferredLanguages: locale?.rLanguages)
        let message = R.string.localizable.parastkUnstakeAllMessageFormat(
            minStake,
            preferredLanguages: locale?.rLanguages
        )

        presentWarning(
            for: title,
            message: message,
            action: action,
            view: view,
            locale: locale
        )
    }

    func presentNoUnstakingOptions(_ view: ControllerBackedProtocol, locale: Locale?) {
        let languages = locale?.rLanguages

        let title = R.string.localizable.parastkUnstakeNoCollatorsTitle(
            preferredLanguages: languages
        )

        let message = R.string.localizable.parastkUnstakeNoCollatorsMessage(
            preferredLanguages: languages
        )

        let close = R.string.localizable.commonClose(preferredLanguages: languages)

        present(message: message, title: title, closeAction: close, from: view)
    }
}

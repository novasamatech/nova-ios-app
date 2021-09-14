import Foundation

enum AnalyticsPeriod: CaseIterable {
    case week
    case month
    case year
    case all
}

extension AnalyticsPeriod {
    static let `default` = AnalyticsPeriod.week

    func title(for locale: Locale) -> String {
        switch self {
        case .week:
            return R.string.localizable
                .stakingAnalyticsPeriod7d(preferredLanguages: locale.rLanguages).uppercased()
        case .month:
            return R.string.localizable
                .stakingAnalyticsPeriod30d(preferredLanguages: locale.rLanguages).uppercased()
        case .year:
            return R.string.localizable
                .stakingAnalyticsPeriod1y(preferredLanguages: locale.rLanguages).uppercased()
        case .all:
            return R.string.localizable
                .stakingAnalyticsPeriodAll(preferredLanguages: locale.rLanguages).uppercased()
        }
    }

    func chartBarsCount(startDate: Date, endDate: Date, calendar: Calendar) -> Int {
        switch self {
        case .week:
            return 7
        case .month:
            return 30
        case .year:
            return 12
        case .all:
            let components = calendar.dateComponents([.month], from: startDate, to: endDate)
            return (components.month ?? 0) + 1
        }
    }

    func xAxisValues(timestampInterval: (Int64, Int64), calendar: Calendar) -> [String] {
        let template: String = {
            switch self {
            case .week, .month:
                return "MMM dd"
            case .year, .all:
                return "MMM yyyy"
            }
        }()
        let format = DateFormatter.dateFormat(fromTemplate: template, options: 0, locale: nil)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format

        let firstDate = Date(timeIntervalSince1970: TimeInterval(timestampInterval.0))
        let lastDate = Date(timeIntervalSince1970: TimeInterval(timestampInterval.1))
        let middleDate = Date(timeIntervalSince1970: TimeInterval((timestampInterval.1 + timestampInterval.0) / 2))

        var result = (0 ..< chartBarsCount(startDate: firstDate, endDate: lastDate, calendar: calendar)).map { _ in "" }
        result[0] = dateFormatter.string(from: firstDate)
        let middleIndex = result.count % 2 == 0 ? result.count / 2 - 1 : result.count / 2
        result[middleIndex] = dateFormatter.string(from: middleDate)
        result[result.count - 1] = dateFormatter.string(from: lastDate)
        return result
    }
}

extension AnalyticsPeriod {
    func timestampInterval(startDate: Date, endDate: Date, calendar _: Calendar) -> (Int64, Int64) {
        guard self != .all else {
            return (Int64(startDate.timeIntervalSince1970), Int64(endDate.timeIntervalSince1970))
        }

        let startDate: Date = {
            let interval: TimeInterval = {
                switch self {
                case .week:
                    return .secondsInDay * 7
                case .month:
                    return .secondsInDay * 30
                case .year, .all:
                    return .secondsInDay * 365.2425
                }
            }()
            return Date().addingTimeInterval(TimeInterval(-interval))
        }()

        let startTimestamp = Int64(startDate.timeIntervalSince1970)
        let endTimestamp = Int64(Date().timeIntervalSince1970)
        return (startTimestamp, endTimestamp)
    }
}

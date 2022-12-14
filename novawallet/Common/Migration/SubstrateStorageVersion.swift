enum SubstrateStorageVersion: String, CaseIterable {
    case version1 = "SubstrateDataModel"
    case version2 = "SubstrateDataModel2"
    case version3 = "SubstrateDataModel3"
    case version4 = "SubstrateDataModel4"
    case version5 = "SubstrateDataModel5"
    case version6 = "SubstrateDataModel6"
    case version7 = "SubstrateDataModel7"
    case version8 = "SubstrateDataModel8"

    static var current: SubstrateStorageVersion {
        allCases.last!
    }

    var nextVersion: SubstrateStorageVersion? {
        switch self {
        case .version1:
            return .version2
        case .version2:
            return .version3
        case .version3:
            return .version4
        case .version4:
            return .version5
        case .version5:
            return .version6
        case .version6:
            return .version7
        case .version7:
            return .version8
        case .version8:
            return nil
        }
    }
}
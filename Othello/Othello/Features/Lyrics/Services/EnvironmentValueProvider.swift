import Foundation

enum EnvironmentValueProvider {
    static func value(forKey key: String, plistName: String = "ENV") -> String? {
        if let processValue = ProcessInfo.processInfo.environment[key], !processValue.isEmpty {
            return processValue
        }

        guard
            let url = Bundle.main.url(forResource: plistName, withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
            let dictionary = plist as? [String: Any],
            let value = dictionary[key] as? String,
            !value.isEmpty
        else {
            return nil
        }

        return value
    }
}

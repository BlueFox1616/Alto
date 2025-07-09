import os
import SwiftUI

// MARK: - Keys

/// contains all the string values used as keys for userDefaults
enum Keys: String {
    case colorScheme
    case searchEngine
    case downloadPath

    /// The default value the userDefault will take
    var defaultValue: String {
        switch self {
        case .colorScheme:
            "system"
        case .searchEngine:
            "brave"
        case .downloadPath:
            ""
        }
    }
}

// MARK: - Defaults

/// a wraper around userDefaults
enum Defaults {
    /// used to update a stored value in userDefaults
    /// - Parameters:
    ///   - value: the value to store
    ///   - key: the key of the userDefault where the value should be is stored
    static func updateValue(value: some UserDefaultsCompatible, key: Keys) {
        let storedValue = asStoredValue(value)
        UserDefaults.standard.set(storedValue, forKey: key.rawValue)
    }

    /// used to retreve the stored value froms userDefaults
    /// - Parameters:
    ///   - key: the key of the user defualt
    ///   - valueType: the type that the value should be converted into
    /// - Returns: the value as the requested value type or nil
    static func retreiveValue<T>(key: Keys, as valueType: T.Type) -> T? {
        let returnedValue = UserDefaults.standard.object(forKey: key.rawValue) ?? key.defaultValue

        guard let value = returnedValue as? T else {
            return nil
        }

        return value
    }

    /// it takes a value conforming to the UserDefaultsCompatible protocol and converts it to the compatable format if
    /// nessesary
    /// - Parameter value: a value conforming to UserDefaultsCompatible
    /// - Returns: a value that userDefaults can store
    static func asStoredValue(_ value: UserDefaultsCompatible) -> UserDefaultsCompatible {
        switch value {
        case is UUID: asType(value: value, as: UUID.self)!.uuidString
        case is ColorScheme: asType(value: value, as: ColorScheme.self)!.stringValue
        default: value
        }
    }

    /// converts a UserDefaultsCompatible value to the desired type
    /// - Parameters:
    ///   - value: a string
    ///   - valueType: the desired type
    /// - Returns: the value but converted to the correct type
    static func getStoredValue(_ value: String, as valueType: (some Any).Type) -> UserDefaultsCompatible {
        switch valueType {
        case is UUID.Type: asType(value: value, as: UUID.self)!
        default: value
        }
    }

    /// returns a value as the specified type or nil if it cannot by typecast
    /// - Parameters:
    ///   - value: Any Value
    ///   - valueType: The Type you want to cast to
    /// - Returns: returns the value as the specified type or nil if it is not posible
    static func asType<T>(value: some Any, as valueType: T.Type) -> T? {
        value as? T
    }
}

// MARK: - UserDefaultsCompatible

/// A protocol that applies to all Types that can be stored in user defaults using the custom Defauts class
protocol UserDefaultsCompatible {}

// MARK: - String + UserDefaultsCompatible

// These types can be stored as user defaults
extension String: UserDefaultsCompatible {}

// MARK: - Int + UserDefaultsCompatible

extension Int: UserDefaultsCompatible {}

// MARK: - Float + UserDefaultsCompatible

extension Float: UserDefaultsCompatible {}

// MARK: - Double + UserDefaultsCompatible

extension Double: UserDefaultsCompatible {}

// MARK: - Bool + UserDefaultsCompatible

extension Bool: UserDefaultsCompatible {}

// MARK: - URL + UserDefaultsCompatible

extension URL: UserDefaultsCompatible {}

// MARK: - Data + UserDefaultsCompatible

extension Data: UserDefaultsCompatible {}

// MARK: - Date + UserDefaultsCompatible

extension Date: UserDefaultsCompatible {}

// MARK: - NSNumber + UserDefaultsCompatible

extension NSNumber: UserDefaultsCompatible {}

// MARK: - Array + UserDefaultsCompatible

// Array of UserDefaultsCompatible
extension Array: UserDefaultsCompatible where Element: UserDefaultsCompatible {}

// MARK: - Dictionary + UserDefaultsCompatible

// Dictionary with String keys and UserDefaultsCompatible values
extension Dictionary: UserDefaultsCompatible where Key == String, Value: UserDefaultsCompatible {}

// MARK: - UUID + UserDefaultsCompatible

// These Types require custom implimentation to be supported

extension UUID: UserDefaultsCompatible {}

// MARK: - ColorScheme + UserDefaultsCompatible

extension ColorScheme: UserDefaultsCompatible {}

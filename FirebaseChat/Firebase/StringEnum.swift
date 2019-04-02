//
//  StringEnum.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 01/09/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation

protocol StringRawRepresentable {
    var stringRawValue: String { get }
    init?(rawValue: String)
}

protocol DefaultStringRawRepresentable : StringRawRepresentable {
    static var defaultValue : String { get }
    static var defaultEnum : Self { get }
}

extension DefaultStringRawRepresentable {
    static var defaultEnum : Self {
        return self.init(rawValue: defaultValue)!
    }
}

extension StringRawRepresentable
where Self: RawRepresentable, Self.RawValue == String {
    var stringRawValue: String { return rawValue }
}

func stringFromEnum<T: RawRepresentable>(_ value: T) -> String
    where T.RawValue == String {
        return value.rawValue
}

func enumFromString<T: RawRepresentable>(_ value: String) -> T?
    where T.RawValue == String {
        return T(rawValue: value)
}

func enumFromStringAndType<T: StringRawRepresentable>(_ value: String, type: T.Type) -> T? {
        return T(rawValue: value)
}

//
//  FirebaseModelSupport.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation

// MARK: - Helpers ------------------------------------------------------------

extension String {
    func isValidFirebaseKey() -> Bool {
        let charset = CharacterSet(charactersIn: ".#$[]")
        return self != "" && rangeOfCharacter(from: charset) == nil
    }
}

// ----- This is my microlayer of convenience methods -----


func isObject(any: Any, sameTypeAs object: Any) -> Bool {
    return typeDescription(any: any) == typeDescription(any: object)
}

func isFirebaseCompatibleValue(value: Any) -> Bool {
    return value is Int || value is String || value is String || value is NSNumber || value is NSDictionary || value is NSArray || value is NSString
}


func isAnArray(any: Any) -> Bool {
    let description = typeDescription(any: any)
    return description.prefix(5) == "Array"
}

func isADictionary(any: Any) -> Bool {
    let description = typeDescription(any: any)
    return description.prefix(10) == "Dictionary"
}

func typeDescription(any: Any) -> String {
    return "\(type(of: any))"
}

func swiftClassOfElementFromArray(any: Any) -> AnyClass? {
    if isAnArray(any: any) {
        let description = typeDescription(any: any)
        let elementDescription = (description as NSString).replacingOccurrences(of: "Array<", with: "").replacingOccurrences(of: ">", with: "")
        return swiftClassTypeFromString(className: elementDescription)
    }
    return nil
}

func instantiateSwiftClassOfElementFromArray(any: Any) -> NSObject? {
    if isAnArray(any: any) {
        let description = typeDescription(any: any)
        let elementDescription = (description as NSString).replacingOccurrences(of: "Array<", with: "").replacingOccurrences(of: ">", with: "")
        return swiftClassFromString(className: elementDescription)
    }
    return nil
}

func instantiateSwiftClassOfElementFromDictionary(any: Any) -> NSObject? {
    if isADictionary(any: any) {
        let description = typeDescription(any: any)
        let dictionaryDescription = (description as NSString).replacingOccurrences(of: "Dictionary<", with: "").replacingOccurrences(of: ">", with: "")
        if let elementDescription = dictionaryDescription.components(separatedBy: ", ").last {
            return swiftClassFromString(className: elementDescription)
        }
    }
    return nil
}


func instantiateSwiftClass(ofAny any: Any) -> Any? {
    // Basic non-objc Swift classes
    switch any {
    case is Bool:
        return Bool()
    case is Int:
        return Int()
    case is String:
        return String()
    case is Date:
        return Date()
    default:
        break
    }
    
    let typeDesc = typeDescription(any: any)
    if typeDesc.contains("Date") && !typeDesc.contains("Array") && !typeDesc.contains("Dictionary") {
        return Date()
    }
    
    return swiftClassFromString(className: "\(type(of: any))")
}


// ------ This is what I've got from Stack Overflow and rewritten to modern swift syntax and commented ------
// https://stackoverflow.com/questions/33491412/get-a-type-of-element-of-an-array-in-swift-through-reflection#33524703


/**
 Gets the swift class instance
 */
func swiftClassFromString(className: String) -> NSObject? {
    var result: NSObject? = nil
    switch className {
    case "NSObject":
        return NSObject()
    default:
        break
    }
    if let anyobjectype : AnyObject.Type = swiftClassTypeFromString(className: className) {
        if let nsobjectype : NSObject.Type = anyobjectype as? NSObject.Type {
            let nsobject: NSObject = nsobjectype.init()
            result = nsobject
        }
    }
    return result
}

/**
 Gets the swift class
 */
func swiftClassTypeFromString(className: String) -> AnyObject.Type? {
    var varClassName = className
    
    // Cut away the optional wrapping
    if className.hasPrefix("Optional<") {
        varClassName = (className as NSString).substring(from: "Optional<".count)
        varClassName = (varClassName as NSString).substring(to: varClassName.count - 1)
    }
    
    if varClassName.hasPrefix("_Tt") {
        return NSClassFromString(varClassName)!
    }
    
    switch varClassName {
    case "Date":
        return NSDate.self
    default:
        break
    }
    
    if let anyClass = NSClassFromString(varClassName) {
        return anyClass
    }
    
    var classStringName = varClassName
    if (varClassName as NSString).range(of: ".", options: NSString.CompareOptions.caseInsensitive).location > -1 {
        let appName = getCleanAppName()
        classStringName = "\(appName).\(varClassName)"
    }
    return NSClassFromString(classStringName)
}

/**
 Gets the App name without any prefixes and suffixes
 */
func getCleanAppName(forObject: NSObject? = nil)-> String {
    var bundle = Bundle.main
    if forObject != nil {
        bundle = Bundle(for: type(of: forObject) as! AnyClass)
    }
    
    var appName = bundle.infoDictionary?["CFBundleName"] as? String ?? ""
    if appName == "" {
        if bundle.bundleIdentifier == nil {
//            bundle = Bundle(for: AppDelegate.self)
        }
        appName = ((bundle.bundleIdentifier!) as NSString).components(separatedBy: ".").last ?? ""
    }
    let cleanAppName = (appName as NSString).replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "-", with: "_")
    return cleanAppName
}

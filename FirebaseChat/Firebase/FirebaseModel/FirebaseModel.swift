//
//  FirebaseModel.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase


// MARK: - FirebaseModel ------------------------------------------------------------------------

/**
 FirebaseModel acts as an active record, that means it has methods to update itself based on it's most recent version from firebase and override whatever is in the Firebase with it's current state.
 The overriding is performed by the save() method.
 So everytime you call save() on the FirebaseModel (or a subclass of FirebaseModel) the state of the FirebaseModel, all of it's properties will be saved to Firebase real time database.
 Except for "skippedProperties" which is a list of names of properties that should be excepted from the active record system.
 */
class FirebaseModel: NSObject, Identifiable {
    
    /**
     The property suffixes are modifiers for the parsing
     Nested - the complete object's data is stored in the property (even if part of an array). By default only a reference is stored in the property - the id of the object.
     Timetamp - in case of a Date we are using two formats - the standard Format.dateFormat or a Timestamp which is an inversed UNIX timestamp
              - maybe the timestamp should be plain timestamp and not inversed?
              - there is also a negative timestamp .... so maybe we should add more formats as needed
     */
    enum PropertySuffix : String {
        case Nested, Timestamp
    }
    
    // Object database
    private static var allInstances = [String : [String : FirebaseModel]]()
    static func existingInstance<T : FirebaseModel>(id: String, completion: @escaping (_ instance: T?)->Void) {
        DispatchQueue.global(qos: .default).async {
            let type = "\(self)"
            let instance = allInstances["\(type)"]?[id] as? T
            completion(instance)
        }
    }
    static func allExistingInstancesDictionary<T : FirebaseModel>(completion: @escaping (_ instances: [String : T])->Void) {
        DispatchQueue.global(qos: .default).async {
            let type = "\(T.self)"
            let instances = allInstances["\(type)"] as? [String : T]
            completion(instances ?? [String : T]())
        }
    }
    static func allExistingInstances<T : FirebaseModel>(completion: @escaping (_ instances: [T])->Void) {
        DispatchQueue.global(qos: .default).async {
            let type = "\(T.self)"
            let instances = allInstances["\(type)"]?.compactMap({ (tuple) -> T? in
                let (_, value) = tuple
                return value as? T
            })
            completion(instances ?? [T]())
        }
    }
    func existingInstance<T : FirebaseModel>(with: @escaping (_ instance: T?)->Void) {
        T.existingInstance(id: id, completion: { [weak self] instance in
            if let instance = instance {
                with(instance as? T)
            } else {
                self?.addToDatabase()
            }
        })
    }
    private func addToDatabase() {
        DispatchQueue.global(qos: .default).async {
            let type = typeDescription(any: self)
            if FirebaseModel.allInstances[type] == nil {
                FirebaseModel.allInstances[type] = [String : FirebaseModel]()
            }
            FirebaseModel.allInstances[type]![self.id] = self
        }
    }
    
    struct Format {
        static let dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    }
    
    // Properties
    var skipProperties : [String] {
        return ["id", "basePath", "reference"]
    }
    
    var id: String = NSUUID().uuidString
    var reference : DatabaseReference?
    var fetchedReference : DatabaseReference?
    var exists : Bool = true
    
    deinit {
        // Stop the attachment
    }
    
    // TODO: observation should be on a different object, because this object can be shared with many others and by re-observing we are throwing away the previous call
    func stopObserving(handle: DatabaseHandle) {
        reference?.removeObserver(withHandle: handle)
    }
    
    func stopObserving(property: String, handle: DatabaseHandle) {
        ref.child(property).removeObserver(withHandle: handle)
    }
    
    /**
     Firebase Reference
     */
    var ref : DatabaseReference {
        if let reference = reference {
            return reference
        }
        if type(of: self).basePath != "" {
            return type(of: self).baseRef.child(id)
        }
        if let fetchedReference = fetchedReference {
            return fetchedReference
        }
        
        return type(of: self).baseRef.childByAutoId()
    }
    
    /**
     Base Firebase Reference of the class
     */
    class var baseRef: DatabaseReference {
        get {
            return Firebase.database().reference(withPath: basePath)
        }
    }
    class var basePath: String { return "" }
    
    // ----------------------------------------------------
    // MARK: - Methods
    // ----------------------------------------------------
    
    required override init() {
        super.init()
        // Initialize the identifier
        let r = Firebase.database().reference().childByAutoId()
        // print("r: '\(r)'") /// DJ: TODO: Why is this called so often?
        id = r.key!
    }
    
    required init(id: String) {
        super.init()
        self.id = id
    }
    
    required init?(snapshot: DataSnapshot) {
        if let value = snapshot.value as? [String : AnyObject] {
            // Full JSON
            super.init()
            id = snapshot.key
            setAttributes(value)
            reference = snapshot.ref
            return
        } else
        if let value = snapshot.value as? String {
            // Reference
            super.init()
            id = value
//            reference = snapshot.ref
            return
        } else
        if let _ = snapshot.value as? Int {
            // Element of an array - key as a reference and value as the order Int within the array
            super.init()
            id = snapshot.key
//            reference = snapshot.ref
            return
        }
        return nil
    }
    
    static func == (lhs: FirebaseModel, rhs: FirebaseModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    func dictionary() -> [String : AnyObject] {
        var dict = attributesDictionary()
        dict["id"] = id as AnyObject
        dict["reference"] = reference?.description() as AnyObject
        return dict
    }
    
    
    func attributeFrom(value: Any, property: String? = nil) -> AnyObject {
        if let enumeration = value as? StringRawRepresentable {
            return enumeration.stringRawValue as AnyObject
        } else
        if let reference = value as? DatabaseReference {
            return reference.description() as AnyObject
        } else
        if let url = value as? URL {
            return url.absoluteString as AnyObject
        } else
        if let date = value as? Date {
            if let property = property, property.hasPropertySuffix(.Timestamp) {
                return date.inverseTimestamp as AnyObject
            } else {
                let df = DateFormatter()
                df.dateFormat = Format.dateFormat
                return df.string(from: date) as AnyObject
            }
        } else
        if let objArray = value as? [Identifiable] {
            if let property = property, property.hasPropertySuffix(.Nested) {
                var objectsDict: [String: [String: AnyObject]] = Dictionary<String, Dictionary<String, AnyObject>>()
                objArray.enumerated().forEach({ tuple in
                    let identifier = tuple.element.id
                    objectsDict[identifier] = tuple.element.attributesDictionary()
                })
                return objectsDict as AnyObject
            } else {
                var referencesDict: [String: Int] = [:]
                objArray.enumerated().forEach({ tuple in
                    let id = tuple.element.id
                    referencesDict[id] = tuple.offset
                })
                return referencesDict as AnyObject
            }
        } else if let object = value as? FirebaseModel {
            if let property = property, property.hasPropertySuffix(.Nested) {
                return object.dictionary() as AnyObject
            } else {
                return object.id as AnyObject
            }
        } else
        if let dictionary = value as? [String : Any] {
            // Any dictionary - we'll use a recursivity to help us parse nested structures
            var mappedDictionary = [String : AnyObject]()
            for key in dictionary.keys {
                mappedDictionary[key] = attributeFrom(value: dictionary[key]!, property: key)
            }
            return mappedDictionary as NSDictionary
        } else {
            return value as AnyObject
        }
    }
    
    
    // Store Data -----------------------------------------------------
    @objc func attributesDictionary() -> [String: AnyObject] {  // attributesDictionary() returns all attributes even nil String? as <null>
        var result = [String: AnyObject]()
        let mirror = Mirror(reflecting: self)
        for (property, value) in mirror.children {
            if let property = property, shouldSkip(property: property) == false { // if it is an 'attribute' to store
                result[property] = attributeFrom(value: value, property: property)
            }
        }
        return result
    }
    
    func notOverridingAttributesDictionary() -> [String : AnyObject] { /// DJ: TODO: What does this do? And any code that looks for only what changed to only save those, rather than need to re-save everything?
        var dict = attributesDictionary()
        for (_, element) in dict.enumerated() {
            if element.value is NSNull {
                dict.removeValue(forKey: element.key)
            }
        }
        return dict
    }
    
    /// DJ: Miro said that '.save()' makes a json out of the stuff.
    /// DJ: What does "save()" do, such as why called from AppDelegate when the app opens, and in 'Message.send()'?
    @objc func save() {   // save() won't persist nil String? shown as <null> in attributesDictionary()
        let newRef = ref
        id = newRef.key!
        newRef.updateChildValues(self.notOverridingAttributesDictionary())
        
        
        // Set id for nested references since we don't save those separately
        //        let mirror = Mirror(reflecting: self)
        //        for (property, value) in mirror.children {
        //            if let property = property, let objArray = value as? [FirebaseModel], String(property.suffix(6)) == "Nested" {
        //                objArray.forEach { $0.id = objArray.index(of: $0)!.description }
        //            }
        //        }
    }
    
    @objc func saveWithCompletion(completion: ((Error?)->())! = nil) {   // save() won't persist nil String? shown as <null> in attributesDictionary()
        let newRef = ref
        id = newRef.key!
        newRef.updateChildValues(self.notOverridingAttributesDictionary()) { (error, ref) in
            completion?(error)
        }
    }
    
    @objc func saveProperty(_ property: String) { 
        
        if shouldSkip(property: property) {
            return
        }
        
        if let value = value(forKeyPath: property) {
            let attribute = attributeFrom(value: value, property: property)
            ref.child(property).setValue(attribute)
        } else {
            ref.child(property).removeValue()
        }
        
    }
    
//    @objc func savePropertyMiroUpdatedVersion(_ property: String) { /// DJ: TODO: Use this because appears not needed to save to full path in order to work with security rules. This appears to work for saving a URL and other things, just as 'save()' does -- but this has the advantage of being useful for saving directly to a full path so that this works with security rules.
//        if shouldSkip(property: property) {
//            return
//        }
//
//        if let value = value(forKeyPath: property) {
//            ref.child(property).setValue(attributeFrom(value: value, property: property))
//        } else {
//            ref.child(property).removeValue()
//        }
//    }
    
    // ----------------------------------------------------
    // MARK: - Firebase Operations
    // ----------------------------------------------------
    
    func saveAndOverride() {
        ref.setValue(attributesDictionary)
    }
    
    func delete() {
        ref.removeValue()
    }
    
    func shouldSkip(property: String) -> Bool {
        if skipProperties.index(of: property) != nil {
            return true
        }
        // Storage properties skipping
        let storageSuffix = ".storage"
        if property.hasSuffix(storageSuffix) {
            if skipProperties.index(of: (property as NSString).substring(to: property.count - storageSuffix.count)) != nil {
                return true
            }
        }
        
        return false
    }
    
    @objc func clearAllProperties() {
        
        let mirror = Mirror(reflecting: self)
        for (property, currentValueOfProperty) in mirror.children {
            
            if let property = property, shouldSkip(property: property) == false {
                
                // Empty optional ... nil
                let typeName = typeDescription(any: currentValueOfProperty)
                if typeName.isOptionalProperty() {
                    self.setValue(nil, forKey: property)
                } else {
                    // Empty object
                    let newObject = instantiateSwiftClass(ofAny: currentValueOfProperty)
                    self.setValue(newObject, forKey: property)
                }
            }
        }// end property loop
    }
    
    @objc func clear(property: String) {
        
        if let currentValueOfProperty = value(forKey: property), shouldSkip(property: property) == false {
            
            // Empty optional ... nil
            let typeName = typeDescription(any: currentValueOfProperty)
            if typeName.isOptionalProperty() {
                self.setValue(nil, forKey: property)
            } else {
                // Empty object
                let newObject = instantiateSwiftClass(ofAny: currentValueOfProperty)
                self.setValue(newObject, forKey: property)
            }
        }
    }
    
    // Designed for a specialized purposes when we have the value as a property of some sort instead of just a order number in an array (especially in a situation when we are ordering by a key)
    @objc func setAttribute(_ attribute: Any) {
        
    }
    
    func setSwiftValue(_ value: Any?, forKey key: String) {
        
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        if self.responds(to: NSSelectorFromString(key)) {
            super.setValue(value, forKey: key)
        } else {
            setSwiftValue(value, forKey: key)
        }
    }
    
    func propertyValue(_ property: String, fromAttribute attributeValue: AnyObject?, currentValueOfProperty: Any) -> Any? {
        
        // Check if it's not an array
        if !(currentValueOfProperty is [AnyObject]) { // if it is an 'attribute' to decode (references stored in override)
            
            let instance = instantiateSwiftClass(ofAny: currentValueOfProperty) ?? currentValueOfProperty
            
            switch instance {
            case is StringRawRepresentable:
                if let rawValue = attributeValue as? String, let instance = instance as? StringRawRepresentable {
                    let enumerationValue = type(of: instance).init(rawValue: rawValue)
                    return enumerationValue
                }
            case is DatabaseReference:
                if let urlString = attributeValue as? String {
                    let reference = Firebase.database().reference(fromURL: urlString)
                    return reference
                }
            case is URL:
                if let urlString = attributeValue as? String {
                    if let url = URL(string: urlString) {
                        return url
                    }
                }
            case is Date:
                if let dateString = attributeValue as? String {
                    if property.hasPropertySuffix(.Timestamp) {
                        if let date = Date(currentInverseString: dateString) {
                            return date
                        }
                    } else {
                        let df = DateFormatter()
                        df.dateFormat = Format.dateFormat
                        return df.date(from: dateString)
                    }
                }
            case let value where value is FirebaseModel:
                let newObject = value as! FirebaseModel
                // Single references
                if let snapshotKey = attributeValue as? String {
                    
                    if (value as! FirebaseModel).id == snapshotKey {
                        // Nothing to override, the id is the same...
                        return value
                    } else {
                        newObject.id = snapshotKey
                        newObject.fetchedReference = ref.child(property)
                        return newObject
                    }
                    // Single nested objects
                } else if let newDictionary = attributeValue as? [String : AnyObject] {
                    newObject.fetchedReference = ref.child(property)
                    newObject.setAttributes(newDictionary)
                    return newObject
                }
            case is [String : Any]:
                
                let value = attributeValue as! [String : AnyObject]
                var mappedDictionary = [String : Any]()
                if let elementInstance = instantiateSwiftClassOfElementFromDictionary(any: currentValueOfProperty) {
                    for key in value.keys {
                        mappedDictionary[key] = propertyValue(key, fromAttribute: value[key], currentValueOfProperty: elementInstance)
                    }
                    return mappedDictionary
                } else {
                    return attributeValue
                }
                
            default:
                
                // Check if the value exists
                if let value = attributeValue, value is NSNull == false {
                    
                    // String values
                    let typeName = typeDescription(any: currentValueOfProperty)
                    switch typeName {
                    case "Optional<String>", "String":
                        return value.description
                    case "Optional<URL>", "URL":
                        return URL(string: value.description)
                    default:
                        return attributeValue
                    }
                }
            }
            
        } else {
            
            // An array of Custom classes
            if isAnArray(any: currentValueOfProperty) {
                
                // An Array of References
                if let referencesDict = attributeValue as? [String: Int] {
                    let referencestuplesArray = referencesDict.sorted { $0.value < $1.value }
                    var array : [FirebaseModel] = referencestuplesArray.compactMap {
                        let newObject = instantiateSwiftClassOfElementFromArray(any: currentValueOfProperty) as? FirebaseModel
                        let id = $0.0
                        newObject?.fetchedReference = ref.child(property).child(id)
                        newObject?.id = id
                        return newObject
                    }
                    
                    // Replace the occurences of the existing objects in the new set of items so that we don't override them with just models with references
                    for model in currentValueOfProperty as! [FirebaseModel] {
                        if let index = array.index(of: model) {
                            array.remove(at: index)
                            array.insert(model, at: index)
                        }
                    }
                    
                    return array
                }
                    // Nested objects
                else if let objectsArray = attributeValue as? [String : [String: AnyObject]] { // relies on undocumented firebase behavior
                    var array = [FirebaseModel]()
                    for (_, object) in objectsArray.enumerated() {
                        if let newObject = instantiateSwiftClassOfElementFromArray(any: currentValueOfProperty) as? FirebaseModel {
                            newObject.setAttributes(object.value)
                            newObject.fetchedReference = ref.child(property).child(object.key)
                            newObject.id = object.key
                            array.append(newObject)
                        }
                    }
                    array.sort { (a, b) -> Bool in
                        a.id.compare(b.id) == .orderedAscending
                    }
                    return array
                } else {
                    return attributeValue
                }
                
                // Single custom class
            } else if let newObject = instantiateSwiftClass(ofAny: currentValueOfProperty) as? FirebaseModel {
                // Single references
                if let snapshotKey = attributeValue as? String {
                    newObject.id = snapshotKey
                    newObject.fetchedReference = ref.child(property)
                    return newObject
                    // Single nested objects
                } else if let newDictionary = attributeValue as? [String : AnyObject] {
                    newObject.setAttributes(newDictionary)
                    newObject.fetchedReference = ref.child(property)
                    return newObject
                }
            }
        }
        
        return nil
    }
    
    // Reload Stored Data ------------------------------------------------
    // TODO: UIColor, Enums, UIImage, Protocols indicating ignoration, Object database, Sets (unique object arrays)
    @objc func setAttributes(_ dictionary: Dictionary<String, AnyObject>, clear: Bool = false) {
        
        if let identifier = dictionary["id"] as? String {
            id = identifier
        }
        if let reference = dictionary["reference"] as? String {
            self.reference = Firebase.database().reference(fromURL: reference)
        }
        
        let mirror = Mirror(reflecting: self)
        for (property, currentValueOfProperty) in mirror.children {
            
            if let property = property, shouldSkip(property: property) == false {
                
                if clear == false && dictionary[property] == nil {
                    continue
                }
                
                let value = propertyValue(property, fromAttribute: dictionary[property], currentValueOfProperty: currentValueOfProperty)
                self.setValue(value, forKey: property)
            }
        }
        
        // Update the object in the local database
        addToDatabase()
    }
    
    @objc func attachOnce(_ clear: Bool = false, with: @escaping () -> ()) {
        if id.isValidFirebaseKey() {
            ref.keepSynced(true)
            ref.observeSingleEvent(of: .value, with: { snap in
                
                if clear {
                    self.clearAllProperties()
                }
                if snap.exists() {
                    let foundAttributes = snap.value as? [String: AnyObject] ?? [:]
                    self.setAttributes(foundAttributes, clear:clear)
                    self.exists = true
                } else {
                    self.exists = false
                }
                with()
            })
        }
    }
    
    func observeAndKeepAttached(_ clear: Bool = false, with: @escaping () -> ()) -> FirebaseObservation? {
        
        if id.isValidFirebaseKey() {
            ref.keepSynced(true)
            let handle = ref.observe(.value, with: { snap in
                if clear {
                    self.clearAllProperties()
                }
                if snap.exists() {
                    let foundAttributes = snap.value as? [String: AnyObject] ?? [:]
                    self.setAttributes(foundAttributes, clear:clear)
                    self.exists = true
                } else {
                    self.exists = false
                }
                with()
            })
            
            return FirebaseObservation(handle: handle, query: ref)
        }
        
        return nil
    }
    
    
    // ----------------------------------------------------
    // MARK: - Properties
    // ----------------------------------------------------
    
    @objc func attachPropertyOnce(property: String, with: @escaping () -> ()) {
        if id.isValidFirebaseKey() {
            ref.child(property).keepSynced(true)
            ref.child(property).observeSingleEvent(of: .value, with: { snap in
                if snap.exists() {
                    let foundAttributes : AnyObject = (snap.value as? NSDictionary) ?? snap.value as AnyObject
                    let updatingAttributes = [property : foundAttributes] as [String: AnyObject]
                    self.setAttributes(updatingAttributes, clear:false)
                }
                with()
            })
        }
    }
    
    func observePropertyAndKeepAttached(property: String, with: @escaping () -> ()) -> FirebaseObservation? {
        
        if id.isValidFirebaseKey() {
            ref.child(property).keepSynced(true)
            let handle = ref.child(property).observe(.value, with: { snap in
                if snap.exists() {
                    let foundAttributes : AnyObject = (snap.value as? NSDictionary) ?? snap.value as AnyObject
                    let updatingAttributes = [property : foundAttributes] as [String: AnyObject]
                    self.setAttributes(updatingAttributes, clear:false)
                } else {
                    self.clear(property: property)
                }
                with()
            })
            
            return FirebaseObservation(handle: handle, query: ref)
        }
        
        return nil
    }
    
    
    
    // To make index(of:) work
    override func isEqual(_ object: Any?) -> Bool {
        guard let obj = object as? FirebaseModel else {
            return false
        }
        return self.id == obj.id
    }
    
    
    @objc func ifExists(perform: @escaping () -> () = {}, elsePerform: @escaping () -> () = {}) {
        ref.observeSingleEvent(of: .value, with: { snap in
            self.exists = snap.exists()
            if snap.exists() { perform() } else { elsePerform() }
        })
    }
    
    @objc class func ifExists(id: String, perform: @escaping () -> () = {}, elsePerform: @escaping () -> () = {}) {
        let ref = Firebase.database().reference(withPath: basePath).child(id)
        ref.observeSingleEvent(of: .value, with: { snap in
            if snap.exists() { perform() } else { elsePerform() }
        })
    }
    
    override var description: String {
        return ("\(type(of: self)) with id: \(id) from path: \( type(of: self).basePath )\n\(attributesDictionary())" as NSString).replacingOccurrences(of: ", ", with: ",\n ")
    }
    
    override func copy() -> Any {
        let dict = dictionary()
        let newObject = type(of: self).init()
        newObject.setAttributes(dict, clear: true)
        return newObject
    }
}

extension String {
    
    func hasPropertySuffix(_ suffix: FirebaseModel.PropertySuffix) -> Bool {
        return hasSuffix(suffix.rawValue)
    }
    
    func isOptionalProperty() -> Bool {
        return hasPrefix("Optional<")
    }
    
}

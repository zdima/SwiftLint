//
//  Rule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public typealias RuleIdentifier = String

extension RuleIdentifier {
    static let validCharacterSet: NSCharacterSet = {
        let lowercaseSet = NSCharacterSet.lowercaseLetterCharacterSet()
        let mutableSet = lowercaseSet.mutableCopy() as? NSMutableCharacterSet
        mutableSet?.addCharactersInString("_")
        return (mutableSet?.copy() as? NSCharacterSet)!
    }()
}

public protocol Rule {
    var identifier: RuleIdentifier { get }
    func validateFile(file: File) -> [StyleViolation]
}

public protocol ParameterizedRule: Rule {
    typealias ParameterType
    var parameters: [RuleParameter<ParameterType>] { get }
}

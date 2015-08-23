//
//  ForceCastRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct ForceCastRule: Rule {
    public init() {}

    public let identifier = "force_cast"

    public func validateFile(file: File) -> [StyleViolation] {
        return file.matchPattern("as!", withSyntaxKinds: [.Keyword]).filter { range in
                let patternRange = NSMakeRange(range.location,1)
                let lineRage = (file.contents as NSString).lineRangeForRange(patternRange)
                let line: NSString = (file.contents as NSString).substringWithRange(lineRage)
                return line.rangeOfString("// $-\(self.identifier)").location == NSNotFound
            }.map { range in
                return StyleViolation(type: .ForceCast,
                    location: Location(file: file, offset: range.location),
                    severity: .High,
                    reason: "Force casts should be avoided")
            }
    }

    public let example = RuleExample(
        ruleName: "Force Cast Rule",
        ruleDescription: "This rule checks whether you don't do force casts.",
        nonTriggeringExamples: [
            "NSNumber() as? Int\n",
            "// NSNumber() as! Int\n",
        ],
        triggeringExamples: [ "NSNumber() as! Int\n" ]
    )
}

//
//  Linter.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SwiftXPC
import SourceKittenFramework

private var ruleDictionary: [String:Bool] = [:]

public struct Linter {
    private let file: File
    /**
     * List of all rules. Update this list when new rule is added.
     */
    private let defaultRules: [Rule] = [
        LineLengthRule(),
        LeadingWhitespaceRule(),
        TrailingWhitespaceRule(),
        ReturnArrowWhitespaceRule(),
        TrailingNewlineRule(),
        ForceCastRule(),
        FileLengthRule(),
        TodoRule(),
        ColonRule(),
        TypeNameRule(),
        VariableNameRule(),
        TypeBodyLengthRule(),
        FunctionBodyLengthRule(),
        NestingRule(),
        ControlStatementRule()
    ]

    private var rules: [Rule]!

    // Load configuration and update rules settings.
    private func loadRules() {
        // by default enable all rules
        for rule in defaultRules {
            ruleDictionary.updateValue(true, forKey: rule.identifier)
        }
        loadGlobalRules()
        loadProjectRules()
    }
    func loadGlobalRules() {
        let fileManager: NSFileManager = NSFileManager.defaultManager()
        let urls: [AnyObject] = fileManager.URLsForDirectory(
            .LibraryDirectory, inDomains: .UserDomainMask)
        if urls.count > 0 {
            if let libraryURL = urls[urls.count-1] as? NSURL {
                let SwiftLintFolder: NSURL = libraryURL.URLByAppendingPathComponent(
                    "SwiftLint", isDirectory: true)
                let configurationFile = SwiftLintFolder.URLByAppendingPathComponent(
                    "config.json", isDirectory: false)
                if !fileManager.fileExistsAtPath(SwiftLintFolder.path!) {
                    fileManager.createDirectoryAtURL(SwiftLintFolder,
                        withIntermediateDirectories: true, attributes: nil, error: nil)
                    return
                }
                var config: NSMutableDictionary = NSMutableDictionary()
                if fileManager.fileExistsAtPath(configurationFile.path!) {
                    // Load file
                    if let configObject = load( configurationFile ) {
                        config = configObject
                        // Update default value with configuration
                        if let configRules = config["rules"] as? [String:Bool] {
                            for (aKey,aValue) in configRules {
                                ruleDictionary[aKey] = aValue
                            }
                        }
                    }
                }
                config.setObject(ruleDictionary, forKey: "rules")
                save(config, toFileURL: configurationFile)
            }
        }
    }
    func loadProjectRules() {
        let fileManager: NSFileManager = NSFileManager.defaultManager()
        let homeURL = NSURL(fileURLWithPath: NSHomeDirectory())

        var fileFolder = NSURL(fileURLWithPath: self.file.path!.lastPathComponent)
        var config: NSMutableDictionary = NSMutableDictionary()
        while fileFolder != nil && fileFolder != homeURL {
            fileFolder = fileFolder!.URLByDeletingLastPathComponent!.absoluteURL
            if fileFolder != nil {
                let configurationFile = fileFolder!.URLByAppendingPathComponent(
                    "lint.config", isDirectory: false)
                println("check for \(configurationFile)")
                if fileManager.fileExistsAtPath(configurationFile.path!) {
                    // Load file
                    println("loadin \(configurationFile)")
                    if let configObject = load( configurationFile ) {
                        config = configObject
                        // Update default value with configuration
                        if let configRules = config["rules"] as? [String:Bool] {
                            for (aKey,aValue) in configRules {
                                ruleDictionary[aKey] = aValue
                            }
                        }
                    }
                    config.setObject(ruleDictionary, forKey: "rules")
                    save(config, toFileURL: configurationFile)
                    break
                }
            } else {
                break;
            }
        }
    }

    // Load configuration
    private func load( fromFile: NSURL) -> NSMutableDictionary? {
        var error: NSError?
        if let data = NSData(contentsOfURL: fromFile,
            options: NSDataReadingOptions.allZeros, error: &error) {
                if let configObject = NSJSONSerialization.JSONObjectWithData(data,
                    options: NSJSONReadingOptions.MutableContainers,
                    error: &error) as? NSMutableDictionary {
                    return configObject
                }
        }
        return nil
    }

    // Save configuration
    private func save( configuration: NSDictionary, toFileURL: NSURL) {
        var error: NSError?
        if let data: NSData? = NSJSONSerialization.dataWithJSONObject( configuration,
            options: NSJSONWritingOptions.PrettyPrinted, error: &error) {
                data!.writeToURL( toFileURL, atomically:true )
        }
    }

    private func getRules() -> [Rule] {

        // initialize ruleDictionary once
        if ruleDictionary.count == 0 {
            loadRules()
        }

        // build array of enabled rules
        var resultArray: [Rule] = []
        for rule in defaultRules {
            if ruleDictionary[rule.identifier] == true {
                resultArray.append(rule)
            }
        }

        return resultArray
    }

    public var styleViolations: [StyleViolation] {
        return rules.flatMap { $0.validateFile(self.file) }
    }

    public var ruleExamples: [RuleExample] {
        return compact(rules.map { $0.example })
    }

    /**
    Initialize a Linter by passing in a File.

    :param: file File to lint.
    */
    public init(file: File) {
        self.file = file
        self.rules = getRules()
    }
}

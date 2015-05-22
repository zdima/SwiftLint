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

public struct Configuration {
    public var enabledRuleIDs: Set<RuleIdentifier>
    public var disabledRuleIDs: Set<RuleIdentifier>
    public static let defaultConfiguration = Configuration()

    public init(enabledRuleIDs: Set<RuleIdentifier> = Set(),
        disabledRuleIDs: Set<RuleIdentifier> = Set()) {
        self.enabledRuleIDs = enabledRuleIDs
        self.disabledRuleIDs = disabledRuleIDs
    }

    public mutating func enable(ruleID: RuleIdentifier) {
        enabledRuleIDs.insert(ruleID)
        disabledRuleIDs.remove(ruleID)
    }

    public mutating func disable(ruleID: RuleIdentifier) {
        enabledRuleIDs.remove(ruleID)
        disabledRuleIDs.insert(ruleID)
    }

    public func filterRules(rules: [Rule]) -> [Rule] {
        return rules.filter {
            !self.disabledRuleIDs.contains($0.identifier)
        }
    }
}

extension Configuration: Printable {
    public var description: String {
        return "enabled: " +
            join(", ", enabledRuleIDs) +
            "\ndisabled: " +
            join(", ", disabledRuleIDs)
    }
}

extension File {
    public var commands: Array<(Int, ConfigurationCommand)> {
        return compact(matchPattern("// swiftlint:(.*)",
            withSyntaxKinds: [.Comment]).map { match in
            if match.numberOfRanges != 2 {
                return nil
            }
            let matchString = (self.contents as NSString).substringWithRange(match.rangeAtIndex(1))
            return map(ConfigurationCommand.fromString(matchString)) {
                return (match.range.location, $0)
            }
        })
    }

    public var configurations: Array<(Int, Configuration)> {
        var configurations = [(0, Configuration())] // Always start with the default configuration
        for command in commands {
            if let previousConfiguration = configurations.last {
                configurations.append((command.0, command.1.apply(previousConfiguration.1)))
            }
        }
        return configurations
    }
}

public enum ConfigurationCommand {
    case EmptyCommand
    case EnableRule(ruleID: RuleIdentifier)
    case DisableRule(ruleID: RuleIdentifier)

    public static func fromString(string: String) -> ConfigurationCommand? {
        let scanner = NSScanner(string: string)
        if scanner.scanString("enable_rule:", intoString: nil) {
            var ruleName: NSString? = nil
            scanner.scanCharactersFromSet(RuleIdentifier.validCharacterSet,
                intoString: &ruleName)
            if let ruleName = ruleName as? String {
                return .EnableRule(ruleID: ruleName)
            }
        } else if scanner.scanString("disable_rule:", intoString: nil) {
            var ruleName: NSString? = nil
            scanner.scanCharactersFromSet(RuleIdentifier.validCharacterSet,
                intoString: &ruleName)
            if let ruleName = ruleName as? String {
                return .DisableRule(ruleID: ruleName)
            }
        }
        return nil
    }

    public func apply(var configuration: Configuration) -> Configuration {
        switch self {
            case .EmptyCommand:
                break // no-op
            case .EnableRule(let ruleID):
                configuration.enable(ruleID)
            case .DisableRule(let ruleID):
                configuration.disable(ruleID)
        }
        return configuration
    }
}

extension ConfigurationCommand: Printable {
    public var description: String {
        switch self {
        case .EmptyCommand:
            return "Empty Command"
        case .EnableRule(let ruleID):
            return "Enable Rule: \(ruleID)"
        case .DisableRule(let ruleID):
            return "Disable Rule: \(ruleID)"
        }
    }
}

// swiftlint:disable_rule:line_length
// swiftlint:enable_rule:line_length

public struct Linter {
    private let file: File
    private let availableRules: [Rule] = [
        LineLengthRule(),
        LeadingWhitespaceRule(),
        TrailingWhitespaceRule(),
        TrailingNewlineRule(),
        ForceCastRule(),
        FileLengthRule(),
        TodoRule(),
        ColonRule(),
        TypeNameRule(),
        VariableNameRule(),
        TypeBodyLengthRule(),
        FunctionBodyLengthRule(),
        NestingRule()
    ]

    public var styleViolations: [StyleViolation] {
        for region in file.configurations {
            println("validating \(file.path) with configuration: \(region)")
        }
        return flatMap(availableRules) {
            $0.validateFile(self.file)
        }
    }

    /**
    Initialize a Linter by passing in a File.

    :param: file File to lint.
    */
    public init(file: File) {
        self.file = file
    }
}

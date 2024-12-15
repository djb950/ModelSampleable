import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

enum ModelSampleableDiagnostic: String, DiagnosticMessage {
    case notAStruct
    
    var severity: DiagnosticSeverity { return .error }
    
    var message: String {
        switch self {
        case .notAStruct:
            return "'@ModelSampleable' can only be applied to a 'struct'"
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "ModelSampleableMacros", id: rawValue)
    }
}


public struct ModelSampleableMacro: MemberMacro {
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            let structError = Diagnostic(
                node: node,
                message: ModelSampleableDiagnostic.notAStruct
            )
            context.diagnose(structError)
            return []
        }
        
        guard let argumentDecl = node.arguments?.as(LabeledExprListSyntax.self) else {
            return []
        }
        let defaultValues = argumentDecl.first!.expression.as(DictionaryExprSyntax.self)!.content.as(DictionaryElementListSyntax.self)!
        var defaultStringValues = [String: String]()
        for item in defaultValues {
            guard let key = item.key.as(MemberAccessExprSyntax.self)?.base?.as(DeclReferenceExprSyntax.self)?.baseName.identifier?.name else { continue }
            guard let value = switch key {
            case "String":
                item.value.as(StringLiteralExprSyntax.self)?.segments.first?.as(StringSegmentSyntax.self)?.content.description
            case "Int":
                item.value.as(IntegerLiteralExprSyntax.self)?.literal.description
            default:
                nil

            }  else { continue }
            defaultStringValues[key] = value
        }
        
        let structName = structDecl.name.text
        var sampleValues: [String] = []
        
        for member in structDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  let binding = varDecl.bindings.first,
                  binding.initializer == nil,
                  let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else {
                continue
            }

            let propertyName = identifier.identifier.text

            let sampleValue = determineSampleValue(for: binding.typeAnnotation?.type.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", propertyName: propertyName, defaultValues: defaultStringValues)

            sampleValues.append("\(propertyName): \(sampleValue)")
        }
        
        let sampleDataDecl = """
        static var sampleData: \(structName) {
            \(structName)(\(sampleValues.joined(separator: ", ")))
        }
        """

        let sampleDataSyntax = DeclSyntax(stringLiteral: sampleDataDecl)

        return [sampleDataSyntax]
    }
    
    private static func determineSampleValue(for typeName: String, propertyName: String, defaultValues: [String: String] = [:]) -> String {
        switch typeName {
        case "String":
            if let defaultStringValue = defaultValues["String"] {
                return "\"\(defaultStringValue)\""
            }
            return "\"Sample \(propertyName)\""
        case let type where type.hasSuffix("?") || type.hasPrefix("Optional<"): // TODO: allow custom parameter to macro to determine if optionals should default to nil or the underlying type instead
            return "nil"
        case "Int":
            if let defaultIntValue = defaultValues["Int"] {
                return "\(defaultIntValue)"
            }
            return "123"
        case "Double":
            return "123.45"
        case "Bool":
            return "true"
        case let type where type.hasPrefix("[") && type.hasSuffix("]") && type.contains(":"): // dictionary literal
            let types = type.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "]", with: "").split(separator: ":")
            if types.count == 2 {
                let keySample = determineSampleValue(for: String(types[0]), propertyName: "key")
                let valueSample = determineSampleValue(for: String(types[1]), propertyName: "value")
                return "[\(keySample): \(valueSample)]"
            } else if types.count == 1 {
                let sample = determineSampleValue(for: String(types[0]), propertyName: propertyName)
                return "[\(sample): \(sample)]"
            }
            return "[:]"
        case let type where type.hasPrefix("Dictionary<") && type.hasSuffix(">"): // Dictionary type
            print("type: \(type)")
        let types = String(type.dropFirst(11).dropLast()).split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if types.count == 2 {
                print("types: \(types)")
                let keySample = determineSampleValue(for: String(types[0]), propertyName: "key")
                let valueSample = determineSampleValue(for: String(types[1]), propertyName: "value")
                return "[\(keySample): \(valueSample)]"
            }
            return "[:]"
        case let type where type.hasPrefix("[") && type.hasSuffix("]"): // Array type
            let elementType = String(type.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
                let elementSample = determineSampleValue(for: elementType, propertyName: propertyName)
                return "[\(elementSample)]"
        case let type where type.hasPrefix("Set<") && type.hasSuffix(">"): // Set type
            let elementType = String(type.dropFirst(4).dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
                let elementSample = determineSampleValue(for: elementType, propertyName: "set value")
                return "Set([\(elementSample)])"
            default:
                // Assume it's another struct with @SampleData
                return "\(typeName).sampleData"
        }
    }
}

@main
struct ModelSampleablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ModelSampleableMacro.self
    ]
}

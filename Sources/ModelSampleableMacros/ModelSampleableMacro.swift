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
        
        let structName = structDecl.name.text
        var sampleValues: [String] = []
        
        for member in structDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  let binding = varDecl.bindings.first,
                  let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else {
                continue
            }

            let propertyName = identifier.identifier.text

            let sampleValue = determineSampleValue(for: binding.typeAnnotation?.type.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", propertyName: propertyName)

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
    
    private static func determineSampleValue(for typeName: String, propertyName: String) -> String {
        switch typeName {
        case "String":
            return "\"Sample \(propertyName)\""
        case let type where type.hasSuffix("?") || type.hasPrefix("Optional<"):
            return "nil"
        case "Int":
            return "123"
        case "Double":
            return "123.45"
        case "Bool":
            return "true"
        case let type where type.hasPrefix("[") && type.hasSuffix("]"): // Array type
            let elementType = String(type.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
                let elementSample = determineSampleValue(for: elementType, propertyName: propertyName)
                return "[\(elementSample)]"
        case let type where type.hasPrefix("Set<") && type.hasSuffix(">"): // Set type
            let elementType = String(type.dropFirst(4).dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
                let elementSample = determineSampleValue(for: elementType, propertyName: propertyName)
                return "Set([\((elementSample))])"
            case let type where type.hasPrefix("Dictionary<") && type.hasSuffix(">"): // Dictionary type
            let types = String(type.dropFirst(10).dropLast()).split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                if types.count == 2 {
                    let keySample = determineSampleValue(for: String(types[0]), propertyName: propertyName)
                    let valueSample = determineSampleValue(for: String(types[1]), propertyName: propertyName)
                    return "[\(keySample): \(valueSample)]"
                }
                return "[:]"
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

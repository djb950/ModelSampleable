import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum ModelSampleableError: Error {
    case onlyApplicableToStructs
    
    var description: String {
        switch self {
        case .onlyApplicableToStructs:
            return "@ModelSampleable can only be applied to a struct"
        }
    }
}


public struct ModelSampleableMacro: MemberMacro {
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw ModelSampleableError.onlyApplicableToStructs
        }
        
        let structName = structDecl.name.text
        
        let members = structDecl.memberBlock.members
        let propertyDecls = members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
        let bindings = propertyDecls.flatMap { $0.bindings }
        
        // get types
        let typeAnnotations = bindings.compactMap { $0.typeAnnotation }
        let types = typeAnnotations.compactMap { $0.type.as(IdentifierTypeSyntax.self) }
        let typeIdentifiers = types.compactMap { $0.name }
        
        // get identifiers
        let patterns = bindings.compactMap { $0.pattern.as(IdentifierPatternSyntax.self) }
        let identifiers = patterns.compactMap { $0.identifier }
        
        var params = ""
        
        for index in 0..<identifiers.count {
            
            let type = typeIdentifiers[index].text
            let paramName = identifiers[index].text
            switch type {
                case "String":
                params += "\(paramName): \"test\""
            case "Int":
                params += "\(paramName): 0"
            default:
                break
            }
            if index != identifiers.count - 1 {
                params += ", "
            }
        }
        
        let staticData = try VariableDeclSyntax("static var sampleData: \(raw: structName)") {
            """
            
            \(raw: structName)(
                \(raw: params)
            )
            
            """
        }
        return [DeclSyntax(staticData)]
    }
}

@main
struct ModelSampleablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ModelSampleableMacro.self
    ]
}

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest


import ModelSampleableMacros

let testMacros: [String: Macro.Type] = [
    "ModelSampleable": ModelSampleableMacro.self,
]
//#endif

final class ModelSampleableTests: XCTestCase {
    
    func testModelSampleableMacro() {
        assertMacroExpansion("""

        @ModelSampleable
        struct Model {
            let stringProperty: String
            let intProperty: Int
        }
        """, expandedSource: """
        
        struct Model {
            let stringProperty: String
            let intProperty: Int
        
            static var sampleData: Model {
                Model(
                    stringProperty: "test", intProperty: 0
                )
            }
        }
        
        """, macros: testMacros
        )
    }
    
    func testModelSampleableMacroWithArrayType() {
        assertMacroExpansion("""
        
        @ModelSampleable
        struct Model {
            let stringProperty: String
            let intProperty: Int
            let arrayProperty: [String]
        }
        
        """, expandedSource: """

        struct Model {
            let stringProperty: String
            let intProperty: Int
            let arrayProperty: [String]
        
            static var sampleData: Model {
                Model(stringProperty: "Sample stringProperty", intProperty: 123, arrayProperty: ["Sample arrayProperty"])
            }
        }

        """, macros: testMacros)
    }
    
    func testModelSampleableMacroWithObjectType() {
        assertMacroExpansion("""
        
        @ModelSampleable
        struct Model {
            let stringProperty: String
            let intProperty: Int
            let arrayProperty: [String]
            let objectType: Object
        }
        
        """, expandedSource: """

        struct Model {
            let stringProperty: String
            let intProperty: Int
            let arrayProperty: [String]
            let objectType: Object
        
            static var sampleData: Model {
                Model(stringProperty: "Sample stringProperty", intProperty: 123, arrayProperty: ["Sample arrayProperty"], objectType: Object.sampleData)
            }
        }

        """, macros: testMacros)
    }
}

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


}

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
                Model(stringProperty: "Sample stringProperty", intProperty: 123)
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
    
    func testModelSampleableMacroWithDictionaryShorthand() {
        assertMacroExpansion("""
        
        @ModelSampleable
        struct Model {
            let stringProperty: String
            let intProperty: Int
            let arrayProperty: [String]
            let dictionaryShorthand: [String: Int]
        }
        
        """, expandedSource: """

        struct Model {
            let stringProperty: String
            let intProperty: Int
            let arrayProperty: [String]
            let dictionaryShorthand: [String: Int]
        
            static var sampleData: Model {
                Model(stringProperty: "Sample stringProperty", intProperty: 123, arrayProperty: ["Sample arrayProperty"], dictionaryShorthand: ["Sample key": 123])
            }
        }

        """, macros: testMacros)
    }
    
    func testModelSampleableMacroWithDictionary() {
        assertMacroExpansion("""
        
        @ModelSampleable
        struct Model {
            let stringProperty: String
            let intProperty: Int
            let arrayProperty: [String]
            let dictionary: Dictionary<String, Int>
        }
        
        """, expandedSource: """

        struct Model {
            let stringProperty: String
            let intProperty: Int
            let arrayProperty: [String]
            let dictionary: Dictionary<String, Int>
        
            static var sampleData: Model {
                Model(stringProperty: "Sample stringProperty", intProperty: 123, arrayProperty: ["Sample arrayProperty"], dictionary: ["Sample key": 123])
            }
        }

        """, macros: testMacros)
    }
    
    func testModelSampleableMacroWithSet() {
        assertMacroExpansion("""
        
        @ModelSampleable
        struct Model {
            let stringProperty: String
            let intProperty: Int
            let arrayProperty: [String]
            let set: Set<String>
        }
        
        """, expandedSource: """

        struct Model {
            let stringProperty: String
            let intProperty: Int
            let arrayProperty: [String]
            let set: Set<String>
        
            static var sampleData: Model {
                Model(stringProperty: "Sample stringProperty", intProperty: 123, arrayProperty: ["Sample arrayProperty"], set: Set(["Sample set value"]))
            }
        }

        """, macros: testMacros)
    }
    
    func testModelSampleableMacroStoredProperty() {
        assertMacroExpansion("""

        @ModelSampleable
        struct Model {
            let stringProperty: String
            let intProperty: Int
        
            let storedProperty = "stored"
        }
        """, expandedSource: """
        
        struct Model {
            let stringProperty: String
            let intProperty: Int
        
            let storedProperty = "stored"
        
            static var sampleData: Model {
                Model(stringProperty: "Sample stringProperty", intProperty: 123)
            }
        }
        
        """, macros: testMacros
        )
    }
}

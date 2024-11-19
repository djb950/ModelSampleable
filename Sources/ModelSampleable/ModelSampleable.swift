// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(member, names: named(sampleData))
public macro ModelSampleable(defaultTypes: [ObjectIdentifier: Any] = [:]) = #externalMacro(module: "ModelSampleableMacros", type: "ModelSampleableMacro")

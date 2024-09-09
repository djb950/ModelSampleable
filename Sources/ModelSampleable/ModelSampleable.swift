// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(member, names: named(sampleData))
public macro ModelSampleable() = #externalMacro(module: "ModelSampleableMacros", type: "ModelSampleableMacro")

// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

private let rootPath = FileManager.default.urls(
    for: .applicationSupportDirectory, in: .userDomainMask
)[0].appending(component: Bundle.main.bundleIdentifier!)

let prefixDir = rootPath.appending(path: "Prefix")
let wineDir = rootPath.appending(path: "Wine")

public enum WineKit {}

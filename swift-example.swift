#!/usr/bin/swift

// File: example_script.swift
// reminder: chmod to executable before invoking the script

import Foundation

func printHelp() {
    print("Please add an argument to the command line. Thanks.")
}

// --- main ---
if CommandLine.argc < 2 {
    printHelp()
} else {
    for i: Int in 1 ..< Int(CommandLine.argc) {
        print( CommandLine.arguments[i] )
    }
}

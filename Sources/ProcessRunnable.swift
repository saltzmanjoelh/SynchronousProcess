//
//  ProcessRunnable.swift
//  SynchronousProcess
//
//  Created by Joel Saltzman on 12/18/16.
//
//

import Foundation

public protocol ProcessRunnable {
    static func run(_ launchPath: String, arguments: [String]?, silenceOutput: Bool) -> ProcessResult 
}

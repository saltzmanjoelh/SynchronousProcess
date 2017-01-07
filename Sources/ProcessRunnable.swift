//
//  ProcessRunnable.swift
//  SynchronousProcess
//
//  Created by Joel Saltzman on 12/18/16.
//
//

import Foundation

public protocol ProcessRunnable {
    @discardableResult
    static func run(_ launchPath: String, arguments: [String]?, printOutput: Bool, outputPrefix: String?) -> ProcessResult
    
    @discardableResult
    func run(_ printOutput: Bool, outputPrefix: String?) -> ProcessResult
}

//
//  TaskExtensions.swift
//  DockerTask
//
//  Created by Joel Saltzman on 7/27/16.
//
//

import Foundation
#if os(Linux)
    extension Task {
        var isRunning : Bool {
            get {
                return self.running
            }
        }
    }
#endif



extension Task {
    
    @discardableResult
    public class func run(launchPath:String, arguments:[String]?, silenceOutput:Bool = false) -> (output:String?, error:String?, exitCode:Int32) {
        let task = Task()
        task.launchPath = launchPath
        if let launchArguments = arguments {
            task.arguments = launchArguments
        }
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        let errorPipe = Pipe()
        task.standardError = errorPipe
        
        task.launch()
        
        var output = String()
        var error = String()
        
        let read = { (pipe:Pipe, toEndOfFile:Bool) -> String? in
            let fileHandle = pipe.fileHandleForReading
            //TODO: add timeout?
            let data = toEndOfFile ? fileHandle.readDataToEndOfFile() : fileHandle.availableData
            guard let outputString = String(data:data, encoding:String.Encoding.utf8)  else {
                return nil
            }
            if outputString.characters.count == 0 {
                return nil
            }
            if !silenceOutput {
                for string in outputString.components(separatedBy: "\n") {
                    print(string)
                }
            }
            return outputString
        }
        while(task.isRunning){
            if let errorString = read(errorPipe, false) {
                error += errorString
            }
            if let outputString = read(outputPipe, false) {
                output += outputString
            }
        }
        if let errorString = read(errorPipe, true) {
            error += errorString
        }
        if let outputString = read(outputPipe, true) {
            output += outputString
        }
        
        
        let outputResult : String? = output != "" ? output : nil
        let errorResult : String? = error != "" ? error : nil
        
        return (outputResult, errorResult, task.terminationStatus)
    }
}

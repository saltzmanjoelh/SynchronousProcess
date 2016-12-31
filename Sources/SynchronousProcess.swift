//
//  SynchronousProcesss.swift
//  DockerProcess
//
//  Created by Joel Saltzman on 7/27/16.
//
//
//TODO: add async fileHandle reading that makes the run loop run until it's done. maybe use a separate struct for it?

import Foundation

#if os(Linux)
    public typealias Process = Task
    
    
    
    extension Task {
        var isRunning : Bool {
            get {
                return self.running
            }
        }
    }
    
    
    extension NotificationCenter {
        open func addObserver(forName name: NSNotification.Name?, object obj: Any?, queue: OperationQueue?, using block: @escaping (Notification) -> Swift.Void) -> NSObjectProtocol{
            return addObserver(forName: name, object: obj, queue: queue, usingBlock: block)
        }
    }
    extension FileHandle {
        public static let readCompletionNotification = Notification.Name.init(rawValue: "NSFileHandleReadCompletionNotification")
    }
    
#endif

public typealias ProcessResult = (output:String?, error:String?, exitCode:Int32)



extension Process: ProcessRunnable {
    
    @discardableResult
    public static func run(_ launchPath: String, arguments: [String]?, printOutput: Bool = true, outputPrefix: String? = nil) -> ProcessResult {
        let process = Process()
        process.launchPath = launchPath
        if let launchArguments = arguments {
            process.arguments = launchArguments
        }
        return process.run(printOutput, outputPrefix: outputPrefix)
    }
    @discardableResult
    public func run(_ printOutput: Bool = true, outputPrefix: String? = nil) -> ProcessResult {
        
        
        let outputPipe = Pipe()
        self.standardOutput = outputPipe
        
        let errorPipe = Pipe()
        self.standardError = errorPipe
        
        
        var output = String()
        var error = String()
        let prefix = outputPrefix != nil ? "\(outputPrefix!): " : ""
        
        let dataTransformer : (Data) -> (String?) = {
            data in
            if data.count == 0 {
                self.terminate()
                return nil
            }
            if let string = String(data:data, encoding:String.Encoding.utf8) {
                if(printOutput){
                    print("\(prefix)\(string.trimmingCharacters(in: CharacterSet.whitespaces))")
                }
                return string
            }
            return nil
        }
        
        let readHandler : (Notification) -> (Void) = {
            notification in
            if let data = notification.userInfo?[NSFileHandleNotificationDataItem] as? Data, let fileHandle = notification.object as? FileHandle {
                guard let readString = dataTransformer(data) else {
                    return
                }
                if fileHandle == outputPipe.fileHandleForReading {
                    output += "\(prefix)\(readString)"
                }else {
                    error += "\(prefix)\(readString)"
                }
            }
        }
        _ = NotificationCenter.default.addObserver(forName: FileHandle.readCompletionNotification, object: outputPipe.fileHandleForReading, queue: OperationQueue.main, using: readHandler)
        _ = NotificationCenter.default.addObserver(forName: FileHandle.readCompletionNotification, object: errorPipe.fileHandleForReading, queue: OperationQueue.main, using: readHandler)
        
        self.launch()
        
        while(self.isRunning){
            outputPipe.fileHandleForReading.readInBackgroundAndNotify()
            errorPipe.fileHandleForReading.readInBackgroundAndNotify()
            let runLoop = RunLoop.current
            runLoop.run(until: Date(timeIntervalSinceNow: TimeInterval(0.2)))
        }
        //cleanup
        if let outputString = dataTransformer(outputPipe.fileHandleForReading.readDataToEndOfFile()) {
            output += outputString
        }
        if let errorString = dataTransformer(errorPipe.fileHandleForReading.readDataToEndOfFile()) {
            error += errorString
        }
        
        
        NotificationCenter.default.removeObserver(self)
        
        let outputResult : String? = output != "" ? output : nil
        let errorResult : String? = error != "" ? error : nil
        
        return (outputResult, errorResult, self.terminationStatus)
    }
}

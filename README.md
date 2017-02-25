#SynchronousProcess

[![Build Status][image-1]][1] [![Swift Version][image-2]][2]

Synchronously run a Process (formerly NSTask) and have it return the output, error and exit code as a tuple `(output:String?, error:String?, exitCode:Int32)`


Example: 

```Swift
let result = Process.run("/bin/bash", arguments: ["-c", "echo test && echo test2; echo test3"], silenceOutput: false)
if let error = result.error {
	print("Error: \(error)")
}else{
	print("Output: \(result.output)")
}
```

[1]:	https://travis-ci.org/saltzmanjoelh/SynchronousProcess
[2]:	https://swift.org "Swift"

[image-1]:	https://travis-ci.org/saltzmanjoelh/SynchronousProcess
[image-2]:	https://img.shields.io/badge/swift-version%203-blue.svg
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
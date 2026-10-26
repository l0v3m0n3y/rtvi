# rtvi
api for rtvi.com RTVI - главные новости США и мира на русском языке · Боевые действия в Украине · Топливный рынок · Атаки беспилотников · Война в Иране. 
# main
```swift
import Foundation
import rtvi

let rtviCli = RTVIClient()

let home = try await rtviCli.getHome()

print(home)
```

# Launch (your script)
```
swift run
```

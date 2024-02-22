# Hubspot Mobile SDK for iOS

## Installation

Add the SDK to your project using Swift Package Manager using this repo url.

TODO: explain further with specific example or screenshot of correct url?

## Configuration

Once the Hubspot Mobile SDK is added to SPM, include your `Hubspot-Info.plist` config file in your project, and marked as included in the app target.

During app startup, or some other convenient place to initialise app components, call the configure method on the sdk.

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // Override point for customization after application launch.
    
    // This will configure the SDK using the `Hubspot-Info.plist` file that is bundled in app
    try! HubspotManager.configure()
    
    return true
}
```

Once configured, the chat view can be created and shown to users like any other SwiftUI view. For example, in response to a button press:

```
Button(action: {
     showChat.toggle()
 }, label: {
     Text("\(Chat Now")
 }).sheet(isPresented: $showChat, content: {
     HubspotChatView()
 })
```

## Documentation

Reference documentation can be found here: https://tapadoo.github.io/hubspot-mobile-sdk-ios/documentation/hubspotmobilesdk

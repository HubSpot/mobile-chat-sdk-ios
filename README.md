# Hubspot Mobile SDK for iOS

## Overview

HubSpot's iOS Mobile Chat SDK is designed to seamlessly integrate HubSpot Chat into any iOS mobile application (see [here](https://github.hubspot.com/mobile-chat-sdk-android/) for the Android documentation). With this SDK, developers can effortlessly provide their users with a fast, efficient, and empathetic in-app customer support experience.

### Key Features

* Integrate HubSpot Chat into your mobile app to deliver real-time, in-app customer support.
* Leverage HubSpot's powerful Bots and Knowledge Base to deflect customer inquiries 24/7.
* Alert users of new messages via push notifications.
* Customize the chat experience to align with your brand and user interface.

## Installation

Add the SDK to your project using Swift Package Manager using this repo url. From the project settings, select the Package Dependencies tab, beside Info and Build Settings tab. Search with this url to find and add the package.

NOTE: During alpha and beta testing, while this repository is private you may need to configure xcode with your Github Account. Add in account from the Xcode Preferences panel, in the account section. If building using a cli tool like xcodebuild, you may need to specify either `-scmProvider system` or `-scmProvider xcode` to choose if your system git credentials or xcode credentials are used.

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
     Text("Chat Now")
 }).sheet(isPresented: $showChat, content: {
     HubspotChatView(chatFlow: "support")
 })
```


## Documentation

For more information, please refer to the following links:
* https://github.hubspot.com/mobile-chat-sdk-ios/documentation/hubspotmobilesdk/
* https://developers.hubspot.com/docs/api-reference/mobile-chat-sdk/ios
* https://knowledge.hubspot.com/chatflows/integrate-a-hubspot-chatflow-with-a-mobile-app
* https://knowledge.hubspot.com/chatflows/create-and-customize-a-mobile-chatflow


## Deploying this SDK

For publishing a new version of this SDK:

* Agree on a new version number, based on the changes
* Update the CHANGELOG.md file with new version and summary of important changes
* Commit, merge any branches (if needed) to main branch and tag the commit with the new version , i.e 1.0.0
* push the main branch & tags to github.

See also: https://developer.apple.com/documentation/xcode/publishing-a-swift-package-with-xcode

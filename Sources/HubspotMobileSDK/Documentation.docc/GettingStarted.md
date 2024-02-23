# Getting Started

The basic steps to get the SDK installed and opening chat views.

## Overview

The SDK is a swift package containing hubspot chat view , notification functionality, and additional optional UI components.

### Alpha / Beta Only - Ensure access to repository

Confirm the SDK repository is accessible at [https://github.com/HubSpot/mobile-chat-sdk-ios](https://github.com/HubSpot/mobile-chat-sdk-ios)

During alpha and beta testing, while the repository is private you may need to configure xcode with your Github Account. Add in account from the Xcode Preferences panel, in the account section. If building using a cli tool like xcodebuild, you may need to specify either `-scmProvider system` or `-scmProvider xcode` to choose if your system git credentials or xcode credentials are used.

### Installing & Configuring the SDK

Use swift packages to add the SDK to your workspace, using the github repository URL. Add the `HubspotMobileSDK` library as a dependency of your app project and target.

![Adding Package](confirm-spm)


Be sure to download and include the `Hubspot-Info.plist` file from your hubspot account at [hubspot.com](https://www.hubspot.com). Important - make sure to include the file as part of the target within Xcode , in the right inspection panel:
![Demo screenshot](hsIncludeFile) ![Demo screenshot](hsIncludedTarget)

The SDK needs to be configured once per app launch, before use. The most convenient place to do this is during the app initialiser or the app delegate callback, like so:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // Override point for customization after application launch.
    
    // This will configure the SDK using the `Hubspot-Info.plist` file that is bundled in app
    try! HubspotManager.configure()
    
    return true
}
```

#### Initialisation Errors

Failure to include the config file, or forgetting to include the file as being part of your apps target will cause initialisation to throw an error:

![Demo screenshot](hsInitError) 
![Demo screenshot](hsMissingTarget)



### Declare additional permissions in your Xcode Project

#### NSCameraUsageDescription

The chat view contains an option to attach an existing image, or to take a new image. For this functionality work, **your app should have an entry in the Info plist** for `NSCameraUsageDescription`. 

### Opening Hubspot Chat View

The chat view can be presented modally as a sheet , or fullscreen, or pushed into a navigation stack. The easiest way to get started is to present the chat view as a sheet in response to a button press in your UI.

The Chat view can be initialised using ``HubspotChatView/init(manager:pushData:chatFlow:)`` , either with default values or by customising the chat settings 

#### Showing the chat as a sheet in SwiftUI

The chat view is a SwiftUI View, meaning it can be the contents of a sheet, or embedded in your existing UI like any other view. The easiest way is to present it as a sheet using the `.sheet` modifier , in response to user action like pressing a button.

```swift
Button(action: {
    showChat.toggle()
}, label: {
    Text("Chat Now")

}).sheet(isPresented: $showChat, content: {
    HubspotChatView()
})
```

Here, `$showChat` is a state property in the view:

```swift
@State var showChat = false
```

#### Showing the chat as a presented view controller in UIKit

While the Hubspot Chat View is a SwiftUI view, it functions fine when contained in a `UIHostingController`. For example, to present the chat view from a UIViewController button action:

```swift
@IBAction
func onButtonPress(_ source: Any) {

    //Init chat view with no arguments , or use alternative initialiser for configuring chat specifics
    let chatView = HubspotChatView()
    //Create a hosting controller to hold the chat view
    let hostingVC = UIHostingController(rootView: chatView)
    
    // Present the view controller like any other (or push into a navigation stack)
    self.present(hostingVC, animated: true)
}
}

```

### Identifying Users with the Hubspot Visitor Identification Token

To optionally identify users, you must first obtain a visitor token using  the visitor identification api, detailed at [https://developers.hubspot.com/docs/api/conversation/visitor-identification](https://developers.hubspot.com/docs/api/conversation/visitor-identification)

This API is best implemented in your own server project, and the identity token passed to your app by whatever method works for your specific setup - perhaps in response to your own user login or session management, or as a result of a dedicated api.

Once a token is generated it can be set using the ``HubspotManager/setUserIdentity(identityToken:email:)`` method. This should be called before opening a chat view.

### Adding Custom Chat Data Properties

The SDK supports including key value pairs of data when opening a chat session. You can add your own values to these, as well as declare some common permission dates if you wish, if that is something that would be useful for agents during a chat session.

See ``HubspotManager/setChatProperties(data:)`` for the method to use. This is best called before starting a chat, and applies to all new chats.
You could set an account status, or some other identifiers when setting up your user, and these will appear in all chats opened for the remainder of the app launch.

 An example of setting a mix of pre-defined properties, and custom properties
```swift
 var properties: [String: String] = [
     ChatPropertyKey.cameraPermissions.rawValue: self.checkCameraPermissions(),
     "myapp-install-id": appUniqueId,
     "subscription-tier": "premium"
 ]
 HubspotManager.shared.setChatProperties(data: properties)
```

### Clearing Data On Logout

The SDK stores in memory identification tokens, email address, and any properties set. The push token for the app is also associated with the current user , if applicable.

There are situations where you know you might want to clear this data, such as during a logout or changing user in a multi user app.

To clear this data, call ``HubspotManager/clearUserData()`` at an appropiate time in in your app. Note this only impacts the data used for future chat sessions - it has no impact on data or chat sessions already stored in hubspot. 

## Push Messaging

See <doc:PushNotifications> for instructions for configuring for push messages

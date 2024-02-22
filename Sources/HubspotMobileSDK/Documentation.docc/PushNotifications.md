# Push Notifications

This article covers the 2 methods of integrating the SDK and Chat with push notifications.

## Overview

There are two ways to handle hubspot push notifications in your app, first is for the app to be the main notification handler - in this setup, the app itself determines what to do with each notification, and controls the when and how notification permissions are prompted for. This is the choice for any app that already uses push for its own purposes. The second way is to allow the Hubspot SDK to handle the notifications itself, and trigger a callback whenever a chat needs to be displayed. This may be convenient for apps that have not yet configured push notifications.

### App Delegate Changes

Whichever approach is taken, the SDK will need to be informed when the app has a push notification. In your app delegate, call the sdk method ``HubspotManager/setPushToken(apnsPushToken:)`` from within the push registration delegate method.

```swift
func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    //Forward device token to hubspot SDK
    HubspotManager.shared.setPushToken(apnsPushToken: deviceToken)
    //Note, you may have other content here already for other
}
```

#### Firebase Messaging Users

You may not have a delegate method but be using push messages already. If that is the case, you may need to disable method swizzling. See [https://firebase.google.com/docs/cloud-messaging/ios/receive#handle_messages_with_method_swizzling_disabled](https://firebase.google.com/docs/cloud-messaging/ios/receive#handle_messages_with_method_swizzling_disabled)

### App Handling Notifications

#### Check for hubspot Notifications in your notification handler

In your `UNUserNotificationCenterDelegate` , you can check a notification that the user has opened to see if its a hubspot notification. This is done by looking for specific content in the notification body. There's helper methods that will help with this check, ``HubspotManager/isHubspotNotification(notification:)`` or ``HubspotManager/isHubspotNotification(notificationData:)``

You can also use ``PushNotificationChatData/init(notification:)`` to create a struct containing relevant Hubspot data from the notification.

Your method might look something like this:

```swift

func application(_: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    
    if HubspotManager.shared.isHubspotNotification(notificationData: userInfo), let chatData = PushNotificationChatData(notificationData:userInfo) {
        // This is a hubspot push message. Ideally we want to show a new HubspotChatView - the exact method to do so will depend on your own UI layout
        myViewModel.presentChatView(chatData)
        completionHandler(.newData)
    }
    else {
        // This push is for an existing / other app feature and unrelated to hubspot sdk
        myViewModel.handleAppPush(...)
        completionHandler(.newData)
    }
}
```

If a notification is a hubspot sdk push, the ideal handling is to present the chat view, if not already showing one. This will depend on your own app structure, see <doc:GettingStarted> for examples of how to present chat view UI.

#### Registering for Pushes

When handling pushes yourself, its assumed you are already calling `UIApplication.shared.registerForRemoteNotifications()` at some point in your app lifecycle. If not, call it at a suitable point during startup, such as app delegates did finish launching method, or when first entering the foreground

#### Handling Permissions

In this mode, its assumed yoour app will prompt the user for permissions to show notifications at a suitable point already.

### Hubspot SDK Handling Notifications

In this mode, the hubspot sdk will help with push messages by acting as the messaging delegate and calling a callback when UI needs to be shown. It can optionally handle presenting the user with permissions prompt also.

#### Configure the Hubspot Manager for push during app start up

The hubspot manager instance should be configured on launch for push, using the method ``HubspotManager/configurePushMessaging(promptForNotificationPermissions:allowProvisionalNotifications:newMessageCallback:)`` , for example in your app delegate, combined with the other configuration steps might look like this:

```swift
func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.

    // This will configure the SDK using the `Hubspot-Info.plist` file that is bundled in app
    try! HubspotManager.configure()
    
    // We want sdk to handle our push notifications
    HubspotManager.shared.configurePushMessaging(promptForNotificationPermissions: true,
                                                 allowProvisionalNotifications: true, 
                                                 newMessageCallback: onChatPushSelected)

    return true
}

func onChatPushSelected(data: PushNotificationChatData) {
    // This sends notification to the main UI to display the chat view
    onChatPushReceived.send(data)
}

func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    //Forward device token to hubspot SDK
    HubspotManager.shared.setPushToken(apnsPushToken: deviceToken)
    // Note, you may have other content here already for other
}
```

#### Handling user opening a notification

When a user taps on a notification, you will want to be notified so you can present ``HubspotChatView`` in a method that makes sense for your current layout. The SDK will not assume it can alter your UI.

The above example shows using a callback that is triggered on user selecting a notification. This can also be set directly on the Mananager after initial setup: ``HubspotManager/newMessageCallback``

One downside to this callback is only one callback can be active at a time - as an alternative there's a passthrough publisher that is triggered also ``HubspotManager/newMessage``, as well as the ability to generate an async stream - ``HubspotManager/newMessages()``. Either of these can be used in multiple places.

However be aware if using both the callback and the publisher/async sequence , or all three at once , selecting a new message will result in all 3 triggering.

In all cases these new message triggers will include a ``PushNotificationChatData`` instance - this is an optional parameter to the chat view, to allow it to open the correct chat for the notification. It can be passed to the chat view during initalisation like so:

```swift
myContentView.task {
    // If notification is tapped/opened by the user , set shate properties to open the chat view using sheet
    
    for await chatData in HubspotManager.shared.newMessages()  {
        if !showChatFromPushNotification {
            showChatFromPushNotification = true
            selectedChatData = chatData
        }
    }
}
.sheet(isPresented: $showChatFromPushNotification, content: {
    HubspotChatView(pushData: selectedChatData)
})
```

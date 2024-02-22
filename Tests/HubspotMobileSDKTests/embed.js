function configureHubspotConversations() {
    if (window.HubSpotConversations) {
        window.webkit.messageHandlers.nativeApp.postMessage({ "info": "Setting up handlers" });
        window.HubSpotConversations.on('conversationStarted', payload => {
            window.webkit.messageHandlers.nativeApp.postMessage(payload);
        });

        window.HubSpotConversations.on('widgetLoaded', payload => {
            window.webkit.messageHandlers.nativeApp.postMessage(payload);
        });

        window.HubSpotConversations.on('userInteractedWithWidget', payload => {
            window.webkit.messageHandlers.nativeApp.postMessage(payload);
        });

        window.HubSpotConversations.on('userSelectedThread', payload => {
            window.webkit.messageHandlers.nativeApp.postMessage(payload);
        });

        window.webkit.messageHandlers.nativeApp.postMessage({ "info": "Finished setting up handlers" });
    } else {
        window.webkit.messageHandlers.nativeApp.postMessage({ "info": "no object to set handlers on still" });
    }
}

window.webkit.messageHandlers.nativeApp.postMessage({ "info": "starting main load script" });

if (window.HubSpotConversations) {
    configureHubspotConversations();
} else {
    window.hsConversationsOnReady = [configureHubspotConversations];
}

window.webkit.messageHandlers.nativeApp.postMessage({ "info": "finished main load script" });
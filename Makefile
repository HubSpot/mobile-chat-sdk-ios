
# Base path used with Xcode Command
DEMO_BUILD_DIR=build/demo
# Xcode creates .xcarchive with the given path
DEMO_ARCHIVE_DIR=${DEMO_BUILD_DIR}.xcarchive

LEGACY_DEMO_BUILD_DIR=build/legacy-demo
LEGACY_DEMO_ARCHIVE_DIR=${LEGACY_DEMO_BUILD_DIR}.xcarchive

DOCS_BUILD_DIR=build/docs
DOCS_DIR=docs

# default value for when testing locally
GITHUB_RUN_NUMBER ?= "1"

FRAMEWORKS_OUTPUT=build/frameworks
FRAMEWORK_NAME=HubspotMobileSDK

clean:
	rm -rf betabuild.tmp
	rm -rf ${DOCS_DIR}
	rm -rf ${DOCS_BUILD_DIR}
	rm -rf ${DEMO_BUILD_DIR}
	rm -rf ${LEGACY_DEMO_BUILD_DIR}
	rm -rf ${DEMO_ARCHIVE_DIR}
	rm -rf ${LEGACY_DEMO_ARCHIVE_DIR}
	rm -rf ${FRAMEWORKS_OUTPUT}

lint:
	swiftformat --lint --swiftversion 5.9 Sources
	swiftformat --lint --swiftversion 5.9 Demo
	swiftformat --lint --swiftversion 5.9 UIKitDemo

format:
	swiftformat --swiftversion 5.9 Sources
	swiftformat --swiftversion 5.9 Demo
	swiftformat --swiftversion 5.9 UIKitDemo

make-doc-archive:
	xcodebuild \
	-workspace HubspotSDK.xcworkspace \
	-scheme HubspotMobileSDK \
	-destination generic/platform=iOS \
	docbuild \
	-derivedDataPath $(DOCS_BUILD_DIR)/

make-static-docs: make-doc-archive
	xcrun docc process-archive transform-for-static-hosting \
	$(DOCS_BUILD_DIR)/Build/Products/Debug-iphoneos/HubspotMobileSDK.doccarchive/ \
	--hosting-base-path '/' \
	--output-path $(DOCS_DIR)

set-demo-version:
	cd Demo && xcrun agvtool new-version $(GITHUB_RUN_NUMBER)
	cd UIKitDemo/HubspotLegacyUIDemo && xcrun agvtool new-version $(GITHUB_RUN_NUMBER)

build-demo: set-demo-version

#	Depending on process context, this may or may not be needed
#	security unlock-keychain -p $(KEYCHAIN_PASSWORD) ~/Library/Keychains/login.keychain

	xcodebuild \
	-allowProvisioningUpdates \
	-authenticationKeyPath $(AUTH_KEY_PATH) \
    -authenticationKeyID $(AUTH_KEY_ID) \
    -authenticationKeyIssuerID $(AUTH_KEY_ISSUERID) \
	-workspace HubspotSDK.xcworkspace \
	-scheme HubspotDemo \
	-destination generic/platform=iOS \
	-archivePath ${DEMO_BUILD_DIR} \
	clean archive

build-legacy-demo: set-demo-version

#	Depending on process context, this may or may not be needed
#	security unlock-keychain -p $(KEYCHAIN_PASSWORD) ~/Library/Keychains/login.keychain

	xcodebuild \
	-allowProvisioningUpdates \
	-authenticationKeyPath $(AUTH_KEY_PATH) \
	-authenticationKeyID $(AUTH_KEY_ID) \
	-authenticationKeyIssuerID $(AUTH_KEY_ISSUERID) \
	-workspace HubspotSDK.xcworkspace \
	-scheme HubspotLegacyUIDemo \
	-destination generic/platform=iOS \
	-archivePath ${LEGACY_DEMO_BUILD_DIR} \
	clean archive

upload-demo:
	xcodebuild -allowProvisioningUpdates \
	-authenticationKeyPath $(AUTH_KEY_PATH) \
	-authenticationKeyID $(AUTH_KEY_ID) \
	-authenticationKeyIssuerID $(AUTH_KEY_ISSUERID) \
	-exportArchive -archivePath ${DEMO_ARCHIVE_DIR} \
	-exportOptionsPlist demo-uploadoptions.plist

custom-selfhosted-deploy:
	@echo "Building .ipa and using our custom tools for internal deployment and hosting"
	ios-beta-gen --app ${DEMO_ARCHIVE_DIR}
	@echo "Would deploy as version number $(BUILD_NUMBER) / $(GITHUB_RUN_NUMBER)"
	tapadoo-beta -p ios upload HubspotDemo betabuild.tmp/HubspotDemo-$(GITHUB_RUN_NUMBER).ipa betabuild.tmp/HubspotDemo-$(GITHUB_RUN_NUMBER)-metadata.json
	tapadoo-beta promote -i HubspotDemo $(GITHUB_RUN_NUMBER)
	@echo "Believe that its been uploaded and is available now"

custom-legacy-selfhosted-deploy:
	@echo "Building .ipa and using our custom tools for internal deployment and hosting"
	ios-beta-gen --app ${LEGACY_DEMO_ARCHIVE_DIR}
	@echo "Would deploy as version number $(BUILD_NUMBER) / $(GITHUB_RUN_NUMBER)"
	tapadoo-beta -p ios upload HubspotLegacyDemo betabuild.tmp/HubspotLegacyUIDemo-$(GITHUB_RUN_NUMBER).ipa betabuild.tmp/HubspotLegacyUIDemo-$(GITHUB_RUN_NUMBER)-metadata.json
	tapadoo-beta promote -i HubspotLegacyDemo $(GITHUB_RUN_NUMBER)
	@echo "Believe that its been uploaded and is available now"

#
# Note: Untested. Keeping this incase I need it, but it will only build frameworks if the library type is set to dynamic in the Package.swift
# 
create-binary-framework:
	@echo "Creating a binary xcframework in $(FRAMEWORKS_OUTPUT) - typically we want to add this as a SPM source dependency rather than a binary framework, but  the ability to generate one may still be useful"
	
	xcodebuild archive \
    -workspace HubspotSDK.xcworkspace \
    -scheme HubspotMobileSDK \
    -destination "generic/platform=iOS" \
    -archivePath "$(FRAMEWORKS_OUTPUT)/$(FRAMEWORK_NAME)" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

	xcodebuild archive \
    -workspace HubspotSDK.xcworkspace \
    -scheme HubspotMobileSDK \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "$(FRAMEWORKS_OUTPUT)/$(FRAMEWORK_NAME)-iOS_Simulator" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

	xcodebuild -create-xcframework \
    -archive "$(FRAMEWORKS_OUTPUT)/$(FRAMEWORK_NAME).xcarchive" -framework $(FRAMEWORK_NAME).framework \
    -archive "$(FRAMEWORKS_OUTPUT)/$(FRAMEWORK_NAME)-iOS_Simulator.xcarchive" -framework $(FRAMEWORK_NAME).framework \
    -output "$(FRAMEWORKS_OUTPUT)/$(FRAMEWORK_NAME).xcframework"

	@echo "Created XCFramework (and platform specific frameworks) in $(FRAMEWORKS_OUTPUT)"


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

FRAMEWORKS_OUTPUT=./build/frameworks
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
	swift format lint --recursive --strict Sources
	swift format lint --recursive --strict Tests
	swift format lint --recursive --strict Demo
	swift format lint --recursive --strict UIKitDemo

format:
	swift format --in-place --recursive Sources
	swift format --in-place --recursive Tests
	swift format --in-place --recursive Demo
	swift format --in-place --recursive UIKitDemo

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
	--hosting-base-path '/mobile-chat-sdk-ios' \
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
	
#
# Note: Untested. Keeping this incase I need it, but it will only build frameworks if the library type is set to dynamic in the Package.swift
# 
create-binary-framework:
	@echo "Creating a binary xcframework in $(FRAMEWORKS_OUTPUT) - typically we want to add this as a SPM source dependency rather than a binary framework, but  the ability to generate one may still be useful"
	@echo "Note: update Package.swift to use dynamic type first"
	
	xcodebuild archive \
    -workspace HubspotSDK.xcworkspace \
    -scheme HubspotMobileSDK \
    -destination "generic/platform=iOS" \
    -archivePath "$(FRAMEWORKS_OUTPUT)/ios/$(FRAMEWORK_NAME).xcarchive" \
	SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

	xcodebuild archive \
    -workspace HubspotSDK.xcworkspace \
    -scheme HubspotMobileSDK \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "$(FRAMEWORKS_OUTPUT)/ios-simulator/$(FRAMEWORK_NAME).xcarchive" \
	SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

	xcodebuild -create-xcframework \
    -archive "$(FRAMEWORKS_OUTPUT)/ios/$(FRAMEWORK_NAME).xcarchive" -framework $(FRAMEWORK_NAME).framework \
    -archive "$(FRAMEWORKS_OUTPUT)/ios-simulator/$(FRAMEWORK_NAME).xcarchive" -framework $(FRAMEWORK_NAME).framework \
    -output "$(FRAMEWORKS_OUTPUT)/$(FRAMEWORK_NAME).xcframework"

	@echo "Created XCFramework (and platform specific frameworks) in $(FRAMEWORKS_OUTPUT)"
	@echo "WARNING: This is an untested method of integration"

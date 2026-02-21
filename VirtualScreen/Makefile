APP_NAME = Monitra Virtual
BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS_DIR = $(APP_BUNDLE)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources

all: bundle

bundle: main.swift AppDelegate.swift StreamView.swift VirtualConnector.swift DisplayStreamWrapper.m VirtualScreen-Bridging-Header.h Info.plist LogHelper.swift AppIcon.icns OnboardingWindow.swift
	@mkdir -p "$(MACOS_DIR)"
	@mkdir -p "$(RESOURCES_DIR)"
	swiftc main.swift AppDelegate.swift StreamView.swift VirtualConnector.swift DisplayStreamWrapper.m LogHelper.swift OnboardingWindow.swift \
		-import-objc-header VirtualScreen-Bridging-Header.h \
		-O \
		-o "$(MACOS_DIR)/$(APP_NAME)" \
		-framework Cocoa -framework CoreGraphics -framework CoreDisplay -framework CoreVideo \
		-F /System/Library/PrivateFrameworks
	cp Info.plist "$(CONTENTS_DIR)/Info.plist"
	cp AppIcon.icns "$(RESOURCES_DIR)/AppIcon.icns"
	cp ../monitra_virtual.svg "$(RESOURCES_DIR)/monitra_virtual.svg"
	xattr -cr "$(APP_BUNDLE)"
	codesign --force --deep --sign - --entitlements Entitlements.plist "$(APP_BUNDLE)"
	@echo "Built REGULAR (Release) $(APP_NAME).app in $(BUILD_DIR)"

debug: main.swift AppDelegate.swift StreamView.swift VirtualConnector.swift DisplayStreamWrapper.m VirtualScreen-Bridging-Header.h Info.plist LogHelper.swift AppIcon.icns OnboardingWindow.swift
	@mkdir -p "$(MACOS_DIR)"
	@mkdir -p "$(RESOURCES_DIR)"
	swiftc main.swift AppDelegate.swift StreamView.swift VirtualConnector.swift DisplayStreamWrapper.m LogHelper.swift OnboardingWindow.swift \
		-import-objc-header VirtualScreen-Bridging-Header.h \
		-D DEBUG \
		-o "$(MACOS_DIR)/$(APP_NAME)" \
		-framework Cocoa -framework CoreGraphics -framework CoreDisplay -framework CoreVideo \
		-F /System/Library/PrivateFrameworks
	cp Info.plist "$(CONTENTS_DIR)/Info.plist"
	cp AppIcon.icns "$(RESOURCES_DIR)/AppIcon.icns"
	cp ../monitra_virtual.svg "$(RESOURCES_DIR)/monitra_virtual.svg"
	xattr -cr "$(APP_BUNDLE)"
	codesign --force --deep --sign - --entitlements Entitlements.plist "$(APP_BUNDLE)"
	@echo "Built DEBUG $(APP_NAME).app in $(BUILD_DIR)"

clean:
	rm -rf $(BUILD_DIR)

dist: clean bundle
	@cd $(BUILD_DIR) && zip -r "$(APP_NAME).zip" "$(APP_NAME).app"
	@echo "Created distribution ZIP in $(BUILD_DIR)/$(APP_NAME).zip"

dmg: clean bundle
	@echo "Creating DMG..."
	@mkdir -p $(BUILD_DIR)/dmg_root
	@cp -R "$(APP_BUNDLE)" $(BUILD_DIR)/dmg_root/
	@ln -s /Applications $(BUILD_DIR)/dmg_root/Applications
	@hdiutil create -volname "$(APP_NAME)" -srcfolder $(BUILD_DIR)/dmg_root -ov -format UDZO $(BUILD_DIR)/"$(APP_NAME).dmg"
	@rm -rf $(BUILD_DIR)/dmg_root
	@echo "Created DMG in $(BUILD_DIR)/$(APP_NAME).dmg"

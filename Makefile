.PHONY: bootstrap project build test lint format

PACKAGE_DIR := Packages/SnapboltKit
XCODEBUILD_FLAGS ?=

bootstrap:
	brew install xcodegen swiftlint

project:
	xcodegen generate

build: project
	xcodebuild -project Snapbolt.xcodeproj -scheme Snapbolt -configuration Debug \
		-destination 'platform=macOS' build $(XCODEBUILD_FLAGS)

test:
	cd $(PACKAGE_DIR) && swift test $(if $(FILTER),--filter $(FILTER),)

lint:
	swiftlint --strict
	swift format lint --strict --recursive App $(PACKAGE_DIR)/Sources $(PACKAGE_DIR)/Tests $(PACKAGE_DIR)/Package.swift

format:
	swift format --in-place --recursive App $(PACKAGE_DIR)/Sources $(PACKAGE_DIR)/Tests $(PACKAGE_DIR)/Package.swift

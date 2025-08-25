# Makefile for Hastighed iOS App
# This Makefile provides build targets for the iOS app

.PHONY: help build build-simulator clean test install-deps run

# Default target
help:
	@echo "Available targets:"
	@echo "  build        - Build the iOS app using Xcode"
	@echo "  build-simulator - Build the iOS app for Simulator"
	@echo "  clean        - Clean build artifacts"
	@echo "  test         - Run tests"
	@echo "  install-deps - Install Swift dependencies"
	@echo "  run          - Build and run in simulator"

# Build the iOS app
build:
	@echo "Building Hastighed iOS app..."
	xcodebuild -project hastighed.xcodeproj -scheme hastighed -configuration Release -destination 'generic/platform=iOS' build

# Build for simulator
build-simulator:
	@echo "Building for iOS Simulator..."
	xcodebuild -project hastighed.xcodeproj -scheme hastighed -configuration Debug -destination 'generic/platform=iOS Simulator' build

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	xcodebuild -project hastighed.xcodeproj -scheme hastighed clean
	rm -rf build/
	rm -rf DerivedData/

# Run tests
test:
	@echo "Running tests..."
	xcodebuild -project hastighed.xcodeproj -scheme hastighed -destination 'generic/platform=iOS Simulator' test

# Install dependencies (if using Swift Package Manager)
install-deps:
	@echo "Installing Swift dependencies..."
	xcodebuild -resolvePackageDependencies

# Build and run in simulator
run: build-simulator
	@echo "Launching in iOS Simulator..."
	xcrun simctl install booted build/Debug-iphonesimulator/hastighed.app
	xcrun simctl launch booted com.eopio.hastighed

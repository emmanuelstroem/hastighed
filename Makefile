# Makefile for Hastighed iOS project
# Usage examples:
#   make build        # Debug build for current platform (iPhone 15 simulator default)
#   make test         # (placeholder) Add unit tests later
#   make archive      # Create XCFramework style archive (future)
#   make clean        # Clean derived data
#   make ensure       # CI-style: clean + build

SCHEME=hastighed
PROJECT=hastighed.xcodeproj
CONFIG=Debug
DESTINATION?=platform=iOS Simulator,name=iPhone 16 Pro
DERIVED_DATA?=DerivedData

XCODEBUILD=xcodebuild
COMMON_OPTS=-project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIG) -destination '$(DESTINATION)' -derivedDataPath $(DERIVED_DATA) -quiet

.PHONY: build clean ensure test archive release help

help:
	@grep -E '^[a-zA-Z_-]+:.*?##' Makefile | sed 's/:.*##/\t- /'

build: ## Build the app for simulator (override DESTINATION to change)
	$(XCODEBUILD) build $(COMMON_OPTS) || (echo "Build failed" && exit 1)
	@echo '✅ Build succeeded'

clean: ## Remove derived data
	rm -rf $(DERIVED_DATA)
	@echo '🧹 Cleaned derived data'

ensure: clean build ## Clean then build (useful for CI)

# Placeholder test target until tests added
test: ## Run unit tests (none yet)
	@echo 'No tests defined yet.'

# Simple release build (no signing adjustments here)
release: CONFIG=Release
release: build ## Release build for simulator

# Archive placeholder (extend with exportOptionsPlist when distributing)
archive: CONFIG=Release DESTINATION='generic/platform=iOS'
archive:
	$(XCODEBUILD) archive -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIG) -archivePath $(DERIVED_DATA)/Build/$(SCHEME).xcarchive -quiet || (echo "Archive failed" && exit 1)
	@echo '📦 Archive created at $(DERIVED_DATA)/Build/$(SCHEME).xcarchive'

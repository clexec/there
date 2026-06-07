SCHEME = THEREMusic
PROJECT = THEREMusic.xcodeproj
SIM = platform=iOS Simulator,name=iPhone 15 Pro

.PHONY: gen build clean open

gen:
	xcodegen generate

build: gen
	xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "$(SIM)" \
		-configuration Debug \
		CODE_SIGNING_ALLOWED=NO | xcpretty

open: gen
	open $(PROJECT)

clean:
	rm -rf $(PROJECT)
	rm -rf DerivedData
	rm -rf .build

setup:
	brew install xcodegen xcpretty 2>/dev/null || true
	$(MAKE) gen
	$(MAKE) open

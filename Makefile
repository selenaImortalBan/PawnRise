.PHONY: project open test lint clean bootstrap

project:
	@which xcodegen > /dev/null || (echo "xcodegen not found. Run: brew install xcodegen" && exit 1)
	xcodegen generate

open: project
	open PawnRise.xcodeproj

test: project
	xcodebuild test \
		-project PawnRise.xcodeproj \
		-scheme PawnRise \
		-destination 'platform=iOS Simulator,name=iPhone 15'

bootstrap:
	brew list xcodegen > /dev/null 2>&1 || brew install xcodegen

clean:
	rm -rf PawnRise.xcodeproj build DerivedData

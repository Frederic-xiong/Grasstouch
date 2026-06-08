.PHONY: project clean install-tools

project:
	@command -v xcodegen >/dev/null || { echo "xcodegen not found. Run: brew install xcodegen"; exit 1; }
	xcodegen generate

install-tools:
	brew install xcodegen

clean:
	rm -rf Throttle.xcodeproj build DerivedData

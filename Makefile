.PHONY: all test vet core-lib build-linux build-apk aar proto app-deps app-test app-run clean package-linux icons

# Every build output lands in builds/.
BIN := builds
SHA := $(shell git rev-parse --short HEAD 2>/dev/null || echo dev)
VERSION := 0.1.0
# One stamp per make run: the app and the core built together share it, so
# the app can tell when it talks to a core from another build.
STAMP := $(shell date +%m%d.%H%M%S)
# The app's CMake build runs `make core-lib` with POSTERN_BUILD_ID set.
BUILD_ID := $(or $(POSTERN_BUILD_ID),$(SHA)-$(STAMP))
DEFINES := --dart-define=APP_VERSION=$(VERSION) --dart-define=BUILD_SHA=$(SHA) --dart-define=BUILD_ID=$(BUILD_ID) --dart-define=ENV=$(or $(ENV),dev)
GO_LDFLAGS := -X github.com/SelfHold/postern/core/rpc.Version=$(VERSION) -X github.com/SelfHold/postern/core/rpc.Build=$(BUILD_ID)
NDK ?= $(lastword $(sort $(wildcard $(HOME)/Android/Sdk/ndk/*)))
PROTOC_DART := $(HOME)/.pub-cache/bin/protoc-gen-dart
# Tests: one run at a time, at most 1 GB.
CAP := systemd-run --user --scope -p MemoryMax=1G -p MemorySwapMax=0 --quiet

all: vet test build-linux

test:
	$(CAP) go test ./core/...

vet:
	go vet ./...

# The desktop core (desktopbind) as a C archive, linked into the Linux app's
# executable: one process, no daemon. app/linux/CMakeLists.txt runs this, so
# `flutter build linux` and `flutter run` build it too.
CORE_LIB ?= app/build/core/libpostern.a
core-lib: BUILD_ID = $(or $(POSTERN_BUILD_ID),dev)
core-lib:
	CGO_ENABLED=1 go build -buildmode=c-archive -ldflags '$(GO_LDFLAGS)' -o $(CORE_LIB) ./desktopbind

# A CMake cache made at another checkout path (the repo was moved or renamed)
# breaks `flutter build linux`, so it is dropped first.
build-linux: app-deps
	@c=app/build/linux/x64/release/CMakeCache.txt; \
	if [ -f "$$c" ] && ! grep -qxF "CMAKE_CACHEFILE_DIR:INTERNAL=$(CURDIR)/app/build/linux/x64/release" "$$c"; then \
		echo "CMake cache from another checkout path: removing app/build/linux"; \
		rm -rf app/build/linux; \
	fi
	cd app && POSTERN_BUILD_ID=$(BUILD_ID) flutter build linux --release $(DEFINES)
	rm -rf $(BIN)/linux && mkdir -p $(BIN)/linux
	cp -r app/build/linux/x64/release/bundle/. $(BIN)/linux/
	@echo "app: $(BIN)/linux/postern"

# Linux packages from the build-linux output, described in packaging/linux/nfpm.yaml.
# PKG picks the formats (deb, rpm, archlinux; all three by default), e.g.
#   make package-linux PKG=archlinux
# Packages land in $(BIN)/packages/. nfpm runs through `go run` unless it is installed.
PKG ?= deb rpm archlinux
NFPM ?= $(or $(shell command -v nfpm 2>/dev/null),go run github.com/goreleaser/nfpm/v2/cmd/nfpm@v2.49.0)

package-linux: build-linux
	mkdir -p $(BIN)/packages
	@for p in $(PKG); do \
		PKG_VERSION=$(VERSION) $(NFPM) package -f packaging/linux/nfpm.yaml -p $$p -t $(BIN)/packages/ || exit 1; \
	done

# Re-renders the committed PNG icons (app, Android) from the SVGs in branding/.
icons:
	branding/render.sh

# The core for Android (gomobile, NDK from ~/Android/Sdk/ndk). The Kotlin
# side (CoreService, MethodChannel "dev.selfhold.postern/core", Shard binding)
# is not written yet: see README.
aar:
	ANDROID_NDK_HOME=$(NDK) gomobile bind -target=android/arm64,android/amd64 -androidapi 26 \
		-javapkg dev.selfhold.postern -ldflags='-s -w $(GO_LDFLAGS)' -o app/android/app/libs/postern.aar ./mobilebind

build-apk: aar app-deps
	cd app && flutter build apk --release --split-per-abi --target-platform android-arm64,android-x64 $(DEFINES)
	mkdir -p $(BIN)/android
	cp app/build/app/outputs/flutter-apk/*-release.apk $(BIN)/android/

# Go and Dart code from proto/postern.proto; Go client from proto/connector.proto
# (Shard's contract, copied byte for byte).
proto:
	protoc -I proto \
		--go_out=core/rpc/pb --go_opt=paths=source_relative \
		--go-grpc_out=core/rpc/pb --go-grpc_opt=paths=source_relative \
		proto/postern.proto
	protoc -I proto --plugin=protoc-gen-dart=$(PROTOC_DART) --dart_out=grpc:app/lib/data/rpc/gen proto/postern.proto
	protoc -I proto \
		--go_out=core/shard/pb --go_opt=paths=source_relative --go_opt=Mconnector.proto=github.com/SelfHold/postern/core/shard/pb \
		--go-grpc_out=core/shard/pb --go-grpc_opt=paths=source_relative --go-grpc_opt=Mconnector.proto=github.com/SelfHold/postern/core/shard/pb \
		proto/connector.proto

app-deps:
	cd app && flutter pub get

app-test: app-deps
	cd app && flutter analyze && $(CAP) env NODE_OPTIONS= flutter test

app-run: app-deps
	cd app && POSTERN_BUILD_ID=$(BUILD_ID) flutter run -d linux $(DEFINES)

clean:
	rm -rf $(BIN) app/build app/android/app/libs/postern.aar

# Api

## Overview
`Api` is a Swift Package that provides a unified, async-native interface to a suite of AI models (image generation, video generation, large language models, and speech-to-text) hosted on `femi.market`. It bridges Swift to Rust via FFI, leveraging a pre-compiled `RustFFI.xcframework` for iOS and macOS. The package handles authentication, network requests, cancellation, JSON parsing, and graceful fallbacks, allowing developers to integrate remote AI capabilities with minimal boilerplate.

## Features
- **Cross-platform support**: iOS 15+ and macOS 12+
- **Swift Concurrency native**: Fully async/await with `Task` cancellation support
- **Rust-backed FFI**: High-performance, memory-safe network layer compiled to native binaries
- **Automatic fallbacks**: Returns curated fallback assets for network errors, non-200 responses, or HTTP 402 (insufficient credits)
- **Swift 6 compatible**: Uses strict concurrency checking and modern Swift language modes
- **Zero-dependency Swift layer**: Only depends on the bundled `RustFFI.xcframework` and Foundation

## Architecture & Key Files
| Path | Purpose |
|------|---------|
| `Package.swift` | SPM manifest. Defines the `Api` library, links `RustFFI.xcframework`, and bundles fallback resources. |
| `RustFFI.xcframework/` | Pre-built universal framework containing Rust FFI bindings for iOS (arm64 + simulator) and macOS (arm64 + x86_64). |
| `Rust/src/lib.rs` | Rust entry point. Lazily initializes a shared `tokio` runtime (2 workers) and `reqwest` HTTP client. |
| `Rust/src/*.rs` | Individual FFI implementations for each model. POST to `https://femi.market/api`, handle cancellation flags, and return heap-allocated response bytes. |
| `Rust/include/RustFFI/RustFFI.h` | C header declaring the FFI function signatures consumed by Swift. |
| `build-rust.sh` | Build script that compiles the Rust crate for all target platforms, creates universal binaries, and regenerates `RustFFI.xcframework`. |
| `Sources/Api/*.swift` | Swift wrappers that call the FFI, manage cancellation flags, parse JSON responses, and return typed Swift values. |
| `Tests/ApiTests/*.swift` | Swift 6 `Testing` framework tests covering fallback behavior, cancellation, and funded-user responses. |

## Requirements
- Swift 6.0+ (tools version 6.3)
- iOS 15+ / macOS 12+
- Rust toolchain (`rustup`, `cargo`)
- `xcodebuild` (required only if rebuilding the FFI)

## Installation & Build
Add the package to your project via Swift Package Manager. The `RustFFI.xcframework` is included in the repository and will be automatically linked.

To rebuild the Rust FFI from source:
```bash
chmod +x build-rust.sh
./build-rust.sh
```
The script installs the required `rustup` targets, compiles in `--release` mode, merges iOS simulator architectures into a universal binary, and regenerates `RustFFI.xcframework` in the repository root.

## Usage
All endpoints are exposed as static async methods on the `Api` type. They accept credentials, model-specific inputs, and return typed results.

```swift
import Api

// Text-to-Image
let image = await Api.flux2Pro(user: "myuser", password: "mypass", prompt: "a cyberpunk city at dusk")

// Image-to-Image
let edited = await Api.flux2DevI2I(
    user: "myuser", password: "mypass",
    image: originalImageData, prompt: "add neon signs"
)

// Text-to-Video
let video = await Api.ltx2_3a2v(
    user: "myuser", password: "mypass",
    image: referenceImage, audio: backgroundMusic, prompt: "slow pan forward"
)

// LLM Chat
let messages = [(role: .user, content: "Explain quantum computing in one sentence")]
let response = await Api.qwen3_6_35b_a3b(user: "myuser", password: "mypass", messages: messages)

// Speech-to-Text
let lyrics = await Api.qwen3AsrFlash(user: "myuser", password: "mypass", audio: songData)
```

### Cancellation
Swift `Task` cancellation is fully supported. Cancel the task and the FFI layer will abort the in-flight request within ~10ms:
```swift
let task = Task { await Api.flux2Pro(user: "u", password: "p", prompt: "long generation...") }
// ...
task.cancel() // Rust FFI detects flag and returns early
let result = await task.value
```

## API Reference
| Function | Input | Output | Description |
|----------|-------|--------|-------------|
| `Api.zImageTurbo(user:password:prompt:)` | `String, String, String` | `Data` | Text-to-image generation |
| `Api.nanoBanana2(user:password:prompt:)` | `String, String, String` | `Data` | Text-to-image generation |
| `Api.flux2Pro(user:password:prompt:)` | `String, String, String` | `Data` | Text-to-image generation |
| `Api.flux2DevI2I(user:password:image:prompt:)` | `String, String, Data, String` | `Data` | Single-image input-to-image |
| `Api.flux2KleinI2I(user:password:image:image2:prompt:)` | `String, String, Data, Data, String` | `Data` | Dual-image input-to-image |
| `Api.ltx2_3a2v(user:password:image:audio:prompt:)` | `String, String, Data, Data, String` | `Data` | Image+audio-to-video |
| `Api.qwen3_6_35b_a3b(user:password:messages:)` | `String, String, [(Role, String)]` | `[(Role, String)]` | LLM chat with conversation history |
| `Api.qwen3AsrFlash(user:password:audio:)` | `String, String, Data` | `String` | Audio transcription / lyric extraction |

## Testing
Run the test suite with:
```bash
API_USER="your_username" API_PASSWORD="your_password" swift test
```
Tests require valid credentials to hit the live `femi.market` endpoints. The suite verifies:
- Fallback assets are returned for unfunded/missing credentials
- Cancellation resolves in <1s and returns fallback content
- Funded users receive valid generated media or responses
- Edge cases (empty inputs, unicode prompts, empty audio)

## Cancellation & Error Handling
- **Cancellation**: Swift's `withTaskCancellationHandler` sets a shared `UInt8` flag. The Rust FFI polls this flag every 10ms via `AtomicU8::load`. If non-zero, the request aborts and returns status `0`.
- **Error Fallbacks**: 
  - HTTP 402 → Returns `Api.topupImage` or `Api.topupVideo`
  - Network failures, timeouts, or non-200 responses → Returns `Api.fallbackImage` or `Api.fallbackVideo`
  - LLM/ASR failures → Returns `"Could not respond"` or `"Could not process lyrics"`
- **Memory Management**: Rust allocates response bytes on the heap and returns a raw pointer. Swift wraps it in `Data(bytesNoCopy:count:deallocator: .free)` to ensure automatic deallocation when the `Data` instance goes out of scope.

## Conventions & Notes
- A single `tokio` runtime and `reqwest` client are lazily initialized in `Rust/src/lib.rs` and shared across all FFI calls.
- All FFI functions expect credentials via HTTP Basic Auth. The Rust layer constructs the request body with a UUID v7, model type, and status placeholder.
- The Swift wrappers assume the server returns JSON with an `action` object containing a `file` field (base64-encoded media) or `messages`/`lyrics` fields.
- Swift 6 strict concurrency is enforced via `swiftLanguageModes: [.v6]` in `Package.swift`. All public APIs are `Sendable`-compatible.
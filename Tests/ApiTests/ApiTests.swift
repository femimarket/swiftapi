import Testing
import Foundation
@testable import Api

/// Credentials for live-server tests, read once from process env.
/// Set via `API_USER=... API_PASSWORD=... swift test`. Crashes loudly if either is missing.
let testUser = ProcessInfo.processInfo.environment["API_USER"]!
let testPassword = ProcessInfo.processInfo.environment["API_PASSWORD"]!

/// Cancel / missing-bearer / unfunded behavior is shared FFI plumbing across every
/// endpoint, so each test picks one endpoint at random per run rather than
/// duplicating identical logic across each endpoint test file.
struct ApiTests {
    @Test func unfundedUserReturnsTopupFallback() async throws {
        let user = "unfunded-test-\(UUID().uuidString)"
        let password = "anything"
        switch Int.random(in: 0..<8) {
        case 0:
            let r = await Api.zImageTurbo(user: user, password: password, prompt: "hello")
            #expect(r == Api.topupImage)
        case 1:
            let r = await Api.nanoBanana2(user: user, password: password, prompt: "hello")
            #expect(r == Api.topupImage)
        case 2:
            let r = await Api.flux2Pro(user: user, password: password, prompt: "hello")
            #expect(r == Api.topupImage)
        case 3:
            let r = await Api.flux2DevI2I(user: user, password: password, image: Data([0, 1, 2, 3]), prompt: "hello")
            #expect(r == Api.topupImage)
        case 4:
            let r = await Api.flux2KleinI2I(
                user: user,
                password: password,
                image: Data([0, 1, 2, 3]),
                image2: Data([0, 1, 2, 3]),
                prompt: "hello"
            )
            #expect(r == Api.topupImage)
        case 5:
            let r = await Api.ltx2_3a2v(
                user: user,
                password: password,
                image: Data(),
                audio: Data(),
                prompt: "hello"
            )
            #expect(r == Api.topupVideo)
        case 6:
            let r = await Api.qwen3AsrFlash(user: user, password: password, audio: Data([0, 1, 2, 3]))
            #expect(r == "Top up to transcribe lyrics")
        default:
            let r = await Api.qwen3_6_35b_a3b(
                user: user,
                password: password,
                messages: [(role: .user, content: "hi")]
            )
            #expect(r.last?.content == "Could not respond")
        }
    }

    @Test func missingCredentialsReturnsGenericFallback() async throws {
        switch Int.random(in: 0..<8) {
        case 0:
            let r = await Api.zImageTurbo(user: "", password: "", prompt: "hello")
            #expect(r == Api.fallbackImage)
        case 1:
            let r = await Api.nanoBanana2(user: "", password: "", prompt: "hello")
            #expect(r == Api.fallbackImage)
        case 2:
            let r = await Api.flux2Pro(user: "", password: "", prompt: "hello")
            #expect(r == Api.fallbackImage)
        case 3:
            let r = await Api.flux2DevI2I(user: "", password: "", image: Data([0, 1, 2, 3]), prompt: "hello")
            #expect(r == Api.fallbackImage)
        case 4:
            let r = await Api.flux2KleinI2I(
                user: "",
                password: "",
                image: Data([0, 1, 2, 3]),
                image2: Data([0, 1, 2, 3]),
                prompt: "hello"
            )
            #expect(r == Api.fallbackImage)
        case 5:
            let r = await Api.ltx2_3a2v(
                user: "",
                password: "",
                image: Data(),
                audio: Data(),
                prompt: "hello"
            )
            #expect(r == Api.fallbackVideo)
        case 6:
            let r = await Api.qwen3AsrFlash(user: "", password: "", audio: Data([0, 1, 2, 3]))
            #expect(r == "Could not process lyrics")
        default:
            let r = await Api.qwen3_6_35b_a3b(
                user: "",
                password: "",
                messages: [(role: .user, content: "hi")]
            )
            #expect(r.last?.content == "Could not respond")
        }
    }

    @Test func cancellationReturnsFallback() async throws {
        let pick = Int.random(in: 0..<7)
        let task = Task { () -> String in
            switch pick {
            case 0:
                let d = await Api.zImageTurbo(user: testUser, password: testPassword, prompt: "a red apple on a wooden table")
                return d == Api.fallbackImage ? "ok" : "wrong"
            case 1:
                let d = await Api.nanoBanana2(user: testUser, password: testPassword, prompt: "a red apple on a wooden table")
                return d == Api.fallbackImage ? "ok" : "wrong"
            case 2:
                let d = await Api.flux2Pro(user: testUser, password: testPassword, prompt: "a red apple on a wooden table")
                return d == Api.fallbackImage ? "ok" : "wrong"
            case 3:
                let d = await Api.flux2DevI2I(user: testUser, password: testPassword, image: Data([0, 1, 2, 3]), prompt: "hello")
                return d == Api.fallbackImage ? "ok" : "wrong"
            case 4:
                let d = await Api.flux2KleinI2I(
                    user: testUser,
                    password: testPassword,
                    image: Data([0, 1, 2, 3]),
                    image2: Data([0, 1, 2, 3]),
                    prompt: "hello"
                )
                return d == Api.fallbackImage ? "ok" : "wrong"
            case 5:
                let d = await Api.ltx2_3a2v(
                    user: testUser,
                    password: testPassword,
                    image: Data(),
                    audio: Data(),
                    prompt: "a calm ocean wave at sunset"
                )
                return d == Api.fallbackVideo ? "ok" : "wrong"
            case 6:
                let r = await Api.qwen3AsrFlash(user: testUser, password: testPassword, audio: Data([0, 1, 2, 3]))
                return r == "Could not process lyrics" ? "ok" : "wrong"
            default:
                let r = await Api.qwen3_6_35b_a3b(
                    user: testUser,
                    password: testPassword,
                    messages: [(role: .user, content: "write a long story")]
                )
                return r.last?.content == "Could not respond" ? "ok" : "wrong"
            }
        }
        try await Task.sleep(nanoseconds: 100_000_000)
        task.cancel()
        let start = Date()
        let result = await task.value
        let elapsed = Date().timeIntervalSince(start)
        #expect(result == "ok")
        #expect(elapsed < 1.0, "cancel should resolve in <1s, took \(elapsed)s")
    }
}

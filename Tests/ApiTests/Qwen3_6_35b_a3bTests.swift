import Testing
import Foundation
@testable import Api

struct Qwen3_6_35b_a3bTests {
    @Test func fundedUserReturnsReply() async throws {
        let result = await Api.qwen3_6_35b_a3b(
            user: testUser,
            password: testPassword,
            messages: [(role: .user, content: "say hi in one word")]
        )
        #expect(result.count == 2)
        #expect(result.last?.role == .assistant)
        let reply = result.last?.content ?? ""
        #expect(reply != "Could not respond")
        #expect(!reply.isEmpty)
    }

    @Test func emptyMessagesReturnsFallback() async throws {
        let result = await Api.qwen3_6_35b_a3b(user: testUser, password: testPassword, messages: [])
        #expect(result.count == 1)
        #expect(result.last?.content == "Could not respond")
    }
}

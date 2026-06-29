import Foundation
import RustFFI

extension Api {
    /// Role of a chat turn for qwen3_6_35b_a3b. Raw value matches the wire
    /// format the server expects (`"User"` / `"Assistant"`).
    public enum Role: String, Sendable {
        case user = "User"
        case assistant = "Assistant"
    }

    /// Each tuple is one chat turn — `role` is `.user` or `.assistant`,
    /// `content` is the message text. Returns `messages` with the new
    /// assistant turn appended: the model's reply on success, or
    /// `"Could not respond"` on any failure. Always safe to feed the result
    /// straight back as the next call's `messages`.
    public static func qwen3_6_35b_a3b(
        user: String,
        password: String,
        messages: [(role: Role, content: String)]
    ) async -> [(role: Role, content: String)] {
        let flag = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
        flag.initialize(to: 0)
        defer { flag.deinitialize(count: 1); flag.deallocate() }
        let flagAddr = UInt(bitPattern: flag)
        let wire = messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        let messagesJson = String(data: try! JSONSerialization.data(withJSONObject: wire), encoding: .utf8)!
        let original = messages
        return await withTaskCancellationHandler {
            await Task.detached(priority: .userInitiated) {
                let p = UnsafePointer<UInt8>(bitPattern: flagAddr)
                var status: UInt16 = 0
                var len = 0
                let ptr: UnsafeMutablePointer<UInt8>? = user.withCString { u in
                    password.withCString { pw in
                        messagesJson.withCString { m in
                            rust_ffi_qwen3_6_35b_a3b(u, pw, m, p, &status, &len)
                        }
                    }
                }
                let body: Data = (ptr != nil && len > 0)
                    ? Data(bytesNoCopy: ptr!, count: len, deallocator: .free)
                    : Data()
                if status == 200,
                   let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                   let action = json["action"] as? [String: Any],
                   let msgs = action["messages"] as? [[String: Any]],
                   let last = msgs.last,
                   let content = last["content"] as? String,
                   !content.isEmpty {
                    return original + [(role: .assistant, content: content)]
                }
                return original + [(role: .assistant, content: "Could not respond")]
            }.value
        } onCancel: {
            UnsafeMutablePointer<UInt8>(bitPattern: flagAddr)?.pointee = 1
        }
    }
}

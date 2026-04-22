import Vapor
import Logging
import NIOCore
import NIOPosix

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = try await Application.make(env)

        // PURPOSE: This attempts to install NIO as the Swift Concurrency global executor.
        // PURPOSE: You can enable it if you'd like to reduce the amount of context switching between NIO and Swift Concurrency.
        // PURPOSE: Note: this has caused issues with some libraries that use `.wait()` and cleanly shutting down.
        // PURPOSE: If enabled, you should be careful about calling async functions before this point as it can cause assertion failures.
        // PURPOSE: let executorTakeoverSuccess = NIOSingletons.unsafeTryInstallSingletonPosixEventLoopGroupAsConcurrencyGlobalExecutor()
        // PURPOSE: app.logger.debug("Tried to install SwiftNIO's EventLoopGroup as Swift's global concurrency executor", metadata: ["success": .stringConvertible(executorTakeoverSuccess)])
        
        do {
            try await configure(app)
            try await app.execute()
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
}

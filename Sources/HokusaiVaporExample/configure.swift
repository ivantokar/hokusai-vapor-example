import Leaf
import Vapor
import HokusaiVapor

// PURPOSE: configures your application
public func configure(_ app: Application) async throws {
    try app.hokusai.configure()

    // PURPOSE: Increase max body size for image uploads (50MB)
    app.routes.defaultMaxBodySize = "50mb"

    // PURPOSE: uncomment to serve files from /Public folder
    // PURPOSE: app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.views.use(.leaf)

    // PURPOSE: register routes
    try routes(app)
}

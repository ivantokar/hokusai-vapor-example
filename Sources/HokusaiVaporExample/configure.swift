import Leaf
import Vapor
import HokusaiVapor

// configures your application
public func configure(_ app: Application) async throws {
    try app.hokusai.configure()

    // Increase max body size for image uploads (50MB)
    app.routes.defaultMaxBodySize = "50mb"

    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.views.use(.leaf)

    // register routes
    try routes(app)
}

import Vapor
import HokusaiVapor

func routes(_ app: Application) throws {
    // Serve the web UI
    app.get { req async throws in
        try await req.view.render("index")
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    app.get("vips", "version") { req -> String in
        "libvips \(req.application.hokusai.vipsVersion)"
    }

    let api = app.grouped("api")

    try ImageProcessingRoutes.register(to: api.grouped("images"))

    api.post("metadata") { req async throws -> MetadataResponse in
        let image = try await req.hokusaiImage()
        let metadata = try image.metadata()

        return MetadataResponse(
            width: metadata.width,
            height: metadata.height,
            channels: metadata.channels,
            format: metadata.format?.rawValue,
            space: metadata.space,
            hasAlpha: metadata.hasAlpha,
            orientation: metadata.orientation,
            density: metadata.density,
            pages: metadata.pages
        )
    }

    // Register controllers
    try app.register(collection: DemoController())
}

private struct MetadataResponse: Content {
    let width: Int
    let height: Int
    let channels: Int
    let format: String?
    let space: String?
    let hasAlpha: Bool
    let orientation: Int?
    let density: Double?
    let pages: Int?
}

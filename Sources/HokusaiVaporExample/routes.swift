import Vapor
import HokusaiVapor
import Hokusai

func routes(_ app: Application) throws {
    // Serve the web UI
    app.get { req async throws in
        try await req.view.render("index")
    }

    app.get("hello") { _ async -> String in
        "Hello, world!"
    }

    app.get("vips", "version") { req -> String in
        "libvips \(req.application.hokusai.vipsVersion)"
    }

    let api = app.grouped("api")
    let images = api.grouped("images")

    // Convert image format from raw request body
    images.post("convert") { req async throws -> Response in
        struct ConvertQuery: Content {
            let format: String
            let quality: Int?
            let compression: Int?
        }

        let query = try req.query.decode(ConvertQuery.self)
        let imageData = try requestBodyData(req)
        let image = try await Hokusai.image(from: imageData)
        let format = query.format.lowercased()

        if format == "png" {
            return try image.response(
                format: format,
                compression: query.compression ?? 6
            )
        }

        return try image.response(
            format: format,
            quality: query.quality ?? 85,
            compression: query.compression
        )
    }

    // Add text overlay to image from raw request body
    images.post("text") { req async throws -> Response in
        struct TextQuery: Content {
            let text: String
            let fontSize: Int?
            let font: String?
            let x: Int?
            let y: Int?
            let strokeWidth: Double?
            let quality: Int?
            let format: String?
        }

        let query = try req.query.decode(TextQuery.self)
        let imageData = try requestBodyData(req)
        let image = try await Hokusai.image(from: imageData)

        var options = TextOptions()
        options.font = query.font ?? "sans"
        options.fontSize = query.fontSize ?? 48
        options.color = [0, 0, 0, 255]

        if let strokeWidth = query.strokeWidth {
            options.strokeColor = [255, 255, 255, 255]
            options.strokeWidth = strokeWidth
        }

        let x = try query.x ?? (image.width / 2)
        let y = try query.y ?? (image.height / 2)

        let withText = try image.drawText(
            query.text,
            x: x,
            y: y,
            options: options
        )

        let format = query.format?.lowercased() ?? "jpeg"
        if format == "png" {
            return try withText.response(format: "png", compression: 6)
        }

        return try withText.response(
            format: format,
            quality: query.quality ?? 90
        )
    }

    // Resize from raw request body
    images.post("resize") { req async throws -> Response in
        struct ResizeQuery: Content {
            let width: Int?
            let height: Int?
            let fit: String?
            let format: String?
            let quality: Int?
        }

        let query = try req.query.decode(ResizeQuery.self)
        guard query.width != nil || query.height != nil else {
            throw Abort(.badRequest, reason: "Provide width or height")
        }

        let imageData = try requestBodyData(req)
        let image = try await Hokusai.image(from: imageData)

        var options = ResizeOptions()
        switch query.fit?.lowercased() {
        case "cover":
            options.fit = .cover
        case "fill":
            options.fit = .fill
        default:
            options.fit = .inside
        }

        let resized = try image.resize(width: query.width, height: query.height, options: options)
        let format = query.format?.lowercased() ?? "jpeg"

        if format == "png" {
            return try resized.response(format: "png", compression: 6)
        }

        return try resized.response(format: format, quality: query.quality ?? 85)
    }

    api.post("metadata") { req async throws -> MetadataResponse in
        struct MetadataQuery: Content {
            let extended: Bool?
        }

        let query = try req.query.decode(MetadataQuery.self)
        let imageData = try requestBodyData(req)
        let image = try await Hokusai.image(from: imageData)
        let metadata = try image.metadata()
        let extended = (query.extended ?? false) ? try image.extendedMetadata() : nil

        return MetadataResponse(
            width: metadata.width,
            height: metadata.height,
            channels: metadata.channels,
            format: metadata.format?.rawValue,
            space: metadata.space,
            hasAlpha: metadata.hasAlpha,
            orientation: metadata.orientation,
            density: metadata.density,
            pages: metadata.pages,
            extended: extended
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
    let extended: [String: String]?
}

private func requestBodyData(_ req: Request) throws -> Data {
    guard let buffer = req.body.data else {
        throw Abort(.badRequest, reason: "No image data in request body")
    }

    guard let data = buffer.getData(at: buffer.readerIndex, length: buffer.readableBytes) else {
        throw Abort(.badRequest, reason: "Failed to read image data from request")
    }

    return data
}

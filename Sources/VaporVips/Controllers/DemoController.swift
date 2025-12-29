import Vapor
import HokusaiVapor
import Hokusai

struct DemoController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let demo = routes.grouped("demo")

        demo.post("text", use: textOverlay)
        demo.post("resize", use: resizeImage)
        demo.post("convert", use: convertFormat)
        demo.get("certificate", use: generateCertificate)
        demo.post("rotate", use: rotateImage)
        demo.post("metadata", use: getMetadata)
        demo.post("composite", use: compositeImage)
    }

    // Text Overlay
    func textOverlay(req: Request) async throws -> Response {
        // Decode multipart form data manually
        struct FormInput: Content {
            var text: String
            var fontSize: Int?
            var strokeWidth: Double?
            var image: File
        }

        let input = try req.content.decode(FormInput.self)

        // Convert file to HokusaiImage
        guard let data = input.image.data.getData(
            at: input.image.data.readerIndex,
            length: input.image.data.readableBytes
        ) else {
            throw Abort(.badRequest, reason: "Failed to read image data")
        }
        let image = try await Hokusai.image(from: data)

        var textOptions = TextOptions()
        textOptions.font = "DejaVu-Sans"
        textOptions.fontSize = input.fontSize ?? 48
        textOptions.color = [255, 255, 255, 255]  // White
        textOptions.strokeColor = [0, 0, 0, 255]   // Black outline
        textOptions.strokeWidth = input.strokeWidth ?? 2.0

        // Center text
        let x = try image.width / 2
        let y = try image.height / 2

        let withText = try image.drawText(
            input.text,
            x: x,
            y: y,
            options: textOptions
        )

        return try withText.response(format: "jpeg", quality: 90)
    }

    // Resize Image
    func resizeImage(req: Request) async throws -> Response {
        struct FormInput: Content {
            var width: Int?
            var height: Int?
            var fit: String?
            var image: File
        }

        let input = try req.content.decode(FormInput.self)

        guard let data = input.image.data.getData(
            at: input.image.data.readerIndex,
            length: input.image.data.readableBytes
        ) else {
            throw Abort(.badRequest, reason: "Failed to read image data")
        }
        let image = try await Hokusai.image(from: data)

        var options = ResizeOptions()

        // Map fit mode
        switch input.fit {
        case "cover":
            options.fit = .cover
        case "fill":
            options.fit = .fill
        case "inside", .none:
            options.fit = .inside
        default:
            options.fit = .inside
        }

        let resized = try image.resize(
            width: input.width,
            height: input.height,
            options: options
        )

        return try resized.response(format: "jpeg", quality: 85)
    }

    // Convert Format
    func convertFormat(req: Request) async throws -> Response {
        struct FormInput: Content {
            var format: String
            var quality: Int?
            var image: File
        }

        let input = try req.content.decode(FormInput.self)

        guard let data = input.image.data.getData(
            at: input.image.data.readerIndex,
            length: input.image.data.readableBytes
        ) else {
            throw Abort(.badRequest, reason: "Failed to read image data")
        }
        let image = try await Hokusai.image(from: data)

        return try image.response(
            format: input.format,
            quality: input.quality ?? 85
        )
    }

    // Generate Certificate
    func generateCertificate(req: Request) async throws -> Response {
        struct Query: Content {
            let name: String
        }

        let params = try req.query.decode(Query.self)

        // Determine paths based on environment
        let certificatePath: String
        let fontPath: String

        if FileManager.default.fileExists(atPath: "/app/TestAssets/certifcate.png") {
            // Docker container paths
            certificatePath = "/app/TestAssets/certifcate.png"
            fontPath = "DejaVu-Sans"  // System font available in container
        } else {
            // Local development paths
            certificatePath = "TestAssets/certifcate.png"
            fontPath = "DejaVu-Sans"  // Use system font
        }

        let cert = try await Hokusai.image(from: certificatePath)

        var textOptions = TextOptions()
        textOptions.font = fontPath
        textOptions.fontSize = 96
        textOptions.color = [0, 0, 128, 255]
        textOptions.strokeColor = [255, 255, 255, 255]
        textOptions.strokeWidth = 2.0

        let certWidth = try cert.width
        let certHeight = try cert.height
        let textX = certWidth / 2
        let textY = Int(Double(certHeight) * 0.6)

        let withText = try cert.drawText(
            params.name,
            x: textX,
            y: textY,
            options: textOptions
        )

        return try withText.response(format: "png", compression: 9)
    }

    // Rotate Image
    func rotateImage(req: Request) async throws -> Response {
        struct FormInput: Content {
            var angle: Int
            var image: File
        }

        let input = try req.content.decode(FormInput.self)

        guard let data = input.image.data.getData(
            at: input.image.data.readerIndex,
            length: input.image.data.readableBytes
        ) else {
            throw Abort(.badRequest, reason: "Failed to read image data")
        }
        let image = try await Hokusai.image(from: data)

        let rotated: HokusaiImage

        switch input.angle {
        case 90:
            rotated = try image.rotate(angle: .degree90)
        case 180:
            rotated = try image.rotate(angle: .degree180)
        case 270:
            rotated = try image.rotate(angle: .degree270)
        default:
            rotated = image
        }

        return try rotated.response(format: "jpeg", quality: 85)
    }

    // Get Metadata
    func getMetadata(req: Request) async throws -> Response {
        struct MetadataResponse: Content {
            let width: Int
            let height: Int
            let channels: Int
            let hasAlpha: Bool
            let format: String?
        }

        let image = try await req.hokusaiImage(field: "image")
        let metadata = try image.metadata()

        let response = MetadataResponse(
            width: metadata.width,
            height: metadata.height,
            channels: metadata.channels,
            hasAlpha: metadata.hasAlpha,
            format: metadata.format?.rawValue
        )

        return try await response.encodeResponse(for: req)
    }

    // Composite/Watermark
    func compositeImage(req: Request) async throws -> Response {
        struct FormInput: Content {
            var x: Int?
            var y: Int?
            var opacity: Double?
            var mode: String?
            var baseImage: File
            var overlayImage: File
        }

        let input = try req.content.decode(FormInput.self)

        // Convert base image
        guard let baseData = input.baseImage.data.getData(
            at: input.baseImage.data.readerIndex,
            length: input.baseImage.data.readableBytes
        ) else {
            throw Abort(.badRequest, reason: "Failed to read base image data")
        }
        let base = try await Hokusai.image(from: baseData)

        // Convert overlay image
        guard let overlayData = input.overlayImage.data.getData(
            at: input.overlayImage.data.readerIndex,
            length: input.overlayImage.data.readableBytes
        ) else {
            throw Abort(.badRequest, reason: "Failed to read overlay image data")
        }
        let overlay = try await Hokusai.image(from: overlayData)

        // Parse blend mode
        let blendMode: BlendMode
        switch input.mode {
        case "add":
            blendMode = .add
        case "multiply":
            blendMode = .multiply
        default:
            blendMode = .over
        }

        // Create composite options
        var options = CompositeOptions()
        options.mode = blendMode
        if let opacity = input.opacity {
            options.opacity = opacity
        }

        // Perform composite
        let composited = try base.composite(
            overlay: overlay,
            x: input.x ?? 0,
            y: input.y ?? 0,
            options: options
        )

        return try composited.response(format: "png", quality: 90)
    }
}

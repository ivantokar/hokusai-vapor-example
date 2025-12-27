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
    }

    // Text Overlay
    func textOverlay(req: Request) async throws -> Response {
        struct FormData: Content {
            let text: String
            let fontSize: Int?
            let strokeWidth: Double?
        }

        let formData = try req.content.decode(FormData.self)
        let image = try await req.hokusaiImage(field: "image")

        var textOptions = TextOptions()
        textOptions.font = "DejaVu-Sans"
        textOptions.fontSize = formData.fontSize ?? 48
        textOptions.color = [255, 255, 255, 255]  // White
        textOptions.strokeColor = [0, 0, 0, 255]   // Black outline
        textOptions.strokeWidth = formData.strokeWidth ?? 2.0

        // Center text
        let x = try image.width / 2
        let y = try image.height / 2

        let withText = try image.drawText(
            formData.text,
            x: x,
            y: y,
            options: textOptions
        )

        return try withText.response(format: "jpeg", quality: 90)
    }

    // Resize Image
    func resizeImage(req: Request) async throws -> Response {
        struct FormData: Content {
            let width: Int?
            let height: Int?
            let fit: String?
        }

        let formData = try req.content.decode(FormData.self)
        let image = try await req.hokusaiImage(field: "image")

        var options = ResizeOptions()

        // Map fit mode
        switch formData.fit {
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
            width: formData.width,
            height: formData.height,
            options: options
        )

        return try resized.response(format: "jpeg", quality: 85)
    }

    // Convert Format
    func convertFormat(req: Request) async throws -> Response {
        struct FormData: Content {
            let format: String
            let quality: Int?
        }

        let formData = try req.content.decode(FormData.self)
        let image = try await req.hokusaiImage(field: "image")

        return try image.response(
            format: formData.format,
            quality: formData.quality ?? 85
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

        if FileManager.default.fileExists(atPath: "/app/tmp/certifcate.png") {
            // Docker container paths
            certificatePath = "/app/tmp/certifcate.png"
            fontPath = "PasseroOne-Regular"
        } else {
            // Local development paths
            certificatePath = "/Users/ivantokar/Work/vips/tmp/certifcate.png"
            fontPath = "/Users/ivantokar/Work/vips/tmp/Passero_One/PasseroOne-Regular.ttf"
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
        struct FormData: Content {
            let angle: Int
        }

        let formData = try req.content.decode(FormData.self)
        let image = try await req.hokusaiImage(field: "image")

        let rotated: HokusaiImage

        switch formData.angle {
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
}

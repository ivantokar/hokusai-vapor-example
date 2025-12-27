import Vapor
import HokusaiVapor
import Hokusai

struct CertificateController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api", "certificate")
        api.post("generate", use: generate)
    }

    func generate(req: Request) async throws -> Response {
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
            fontPath = "PasseroOne-Regular"  // Use font name in Docker (installed in system fonts)
        } else {
            // Local development paths
            certificatePath = "/Users/ivantokar/Work/vips/tmp/certifcate.png"
            fontPath = "/Users/ivantokar/Work/vips/tmp/Passero_One/PasseroOne-Regular.ttf"
        }

        // Load certificate template
        let cert = try await Hokusai.image(from: certificatePath)

        // Configure Passero_One font
        var textOptions = TextOptions()
        textOptions.font = fontPath
        textOptions.fontSize = 96
        textOptions.color = [0, 0, 128, 255]  // Navy blue
        textOptions.strokeColor = [255, 255, 255, 255]  // White outline
        textOptions.strokeWidth = 2.0

        // Calculate position (centered in blue bordered area)
        let certWidth = try cert.width
        let certHeight = try cert.height
        let textX = certWidth / 2
        let textY = Int(Double(certHeight) * 0.6)

        // Render text with ImageMagick
        let withText = try cert.drawText(
            params.name,
            x: textX,
            y: textY,
            options: textOptions
        )

        return try withText.response(format: "png", compression: 9)
    }
}

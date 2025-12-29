import Foundation
import Vapor
import HokusaiVapor
import Hokusai

struct DemoController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let demo = routes.grouped("demo")

        demo.post("text", use: textOverlay)
        demo.post("resize", use: resizeImage)
        demo.post("convert", use: convertFormat)
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
            var image: File?
            var useTemplate: String?
            var font: String?
            var fontUrl: String?
            var color: String?
            var strokeColor: String?
            var kerning: Double?
            var rotation: Double?
            var align: String?
            var lineSpacing: Double?
            var position: String?
            var x: Int?
            var y: Int?
        }

        let input = try req.content.decode(FormInput.self)
        let useTemplate = isTemplateEnabled(input.useTemplate)

        let image = try await loadBaseImage(
            req: req,
            imageFile: input.image,
            useTemplate: useTemplate
        )

        var textOptions = TextOptions()
        textOptions.font = try await resolveFontPath(
            req: req,
            font: input.font,
            fontUrl: input.fontUrl
        )
        textOptions.fontSize = input.fontSize ?? 48
        textOptions.color = parseRGBA(input.color) ?? [255, 255, 255, 255]
        textOptions.kerning = input.kerning
        textOptions.rotation = input.rotation
        textOptions.lineSpacing = input.lineSpacing

        if let align = TextAlignment(rawValue: (input.align ?? "").lowercased()) {
            textOptions.align = align
        }

        if let strokeWidth = input.strokeWidth {
            textOptions.strokeWidth = strokeWidth
            textOptions.strokeColor = parseRGBA(input.strokeColor) ?? [0, 0, 0, 255]
        } else if let strokeColor = parseRGBA(input.strokeColor) {
            textOptions.strokeColor = strokeColor
        }

        let withText: HokusaiImage
        if let position = parsePosition(input.position) {
            withText = try image.drawText(
                input.text,
                position: position,
                options: textOptions
            )
        } else {
            let x = try input.x ?? (image.width / 2)
            let y = try input.y ?? (image.height / 2)
            withText = try image.drawText(
                input.text,
                x: x,
                y: y,
                options: textOptions
            )
        }

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

        guard let baseData = input.baseImage.data.getData(
            at: input.baseImage.data.readerIndex,
            length: input.baseImage.data.readableBytes
        ) else {
            throw Abort(.badRequest, reason: "Failed to read base image data")
        }

        let base = try await Hokusai.image(from: baseData)

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

        let composited = try base.composite(
            overlay: overlay,
            x: input.x ?? 0,
            y: input.y ?? 0,
            options: options
        )

        return try composited.response(format: "png")
    }

    // MARK: - Text Helpers

    private func isTemplateEnabled(_ value: String?) -> Bool {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            return false
        }
        return value == "true" || value == "1" || value == "on"
    }

    private func loadBaseImage(
        req: Request,
        imageFile: File?,
        useTemplate: Bool
    ) async throws -> HokusaiImage {
        if useTemplate {
            let templatePath = resolveTemplatePath()
            return try await Hokusai.image(from: templatePath)
        }

        guard let imageFile = imageFile else {
            throw Abort(.badRequest, reason: "Image is required unless useTemplate is set")
        }

        guard let data = imageFile.data.getData(
            at: imageFile.data.readerIndex,
            length: imageFile.data.readableBytes
        ) else {
            throw Abort(.badRequest, reason: "Failed to read image data")
        }

        return try await Hokusai.image(from: data)
    }

    private func resolveTemplatePath() -> String {
        if FileManager.default.fileExists(atPath: "/app/TestAssets/certifcate.png") {
            return "/app/TestAssets/certifcate.png"
        }
        return "TestAssets/certifcate.png"
    }

    private func resolveFontPath(
        req: Request,
        font: String?,
        fontUrl: String?
    ) async throws -> String {
        if let fontUrl = fontUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
           !fontUrl.isEmpty {
            return try await downloadFont(req: req, fontUrl: fontUrl)
        }

        if let font = font?.trimmingCharacters(in: .whitespacesAndNewlines),
           !font.isEmpty {
            return font
        }

        if hasSystemFonts() {
            return "sans"
        }

        throw Abort(.badRequest, reason: "No system fonts available. Provide font or fontUrl.")
    }

    private func downloadFont(req: Request, fontUrl: String) async throws -> String {
        guard let url = URL(string: fontUrl),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http" else {
            throw Abort(.badRequest, reason: "Font URL must be http or https")
        }

        let response = try await req.client.get(URI(string: fontUrl))
        guard response.status == .ok else {
            throw Abort(.badRequest, reason: "Failed to download font")
        }

        guard let buffer = response.body,
              let data = buffer.getData(
                at: buffer.readerIndex,
                length: buffer.readableBytes
              ) else {
            throw Abort(.badRequest, reason: "Empty font response")
        }

        let fontsDir = FileManager.default.temporaryDirectory.appendingPathComponent("hokusai-fonts")
        try FileManager.default.createDirectory(
            at: fontsDir,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let ext = url.pathExtension.isEmpty ? "ttf" : url.pathExtension
        let filename = "\(UUID().uuidString).\(ext)"
        let fileUrl = fontsDir.appendingPathComponent(filename)

        try data.write(to: fileUrl)
        return fileUrl.path
    }

    private func hasSystemFonts() -> Bool {
        let searchPaths = [
            "/usr/share/fonts",
            "/usr/local/share/fonts",
            "/Library/Fonts",
            "/System/Library/Fonts"
        ]

        for path in searchPaths {
            guard let enumerator = FileManager.default.enumerator(atPath: path) else {
                continue
            }

            for case let item as String in enumerator {
                let lowercased = item.lowercased()
                if lowercased.hasSuffix(".ttf") || lowercased.hasSuffix(".otf") {
                    return true
                }
            }
        }

        return false
    }

    private func parsePosition(_ value: String?) -> Position? {
        switch value?.lowercased() {
        case "center":
            return .center
        case "top":
            return .top
        case "bottom":
            return .bottom
        case "left":
            return .left
        case "right":
            return .right
        case "top-left":
            return .topLeft
        case "top-right":
            return .topRight
        case "bottom-left":
            return .bottomLeft
        case "bottom-right":
            return .bottomRight
        default:
            return nil
        }
    }

    private func parseRGBA(_ value: String?) -> [Double]? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }

        if value.hasPrefix("#") {
            let hex = String(value.dropFirst())
            guard hex.count == 6 || hex.count == 8 else {
                return nil
            }

            let chars = Array(hex)
            func hexByte(_ index: Int) -> Double? {
                let start = index * 2
                let end = start + 2
                guard end <= chars.count else { return nil }
                let pair = String(chars[start..<end])
                return Double(Int(pair, radix: 16) ?? 0)
            }

            guard let r = hexByte(0),
                  let g = hexByte(1),
                  let b = hexByte(2) else {
                return nil
            }

            let a = hex.count == 8 ? (hexByte(3) ?? 255) : 255
            return [r, g, b, a]
        }

        let parts = value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 3 || parts.count == 4 else {
            return nil
        }

        let numbers = parts.compactMap { Double($0) }
        guard numbers.count == parts.count else {
            return nil
        }

        let r = clampColor(numbers[0])
        let g = clampColor(numbers[1])
        let b = clampColor(numbers[2])
        let a = parts.count == 4 ? clampColor(numbers[3]) : 255
        return [r, g, b, a]
    }

    private func clampColor(_ value: Double) -> Double {
        return min(max(value, 0), 255)
    }
}

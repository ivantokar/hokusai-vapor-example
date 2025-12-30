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

    // Advanced Text Rendering - Showcase ImageMagick capabilities
    func textOverlay(req: Request) async throws -> Response {
        req.logger.info("Received text overlay request")

        // Comprehensive form input covering all ImageMagick text features
        struct FormInput: Content {
            // Required
            var text: String
            var image: File

            // Font settings
            var font: String?
            var fontUrl: String?
            var fontSize: Int?
            var fontWeight: Int?
            var dpi: Int?

            // Color settings
            var color: String?          // Hex (#RRGGBB or #RRGGBBAA) or comma-separated RGBA
            var opacity: Double?        // 0.0-1.0 (affects text color alpha)

            // Stroke/Outline settings
            var strokeWidth: Double?
            var strokeColor: String?
            var strokeOpacity: Double?  // 0.0-1.0

            // Shadow settings
            var shadowOffsetX: Double?
            var shadowOffsetY: Double?
            var shadowColor: String?
            var shadowOpacity: Double?  // 0.0-1.0

            // Typography settings
            var kerning: Double?
            var lineSpacing: Double?
            var align: String?          // left, center, right
            var textWidth: Int?         // Text wrapping width
            var textHeight: Int?        // Text height limit

            // Transform settings
            var rotation: Double?       // Degrees
            var antialiasing: String?   // true/false

            // Position settings
            var position: String?       // center, top, bottom, etc.
            var gravity: String?        // ImageMagick gravity
            var x: Int?
            var y: Int?
        }

        let input: FormInput
        do {
            input = try req.content.decode(FormInput.self)
            req.logger.info("Successfully decoded form input")
        } catch {
            req.logger.error("Failed to decode form input: \(error)")
            throw Abort(.badRequest, reason: "Invalid form data: \(error.localizedDescription)")
        }

        // Load image from uploaded file
        guard let data = input.image.data.getData(
            at: input.image.data.readerIndex,
            length: input.image.data.readableBytes
        ) else {
            req.logger.error("Failed to read image data from uploaded file")
            throw Abort(.badRequest, reason: "Failed to read image data")
        }

        req.logger.info("Loading image, size: \(data.count) bytes")
        let image = try await Hokusai.image(from: data)
        let imageWidth = try image.width
        let imageHeight = try image.height
        req.logger.info("Image loaded successfully: \(imageWidth)x\(imageHeight)")

        // Build comprehensive text options
        var textOptions = TextOptions()

        // Font
        textOptions.font = try await resolveFontPath(
            req: req,
            font: input.font,
            fontUrl: input.fontUrl
        )
        textOptions.fontSize = input.fontSize ?? 48
        // Note: fontWeight parameter is accepted but not yet supported by Hokusai library
        textOptions.dpi = input.dpi ?? 72

        // Color with opacity
        var baseColor = parseRGBA(input.color) ?? [255, 255, 255, 255]
        if let opacity = input.opacity {
            baseColor[3] = clampOpacity(opacity) * 255
        }
        textOptions.color = baseColor

        // Stroke with opacity
        if let strokeWidth = input.strokeWidth {
            textOptions.strokeWidth = strokeWidth
            var strokeCol = parseRGBA(input.strokeColor) ?? [0, 0, 0, 255]
            if let strokeOpacity = input.strokeOpacity {
                strokeCol[3] = clampOpacity(strokeOpacity) * 255
            }
            textOptions.strokeColor = strokeCol
        }

        // Shadow settings
        if let shadowX = input.shadowOffsetX,
           let shadowY = input.shadowOffsetY {
            textOptions.shadowOffset = (x: shadowX, y: shadowY)

            var shadowCol = parseRGBA(input.shadowColor) ?? [0, 0, 0, 128]
            if let shadowOpacity = input.shadowOpacity {
                shadowCol[3] = clampOpacity(shadowOpacity) * 255
            }
            textOptions.shadowColor = shadowCol
        }

        // Typography
        textOptions.kerning = input.kerning
        textOptions.lineSpacing = input.lineSpacing
        textOptions.width = input.textWidth
        textOptions.height = input.textHeight

        if let align = TextAlignment(rawValue: (input.align ?? "").lowercased()) {
            textOptions.align = align
        }

        // Transform
        textOptions.rotation = input.rotation
        textOptions.antialiasing = !(input.antialiasing?.lowercased() == "false")

        // Gravity
        if let gravity = parseGravity(input.gravity) {
            textOptions.gravity = gravity
        }

        // Draw text
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

        return try withText.response(format: "png")
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
            req.logger.error("Invalid font URL: \(fontUrl)")
            throw Abort(.badRequest, reason: "Font URL must be http or https")
        }

        req.logger.info("Downloading font from: \(fontUrl)")
        let response = try await req.client.get(URI(string: fontUrl))
        guard response.status == .ok else {
            req.logger.error("Failed to download font, status: \(response.status)")
            throw Abort(.badRequest, reason: "Failed to download font: \(response.status)")
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

    private func parseGravity(_ value: String?) -> TextGravity? {
        switch value?.lowercased() {
        case "center":
            return .center
        case "north":
            return .north
        case "south":
            return .south
        case "east":
            return .east
        case "west":
            return .west
        case "northeast", "north-east":
            return .northEast
        case "northwest", "north-west":
            return .northWest
        case "southeast", "south-east":
            return .southEast
        case "southwest", "south-west":
            return .southWest
        default:
            return nil
        }
    }

    private func clampOpacity(_ value: Double) -> Double {
        return min(max(value, 0.0), 1.0)
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

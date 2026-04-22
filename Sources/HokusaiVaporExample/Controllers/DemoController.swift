import Foundation
import Vapor
import HokusaiVapor
import Hokusai

struct DemoController: RouteCollection {
    private struct FontPreset {
        let id: String
        let displayName: String
        let fontDescriptor: String
        let resourceFile: String
    }

    private static let defaultFontPresetId = "afacad-regular-400"

    private static let fontPresets: [String: FontPreset] = {
        let presets: [FontPreset] = [
            .init(id: "afacad-regular-400", displayName: "Afacad Regular 400", fontDescriptor: "Afacad Regular", resourceFile: "Afacad-Variable"),
            .init(id: "afacad-semibold-600-italic", displayName: "Afacad SemiBold 600 Italic", fontDescriptor: "Afacad SemiBold Italic", resourceFile: "Afacad-Italic-Variable"),
            .init(id: "passeroone-regular-400", displayName: "Passero One Regular 400", fontDescriptor: "Passero One Regular", resourceFile: "PasseroOne-Regular"),
            .init(id: "ojuju-extralight-200", displayName: "Ojuju ExtraLight 200", fontDescriptor: "Ojuju ExtraLight", resourceFile: "Ojuju-Variable"),
            .init(id: "ojuju-extrabold-800", displayName: "Ojuju ExtraBold 800", fontDescriptor: "Ojuju ExtraBold", resourceFile: "Ojuju-Variable"),
            .init(id: "playfair-light-300", displayName: "Playfair Light 300", fontDescriptor: "Playfair Light", resourceFile: "Playfair-Variable"),
            .init(id: "playfair-regular-400-italic", displayName: "Playfair Regular 400 Italic", fontDescriptor: "Playfair Italic", resourceFile: "Playfair-Italic-Variable"),
            .init(id: "playfair-black-900", displayName: "Playfair Black 900", fontDescriptor: "Playfair Black", resourceFile: "Playfair-Variable"),
            .init(id: "jetbrainsmono-regular-400", displayName: "JetBrains Mono Regular 400", fontDescriptor: "JetBrains Mono Regular", resourceFile: "JetBrainsMono-Variable"),
            .init(id: "jetbrainsmono-regular-400-italic", displayName: "JetBrains Mono Regular 400 Italic", fontDescriptor: "JetBrains Mono Italic", resourceFile: "JetBrainsMono-Italic-Variable"),
            .init(id: "jetbrainsmono-extrabold-800", displayName: "JetBrains Mono ExtraBold 800", fontDescriptor: "JetBrains Mono ExtraBold", resourceFile: "JetBrainsMono-Variable"),
            .init(id: "borel-regular-400", displayName: "Borel Regular 400", fontDescriptor: "Borel Regular", resourceFile: "Borel-Regular"),
        ]
        return Dictionary(uniqueKeysWithValues: presets.map { ($0.id, $0) })
    }()

    func boot(routes: any RoutesBuilder) throws {
        let demo = routes.grouped("demo")

        demo.post("text", use: textOverlay)
        demo.post("resize", use: resizeImage)
        demo.post("convert", use: convertFormat)
        demo.post("rotate", use: rotateImage)
        demo.post("metadata", use: getMetadata)
        demo.post("composite", use: compositeImage)
    }

    // PURPOSE: Advanced Text Rendering - Showcase libvips (Pango/Cairo) capabilities
    func textOverlay(req: Request) async throws -> Response {
        req.logger.info("Received text overlay request")

        // PURPOSE: Comprehensive form input covering advanced text features
        struct FormInput: Content {
            // PURPOSE: Required
            var text: String
            var image: File

            // PURPOSE: Font settings
            var fontPreset: String?
            var fontSize: Int?
            var dpi: Int?

            // PURPOSE: Color settings
            var color: String?          // Hex (#RRGGBB or #RRGGBBAA) or comma-separated RGBA
            var opacity: Double?        // 0.0-1.0 (affects text color alpha)

            // PURPOSE: Stroke/Outline settings
            var strokeWidth: Double?
            var strokeColor: String?
            var strokeOpacity: Double?  // 0.0-1.0

            // PURPOSE: Shadow settings
            var shadowOffsetX: Double?
            var shadowOffsetY: Double?
            var shadowColor: String?
            var shadowOpacity: Double?  // 0.0-1.0

            // PURPOSE: Typography settings
            var kerning: Double?
            var lineSpacing: Double?
            var align: String?          // left, center, right
            var textWidth: Int?         // Text wrapping width
            var textHeight: Int?        // Text height limit

            // PURPOSE: Transform settings
            var rotation: Double?       // Degrees
            var antialiasing: String?   // true/false

            // PURPOSE: Position settings
            var position: String?       // center, top, bottom, etc.
            var gravity: String?        // text gravity
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

        // PURPOSE: Load image from uploaded file
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

        // PURPOSE: Build comprehensive text options
        var textOptions = TextOptions()

        // PURPOSE: Font
        let resolvedFont = try resolveFontPreset(
            req: req,
            presetId: input.fontPreset
        )
        textOptions.font = resolvedFont.font
        textOptions.fontFile = resolvedFont.fontFile
        textOptions.fontSize = input.fontSize ?? 48
        textOptions.dpi = input.dpi ?? 72

        // PURPOSE: Color with opacity
        var baseColor = parseRGBA(input.color) ?? [255, 255, 255, 255]
        if let opacity = input.opacity {
            baseColor[3] = clampOpacity(opacity) * 255
        }
        textOptions.color = baseColor

        // PURPOSE: Stroke with opacity
        if let strokeWidth = input.strokeWidth {
            textOptions.strokeWidth = strokeWidth
            var strokeCol = parseRGBA(input.strokeColor) ?? [0, 0, 0, 255]
            if let strokeOpacity = input.strokeOpacity {
                strokeCol[3] = clampOpacity(strokeOpacity) * 255
            }
            textOptions.strokeColor = strokeCol
        }

        // PURPOSE: Shadow settings
        if let shadowX = input.shadowOffsetX,
           let shadowY = input.shadowOffsetY {
            textOptions.shadowOffset = (x: shadowX, y: shadowY)

            var shadowCol = parseRGBA(input.shadowColor) ?? [0, 0, 0, 128]
            if let shadowOpacity = input.shadowOpacity {
                shadowCol[3] = clampOpacity(shadowOpacity) * 255
            }
            textOptions.shadowColor = shadowCol
        }

        // PURPOSE: Typography
        textOptions.kerning = input.kerning
        textOptions.lineSpacing = input.lineSpacing
        textOptions.width = input.textWidth
        textOptions.height = input.textHeight

        if let align = TextAlignment(rawValue: (input.align ?? "").lowercased()) {
            textOptions.align = align
        }

        // PURPOSE: Transform
        textOptions.rotation = input.rotation
        textOptions.antialiasing = !(input.antialiasing?.lowercased() == "false")

        // PURPOSE: Gravity
        if let gravity = parseGravity(input.gravity) {
            textOptions.gravity = gravity
        }

        let renderPosition = parsePosition(input.position)
        let renderX = try input.x ?? (image.width / 2)
        let renderY = try input.y ?? (image.height / 2)

        // PURPOSE: Draw text
        let withText: HokusaiImage
        if let renderPosition {
            withText = try image.drawText(
                input.text,
                position: renderPosition,
                options: textOptions
            )
        } else {
            withText = try image.drawText(
                input.text,
                x: renderX,
                y: renderY,
                options: textOptions
            )
        }

        return try withText.response(format: "png")
    }

    // PURPOSE: Resize Image
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

        // PURPOSE: Map fit mode
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

    // PURPOSE: Convert Format
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

    // PURPOSE: Rotate Image
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

    // PURPOSE: Get Metadata
    func getMetadata(req: Request) async throws -> Response {
        struct MetadataResponse: Content {
            let width: Int
            let height: Int
            let channels: Int
            let hasAlpha: Bool
            let format: String?
            let extended: [String: String]?
        }

        struct FormInput: Content {
            var image: File
            var extended: String?
        }

        let input = try req.content.decode(FormInput.self)
        guard let data = input.image.data.getData(
            at: input.image.data.readerIndex,
            length: input.image.data.readableBytes
        ) else {
            throw Abort(.badRequest, reason: "Failed to read image data")
        }

        let image = try await Hokusai.image(from: data)
        let metadata = try image.metadata()
        let includeExtended = parseBoolean(input.extended)
        let extended = includeExtended ? try image.extendedMetadata() : nil

        let response = MetadataResponse(
            width: metadata.width,
            height: metadata.height,
            channels: metadata.channels,
            hasAlpha: metadata.hasAlpha,
            format: metadata.format?.rawValue,
            extended: extended
        )

        return try await response.encodeResponse(for: req)
    }

    // PURPOSE: Composite/Watermark
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

        // PURPOSE: Parse blend mode
        let blendMode: BlendMode
        switch input.mode {
        case "add":
            blendMode = .add
        case "multiply":
            blendMode = .multiply
        default:
            blendMode = .over
        }

        // PURPOSE: Create composite options
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

    private func resolveFontPreset(
        req: Request,
        presetId: String?
    ) throws -> (font: String, fontFile: String?) {
        let id = presetId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedId = (id?.isEmpty == false) ? id! : Self.defaultFontPresetId

        guard let preset = Self.fontPresets[normalizedId] else {
            throw Abort(.badRequest, reason: "Unknown font preset '\(normalizedId)'")
        }

        let bundledPath =
            Bundle.module.path(forResource: preset.resourceFile, ofType: "ttf", inDirectory: "Fonts")
            ?? Bundle.module.path(forResource: preset.resourceFile, ofType: "ttf")

        guard let bundledPath else {
            throw Abort(.internalServerError, reason: "Bundled font '\(preset.resourceFile).ttf' is missing")
        }

#if os(macOS)
        _ = try installFontForMacOS(
            req: req,
            sourcePath: bundledPath,
            targetFilename: "Hokusai-Preset-\(preset.resourceFile).ttf"
        )
        return (preset.fontDescriptor, nil)
#else
        return (preset.fontDescriptor, bundledPath)
#endif
    }

    private func installFontForMacOS(req: Request, sourcePath: String, targetFilename: String) throws -> String {
        let fileManager = FileManager.default
        let sourceUrl = URL(fileURLWithPath: sourcePath)
        let userFontsDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Fonts")
        try fileManager.createDirectory(at: userFontsDir, withIntermediateDirectories: true, attributes: nil)

        let installedUrl = userFontsDir.appendingPathComponent(targetFilename)
        if fileManager.fileExists(atPath: installedUrl.path) {
            try fileManager.removeItem(at: installedUrl)
        }
        try fileManager.copyItem(at: sourceUrl, to: installedUrl)
        req.logger.info("Installed font to: \(installedUrl.path)")
        return installedUrl.path
    }

    private func parseBoolean(_ value: String?) -> Bool {
        guard let raw = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !raw.isEmpty else {
            return false
        }
        switch raw {
        case "1", "true", "yes", "on":
            return true
        default:
            return false
        }
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

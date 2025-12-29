# Test Assets

This directory contains sample images and resources for testing the Hokusai image processing features.

## Files

### certifcate.png
- **Size**: 3206 x 2266 pixels
- **Format**: PNG with alpha channel
- **Purpose**: Template image for the text drawing demo
- **Usage**: Used by `/demo/text` with `useTemplate=true` to draw text onto a static template image

### sample-photo.jpg
- **Size**: 1000 x 800 pixels
- **Format**: JPEG
- **Purpose**: General-purpose test image for demonstrating various operations
- **Usage**: Can be used to test resize, rotate, convert, text overlay, and other operations

### watermark.png
- **Size**: 200 x 50 pixels
- **Format**: PNG with alpha channel (grayscale + alpha)
- **Purpose**: Sample watermark for composite/overlay testing
- **Usage**: Used to test the composite operation (watermarking feature)

## Using Test Assets

You can reference these files in your local development:

```swift
// Example: Load template image
let templateImage = try await Hokusai.image(from: "TestAssets/certifcate.png")

// Example: Load sample photo
let photo = try await Hokusai.image(from: "TestAssets/sample-photo.jpg")

// Example: Load watermark
let watermark = try await Hokusai.image(from: "TestAssets/watermark.png")
```

## Adding Your Own Test Assets

You can add additional test images to this directory for your own testing needs. Common use cases:

- **Different formats**: Add AVIF, WebP, GIF files to test format conversion
- **Various sizes**: Add small thumbnails and large images to test resize operations
- **Custom fonts**: Add TTF/OTF font files for text rendering tests (place in `Fonts/` subdirectory)
- **Logos and icons**: Add brand assets for watermarking demos

## Note on Docker

When running in Docker, make sure to copy this directory into the container. See the `Dockerfile` for the COPY instruction.

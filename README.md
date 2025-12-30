# Hokusai Vapor Example

**Interactive demo application for Hokusai image processing**

A production-ready Vapor application demonstrating the full capabilities of [Hokusai](https://github.com/ivantokar/hokusai) and [Hokusai Vapor](https://github.com/ivantokar/hokusai-vapor). Features a beautiful web UI for testing image operations interactively, plus comprehensive REST API endpoints.

## Features

- **Interactive Web UI** - Modern interface for testing all image operations
- **Dark Mode** - Pure monochromatic theme with smooth transitions
- **Advanced Text Demo** - Showcase ImageMagick's full text rendering capabilities
  - Custom Google Fonts with all weight variants (400-900)
  - Stroke/outline with customizable width and color
  - Drop shadows with offset and opacity control
  - Typography controls (kerning, line spacing, alignment)
  - Text rotation and positioning
- **Image Operations** - Resize, rotate, crop, format conversion, compositing
- **Live Preview** - See results instantly in the browser
- **Code Examples** - View cURL and Swift code for each operation
- **Docker Ready** - Production Dockerfile with multi-stage builds

## Perfect For

- **Learning** - Explore Hokusai's capabilities interactively
- **Prototyping** - Test image processing workflows before implementation
- **Reference** - Production-ready code examples and patterns
- **Starter Template** - Clone and customize for your own image processing API

## Prerequisites

### macOS
```bash
brew install vips imagemagick pkg-config
```

### Ubuntu/Debian
```bash
sudo apt update
sudo apt install libvips-dev libmagick++-dev libmagickwand-dev pkg-config
```

## Run Locally

```bash
swift run HokusaiVaporExample
```

Open http://localhost:8081

## Run with Docker

```bash
# Build the image
docker compose build

# Start the application
docker compose up app

# Or combine both steps
docker compose up --build app
```

Open http://localhost:8081

**Note:** The first build may take several minutes as it downloads and compiles dependencies.

## What's Included

- **Demo UI** (`/`) - Interactive web interface with all features
- **REST API** - Production-ready endpoints for all operations
- **Sample Assets** - Test images, certificates, watermarks
- **Documentation** - Comprehensive examples and API usage
- **Docker Config** - Multi-stage build with libvips + ImageMagick

## Testing Endpoints

### Advanced Text Rendering (ImageMagick)

The demo showcases ImageMagick's comprehensive text rendering capabilities:

```bash
# Basic text overlay with Google Font
curl -X POST http://localhost:8081/demo/text \
  -F "image=@TestAssets/certifcate.png" \
  -F "text=John Doe" \
  -F "fontUrl=https://fonts.gstatic.com/s/playfairdisplay/v30/nuFvD-vYSZviVYUb_rj3ij__anPXJzDwcbmjWBN2PKdFvUDQZNLo_U2r.ttf" \
  -F "fontSize=72" \
  -F "color=#2c3e50" \
  -F "position=center" \
  -o certificate.png

# Advanced text with stroke, shadow, and effects
curl -X POST http://localhost:8081/demo/text \
  -F "image=@TestAssets/sample-photo.jpg" \
  -F "text=Hello World" \
  -F "fontSize=64" \
  -F "fontUrl=https://fonts.gstatic.com/s/roboto/v30/KFOmCnqEu92Fr1Me5Q.ttf" \
  -F "color=#FFFFFF" \
  -F "opacity=0.9" \
  -F "strokeWidth=2" \
  -F "strokeColor=#000000" \
  -F "shadowOffsetX=3" \
  -F "shadowOffsetY=3" \
  -F "shadowColor=#000000" \
  -F "shadowOpacity=0.5" \
  -F "kerning=1.5" \
  -F "rotation=-5" \
  -F "position=bottom-right" \
  -o styled-text.png
```

**Supported text features:**
- Custom fonts via Google Fonts URLs or local paths
- Font size, DPI, alignment (left/center/right)
- Color with hex (#RRGGBB) or RGBA values
- Text opacity (0.0-1.0)
- Stroke/outline with color and opacity
- Drop shadows with offset, color, and opacity
- Typography: kerning, line spacing, text wrapping
- Transform: rotation, gravity, positioning

### Other Endpoints

```bash
# Metadata
curl -X POST http://localhost:8081/demo/metadata \
  -F "image=@TestAssets/sample-photo.jpg" | jq

# Resize
curl -X POST http://localhost:8081/demo/resize \
  -F "image=@TestAssets/sample-photo.jpg" \
  -F "width=400" \
  -F "height=300" \
  -F "fit=inside" \
  -o resized.jpg

# Format conversion
curl -X POST http://localhost:8081/demo/convert \
  -F "image=@TestAssets/sample-photo.jpg" \
  -F "format=webp" \
  -F "quality=80" \
  -o converted.webp

# Composite/Watermark
curl -X POST http://localhost:8081/demo/composite \
  -F "baseImage=@TestAssets/sample-photo.jpg" \
  -F "overlayImage=@TestAssets/logo.png" \
  -F "x=10" \
  -F "y=10" \
  -F "opacity=0.8" \
  -F "mode=over" \
  -o watermarked.png
```

## Documentation

For full API documentation and usage examples, see:
- [Hokusai](https://github.com/ivantokar/hokusai) - Core image processing library
- [HokusaiVapor](https://github.com/ivantokar/hokusai-vapor) - Vapor integration

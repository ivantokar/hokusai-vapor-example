# Hokusai Vapor Example

A demo Vapor application showcasing [Hokusai](https://github.com/ivantokar/hokusai) and [HokusaiVapor](https://github.com/ivantokar/hokusai-vapor) features for server-side image processing.

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

- **Demo endpoints** for text overlay, resize, composite, and format conversion
- **Web UI** for interactive testing
- **Sample images** in TestAssets/
- **Test script** (`test-demo.sh`) for CLI testing
- **Docker configuration** for production deployment

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

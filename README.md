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

Open http://localhost:8080

## Run with Docker

```bash
docker compose up app
```

Open http://localhost:8080

## What's Included

- **Demo endpoints** for text overlay, resize, composite, and format conversion
- **Web UI** for interactive testing
- **Sample images** in TestAssets/
- **Test script** (`test-demo.sh`) for CLI testing
- **Docker configuration** for production deployment

## Testing Endpoints

Use the included test script:

```bash
./test-demo.sh
```

Or test manually with curl:

```bash
# Metadata
curl -X POST http://localhost:8080/demo/metadata \
  -F "image=@TestAssets/sample-photo.jpg" | jq

# Resize
curl -X POST http://localhost:8080/demo/resize \
  -F "image=@TestAssets/sample-photo.jpg" \
  -F "width=400" \
  -F "height=300" \
  -o resized.jpg

# Text overlay
curl -X POST http://localhost:8080/demo/text \
  -F "image=@TestAssets/sample-photo.jpg" \
  -F "text=Hello World" \
  -o with-text.jpg
```

## Documentation

For full API documentation and usage examples, see:
- [Hokusai](https://github.com/ivantokar/hokusai) - Core image processing library
- [HokusaiVapor](https://github.com/ivantokar/hokusai-vapor) - Vapor integration

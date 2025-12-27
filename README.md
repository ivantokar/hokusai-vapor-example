# Hokusai Vapor Example

A complete Vapor application demonstrating the [Hokusai](https://github.com/ivantokar/hokusai) hybrid image processing library with a modern web UI for testing features.

[![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![Vapor](https://img.shields.io/badge/Vapor-4.0+-blue.svg)](https://vapor.codes)
[![Platform](https://img.shields.io/badge/Platform-macOS%20|%20Linux-lightgrey.svg)](https://swift.org)

## Features

- 🎨 **Web UI** - Interactive forms for testing all image processing features
- ✍️ **Text Overlay** - Add text with custom fonts, strokes, and effects
- 📐 **Resize** - Multiple fit modes (fill, contain, cover)
- 🔄 **Format Conversion** - Convert between JPEG, PNG, WebP, AVIF, GIF
- ↻ **Rotate** - 90°, 180°, 270° rotations
- ℹ️ **Metadata** - Extract image information
- 🏆 **Certificate Generator** - Generate certificates with custom fonts
- 🐳 **Docker Ready** - Full Docker deployment with PostgreSQL

## Quick Start

### Prerequisites

**macOS:**
```bash
brew install vips imagemagick pkg-config
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install libvips-dev libmagick++-dev libmagickwand-dev pkg-config
```

### Run Locally

```bash
# Build and run
PKG_CONFIG_PATH=/opt/homebrew/lib/pkgconfig swift run

# Or just
swift run

# Open browser to http://localhost:8080
```

The web UI provides interactive forms for testing all features!

### Run with Docker

```bash
# From the workspace root directory
docker compose -f hokusai-vapor-example/docker-compose.yml build
docker compose -f hokusai-vapor-example/docker-compose.yml up app

# Run migrations
docker compose -f hokusai-vapor-example/docker-compose.yml run migrate

# Open browser to http://localhost:8080
```

## Web UI

The application includes a modern web interface at `http://localhost:8080` with interactive forms for:

### 1. Text Overlay
- Upload an image
- Enter text to overlay
- Customize font size and stroke width
- Download the result

### 2. Resize Image
- Upload an image
- Set target dimensions
- Choose fit mode (inside, cover, fill)
- Download resized image

### 3. Convert Format
- Upload an image
- Select output format (JPEG, PNG, WebP, AVIF, GIF)
- Set quality level
- Download converted image

### 4. Generate Certificate
- Enter recipient name
- Generates certificate with Passero One font
- Download personalized certificate

### 5. Rotate Image
- Upload an image
- Choose rotation (90°, 180°, 270°)
- Download rotated image

### 6. Image Info
- Upload an image
- Get metadata (dimensions, format, channels, alpha)
- View as JSON

## API Endpoints

All features are also available via REST API:

### Text Overlay
```bash
POST /demo/text
Content-Type: multipart/form-data

Fields:
- image (file)
- text (string)
- fontSize (int, optional)
- strokeWidth (double, optional)
```

### Resize
```bash
POST /demo/resize
Content-Type: multipart/form-data

Fields:
- image (file)
- width (int)
- height (int)
- fit (string: inside|cover|fill)
```

### Convert Format
```bash
POST /demo/convert
Content-Type: multipart/form-data

Fields:
- image (file)
- format (string: jpeg|png|webp|avif|gif)
- quality (int, optional)
```

### Generate Certificate
```bash
GET /demo/certificate?name=John%20Doe
```

### Rotate
```bash
POST /demo/rotate
Content-Type: multipart/form-data

Fields:
- image (file)
- angle (int: 90|180|270)
```

### Metadata
```bash
POST /demo/metadata
Content-Type: multipart/form-data

Fields:
- image (file)
```

## Using Private GitHub Repositories

This project uses private GitHub repositories for `hokusai` and `hokusai-vapor`. To access private repos:

### Setup SSH Keys

1. **Generate SSH key** (if you don't have one):
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

2. **Add SSH key to GitHub**:
```bash
# Copy public key
cat ~/.ssh/id_ed25519.pub

# Go to GitHub → Settings → SSH and GPG keys → New SSH key
# Paste the key
```

3. **Test SSH connection**:
```bash
ssh -T git@github.com
# Should see: "Hi username! You've successfully authenticated..."
```

### Package.swift Configuration

The Package.swift uses SSH URLs for private repos:

```swift
dependencies: [
    // Private repo using SSH URL
    .package(url: "git@github.com:ivantokar/hokusai-vapor.git", branch: "main"),
]
```

**For local development**, you can use path dependencies instead:

```swift
dependencies: [
    // Local development
    .package(path: "../hokusai-vapor"),
]
```

### Docker Build with Private Repos

For Docker builds, you need to forward SSH agent:

```dockerfile
# In Dockerfile, use SSH mount
RUN --mount=type=ssh swift package resolve
```

```bash
# Build with SSH forwarding
docker buildx build --ssh default .
```

**Alternative:** Use local path dependencies during Docker build by copying the local packages.

## Project Structure

```
hokusai-vapor-example/
├── Package.swift
├── Sources/
│   └── VaporVips/
│       ├── entrypoint.swift
│       ├── configure.swift
│       ├── routes.swift
│       └── Controllers/
│           ├── TodoController.swift
│           ├── CertificateController.swift
│           └── DemoController.swift          # Web UI form handlers
├── Resources/
│   └── Views/
│       └── index.leaf                        # Web UI template
├── Dockerfile
└── docker-compose.yml
```

## Development

### Run locally
```bash
swift run
```

### Build for release
```bash
swift build -c release
```

### Run tests
```bash
swift test
```

### Clean build
```bash
rm -rf .build
swift build
```

## Docker Deployment

### Build and Run
```bash
# From workspace root directory
# Build all services
docker compose -f hokusai-vapor-example/docker-compose.yml build

# Start app
docker compose -f hokusai-vapor-example/docker-compose.yml up app

# Run migrations
docker compose -f hokusai-vapor-example/docker-compose.yml run migrate

# View logs
docker compose -f hokusai-vapor-example/docker-compose.yml logs -f app

# Stop all services
docker compose -f hokusai-vapor-example/docker-compose.yml down
```

### Access the Application

- **Web UI:** http://localhost:8080
- **API:** http://localhost:8080/api/*
- **Health Check:** http://localhost:8080/hello
- **Version:** http://localhost:8080/vips/version

## Example Usage

### Using the Web UI

1. Open http://localhost:8080 in your browser
2. Select a feature card (Text Overlay, Resize, etc.)
3. Upload an image and configure options
4. Click the button to process
5. The processed image will download automatically

### Using curl

**Add text overlay:**
```bash
curl -X POST http://localhost:8080/demo/text \
  -F "image=@photo.jpg" \
  -F "text=Hello World" \
  -F "fontSize=64" \
  -F "strokeWidth=2" \
  -o text_overlay.jpg
```

**Resize image:**
```bash
curl -X POST http://localhost:8080/demo/resize \
  -F "image=@photo.jpg" \
  -F "width=800" \
  -F "height=600" \
  -F "fit=inside" \
  -o resized.jpg
```

**Convert format:**
```bash
curl -X POST http://localhost:8080/demo/convert \
  -F "image=@photo.jpg" \
  -F "format=webp" \
  -F "quality=80" \
  -o converted.webp
```

**Generate certificate:**
```bash
curl -X GET "http://localhost:8080/demo/certificate?name=John%20Doe" \
  -o certificate.png
```

**Rotate image:**
```bash
curl -X POST http://localhost:8080/demo/rotate \
  -F "image=@photo.jpg" \
  -F "angle=90" \
  -o rotated.jpg
```

**Get metadata:**
```bash
curl -X POST http://localhost:8080/demo/metadata \
  -F "image=@photo.jpg"
```

## Troubleshooting

### Private Repository Access

If you get authentication errors when building:

1. **Ensure SSH keys are configured:**
```bash
ssh -T git@github.com
```

2. **Use path dependencies for local development:**
```swift
// In Package.swift
.package(path: "../hokusai-vapor")
```

3. **For CI/CD**, use deploy keys or personal access tokens

### Font Issues

**Local development:**
- Configure font paths in `DemoController.swift` for your environment
- Example: Custom fonts can be placed in a `tmp/` directory

**Docker:**
- Fonts are installed in `/usr/share/fonts/custom/`
- Font cache is rebuilt with `fc-cache -f -v`

### Port Already in Use

If port 8080 is busy:

```bash
# Find process using port 8080
lsof -i :8080

# Kill the process
kill -9 <PID>

# Or change port in configure.swift
app.http.server.configuration.hostname = "0.0.0.0"
app.http.server.configuration.port = 8081
```

## Contributing

This is a demo application showcasing Hokusai capabilities. For contributions to the core library, see:
- [Hokusai](https://github.com/ivantokar/hokusai)
- [Hokusai Vapor](https://github.com/ivantokar/hokusai-vapor)

## License

MIT License

## Credits

- [Hokusai](https://github.com/ivantokar/hokusai) - Hybrid image processing
- [Vapor](https://vapor.codes) - Server-side Swift framework
- [libvips](https://libvips.github.io/libvips/) - Fast image processing
- [ImageMagick](https://imagemagick.org) - Advanced text rendering

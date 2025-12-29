#!/bin/bash

# Test script for Hokusai Vapor Example demo endpoints
# Usage: ./test-demo.sh

set -e

BASE_URL="${BASE_URL:-http://localhost:8080}"
TEST_IMAGE="${1:-TestAssets/sample-photo.jpg}"

if [ ! -f "$TEST_IMAGE" ]; then
    echo "Error: Test image not found: $TEST_IMAGE"
    echo "Make sure you run this from the hokusai-vapor-example directory"
    exit 1
fi

echo "Testing Hokusai Vapor Example API"
echo "Base URL: $BASE_URL"
echo "Test Image: $TEST_IMAGE"
echo "================================================"
echo ""

# Test 1: Get image metadata
echo "1. Testing metadata endpoint..."
curl -s -X POST "$BASE_URL/demo/metadata" \
  -F "image=@${TEST_IMAGE}" \
  | jq '.'
echo ""

# Test 2: Resize image
echo "2. Testing resize endpoint (400x300, cover)..."
curl -s -X POST "$BASE_URL/demo/resize" \
  -F "image=@${TEST_IMAGE}" \
  -F "width=400" \
  -F "height=300" \
  -F "fit=cover" \
  -o /tmp/hokusai-resized.jpg
echo "✓ Saved to /tmp/hokusai-resized.jpg"
ls -lh /tmp/hokusai-resized.jpg
echo ""

# Test 3: Text overlay
echo "3. Testing text overlay endpoint..."
curl -s -X POST "$BASE_URL/demo/text" \
  -F "image=@${TEST_IMAGE}" \
  -F "text=Hokusai Test" \
  -F "fontUrl=https://fonts.gstatic.com/s/roboto/v30/KFOmCnqEu92Fr1Me5Q.ttf" \
  -F "fontSize=48" \
  -F "strokeWidth=2" \
  -o /tmp/hokusai-text.jpg
echo "✓ Saved to /tmp/hokusai-text.jpg"
ls -lh /tmp/hokusai-text.jpg
echo ""

# Test 4: Rotate image
echo "4. Testing rotate endpoint (90 degrees)..."
curl -s -X POST "$BASE_URL/demo/rotate" \
  -F "image=@${TEST_IMAGE}" \
  -F "angle=90" \
  -o /tmp/hokusai-rotated.jpg
echo "✓ Saved to /tmp/hokusai-rotated.jpg"
ls -lh /tmp/hokusai-rotated.jpg
echo ""

# Test 5: Convert format
echo "5. Testing convert endpoint (JPEG → WebP)..."
curl -s -X POST "$BASE_URL/demo/convert" \
  -F "image=@${TEST_IMAGE}" \
  -F "format=webp" \
  -F "quality=85" \
  -o /tmp/hokusai-converted.webp
echo "✓ Saved to /tmp/hokusai-converted.webp"
ls -lh /tmp/hokusai-converted.webp
echo ""

# Test 6: Template text
echo "6. Testing template text..."
curl -s -X POST "$BASE_URL/demo/text" \
  -F "useTemplate=true" \
  -F "text=Test User" \
  -F "fontUrl=https://fonts.gstatic.com/s/roboto/v30/KFOmCnqEu92Fr1Me5Q.ttf" \
  -F "fontSize=96" \
  -F "strokeWidth=2" \
  -F "color=0,0,128,255" \
  -F "strokeColor=255,255,255,255" \
  -F "position=center" \
  -o /tmp/hokusai-template-text.png
echo "✓ Saved to /tmp/hokusai-template-text.png"
ls -lh /tmp/hokusai-template-text.png
echo ""

echo "================================================"
echo "All tests completed successfully!"
echo ""
echo "Output files saved in /tmp/:"
echo "  - hokusai-resized.jpg      (resized image)"
echo "  - hokusai-text.jpg         (text overlay)"
echo "  - hokusai-rotated.jpg      (rotated 90°)"
echo "  - hokusai-converted.webp   (format conversion)"
echo "  - hokusai-template-text.png  (template text)"
echo ""
echo "To view results:"
echo "  open /tmp/hokusai-*.{jpg,png,webp}"

# ================================
# Build image
# ================================
FROM swift:6.1-noble AS build

# Install OS updates
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install -y \
      libjemalloc-dev \
      libvips-dev \
      libmagick++-dev \
      libmagickwand-dev \
      pkg-config

# Create pkg-config symlinks for ImageMagick compatibility
RUN ln -s /usr/lib/$(uname -m)-linux-gnu/pkgconfig/MagickWand-6.Q16.pc /usr/lib/$(uname -m)-linux-gnu/pkgconfig/MagickWand.pc || true

# Set up a build area
WORKDIR /build/vapor-vips

# First just resolve dependencies.
# This creates a cached layer that can be reused
# as long as your Package.swift/Package.resolved
# files do not change.
COPY vapor-vips/Package.* ./
COPY hokusai ../hokusai
COPY hokusai-vapor ../hokusai-vapor
RUN swift package resolve \
        $([ -f ./Package.resolved ] && echo "--force-resolved-versions" || true)

# Copy the Vapor app sources into the build area
COPY vapor-vips/. .

RUN mkdir /staging

# Build the application, with optimizations, with static linking, and using jemalloc
# N.B.: The static version of jemalloc is incompatible with the static Swift runtime.
RUN --mount=type=cache,target=/build/vapor-vips/.build \
    set -eux; \
    swift build -c release -v \
        --product VaporVips \
        --static-swift-stdlib \
        -Xlinker -ljemalloc; \
    BIN_PATH="$(swift build -c release --show-bin-path)"; \
    cp "${BIN_PATH}/VaporVips" /staging; \
    find -L "${BIN_PATH}" -regex '.*\.resources$' -exec cp -Ra {} /staging \;


# Switch to the staging area
WORKDIR /staging

# Copy static swift backtracer binary to staging area
RUN cp "/usr/libexec/swift/linux/swift-backtrace-static" ./

# Copy any resources from the public directory and views directory if the directories exist
# Ensure that by default, neither the directory nor any of its contents are writable.
RUN [ -d /build/vapor-vips/Public ] && { mv /build/vapor-vips/Public ./Public && chmod -R a-w ./Public; } || true
RUN [ -d /build/vapor-vips/Resources ] && { mv /build/vapor-vips/Resources ./Resources && chmod -R a-w ./Resources; } || true

# ================================
# Run image
# ================================
FROM ubuntu:noble

# Make sure all system packages are up to date, and install only essential packages.
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get -q install -y \
      libjemalloc2 \
      ca-certificates \
      tzdata \
      libvips \
      libpango-1.0-0 \
      libpangocairo-1.0-0 \
      libpangoft2-1.0-0 \
      fonts-dejavu-core \
      libmagickcore-6.q16-7 \
      libmagickwand-6.q16-7 \
      fonts-liberation \
      fontconfig \
    && rm -r /var/lib/apt/lists/*

# Copy test assets (certificate template, sample images, watermarks)
RUN mkdir -p /app/TestAssets
COPY hokusai-vapor-example/TestAssets /app/TestAssets

# If your app or its dependencies import FoundationNetworking, also install `libcurl4`.
# If your app or its dependencies import FoundationXML, also install `libxml2`.

# Create a vapor user and group with /app as its home directory
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor

# Switch to the new home directory
WORKDIR /app

# Copy built executable and any staged resources from builder
COPY --from=build --chown=vapor:vapor /staging /app

# Provide configuration needed by the built-in crash reporter and some sensible default behaviors.
ENV SWIFT_BACKTRACE=enable=yes,sanitize=yes,threads=all,images=all,interactive=no,swift-backtrace=./swift-backtrace-static

# Ensure all further commands run as the vapor user
USER vapor:vapor

# Let Docker bind to port 8080
EXPOSE 8080

# Start the Vapor service when the image is run, default to listening on 8080 in production environment
ENTRYPOINT ["./VaporVips"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]

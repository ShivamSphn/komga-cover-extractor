# Set ARG for Python version
ARG PYTHON_VERSION=3.13

# Builder stage
FROM python:${PYTHON_VERSION}-slim-bookworm AS builder

# Add build-time metadata
ARG BUILD_DATE
LABEL org.opencontainers.image.source="https://github.com/riya/komga-cover-extractor" \
      org.opencontainers.image.description="Komga Cover Extractor Builder Stage" \
      org.opencontainers.image.created="${BUILD_DATE}"

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set the working directory
WORKDIR /build

# Copy only dependency files first to leverage caching
COPY pyproject.toml uv.lock ./

# Install dependencies
ENV UV_COMPILE_BYTECODE=1
RUN uv sync --frozen

# Copy the rest of the application
COPY . .

# Final stage
FROM python:${PYTHON_VERSION}-slim-bookworm

# Security configurations
ENV PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DEBIAN_FRONTEND=noninteractive

# Add runtime metadata
ARG BUILD_DATE
LABEL maintainer="riya" \
      org.opencontainers.image.title="Komga Cover Extractor" \
      org.opencontainers.image.description="Tool to extract and process covers for Komga" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="1.0.0"

# Create a new user
RUN useradd -m appuser

# Set default environment variables
ARG PUID=1000
ARG PGID=1000
ENV PYTHONUNBUFFERED=1
ENV UMASK=022

# Set ownership
RUN groupmod -o -g "$PGID" appuser && \
    usermod -o -u "$PUID" appuser && \
    umask "$UMASK"

# Add non-free repository
RUN echo "deb http://deb.debian.org/debian bullseye non-free" >> /etc/apt/sources.list

# Set timezone handling
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install runtime dependencies with specific versions
RUN apt-get update && apt-get install -y --no-install-recommends \
    unrar \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Set working directory with proper permissions
WORKDIR /app
RUN chown appuser:appuser /app && chmod 755 /app

# Define volume mount points
VOLUME ["/app/config", "/app/data"]

# Copy installed packages and application from builder
COPY --from=builder /build /app
COPY --from=builder /usr/local/lib/python${PYTHON_VERSION}/site-packages /usr/local/lib/python${PYTHON_VERSION}/site-packages

# Set secure permissions
RUN find /app -type d -exec chmod 755 {} \; && \
    find /app -type f -exec chmod 644 {} \; && \
    chmod 755 /app/start.sh

# Set correct ownership
RUN chown -R appuser:appuser /app

# Handle optional features
ARG MANGA_ISBN
RUN if [ "$MANGA_ISBN" = "true" ]; then \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        xdg-utils \
        xz-utils \
        libopengl0 \
        libegl1 \
        libxcb-cursor0 \
        libicu-dev \
        pkg-config \
        python3-icu \
        python3-pyqt5 \
        tesseract-ocr && \
    wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sh /dev/stdin && \
    apt-get install -y /app/addons/manga_isbn/chrome/google-chrome-stable_current_amd64.deb && \
    pip3 install --no-cache-dir -r /app/addons/manga_isbn/requirements.txt && \
    pip3 install /app/addons/manga_isbn/python-anilist-1.0.9/. && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*; \
    fi

ARG EPUB_CONVERTER
RUN if [ "$EPUB_CONVERTER" = "true" ]; then \
    apt-get update && \
    apt-get install -y --no-install-recommends zip && \
    pip3 install --no-cache-dir -r /app/addons/epub_converter/requirements.txt && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*; \
    fi

# Make start.sh executable
RUN chmod +x start.sh

# Switch to appuser
USER appuser

# Run start script
CMD ["./start.sh"]

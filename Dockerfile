# Use a specific version of the Python image
FROM python:3.13-slim-bookworm
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set the working directory to /app
WORKDIR /app
# Create a new user called "appuser"
RUN useradd -m appuser

# Set the default environment variables
ARG PUID=1000
ARG PGID=1000

# Set the PYTHONUNBUFFERED environment variable to avoid partial output in logs
ENV PYTHONUNBUFFERED=1
ENV UV_COMPILE_BYTECODE=1
# Add non-free to sources.list
RUN echo "deb http://deb.debian.org/debian bullseye non-free" >> /etc/apt/sources.list

# Set ownership to appuser and switch to "appuser"
RUN groupmod -o -g "$PGID" appuser && usermod -o -u "$PUID" appuser

# Allow users to specify UMASK (default value is 022)
ENV UMASK=022
RUN umask "$UMASK"

# Copy the current directory contents into the container at /app
COPY --chown=appuser:appuser . .

# Install necessary packages and requirements for the main script
RUN apt-get update
RUN apt-get install -y unrar tzdata nano
RUN apt-get install -y build-essential
RUN uv sync --frozen
# # Install the optional addon feature manga_isbn if true
ARG MANGA_ISBN
RUN if [ "$MANGA_ISBN" = "true" ]; then \
    apt-get update && \
    apt-get install -y wget && \
    apt-get install -y build-essential && \
    apt-get install -y xdg-utils xz-utils libopengl0 libegl1 libxcb-cursor0 && \
    wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sh /dev/stdin && \
    apt-get install -y libicu-dev pkg-config python3-icu && \
    apt-get install -y /app/addons/manga_isbn/chrome/google-chrome-stable_current_amd64.deb && \
    apt-get install -y python3-pyqt5 && \
    apt-get -y install tesseract-ocr && \
    pip3 install --no-cache-dir -r /app/addons/manga_isbn/requirements.txt && \
    pip3 install /app/addons/manga_isbn/python-anilist-1.0.9/.; \
    fi

# # Install the optional addon feature epub_converter if true
ARG EPUB_CONVERTER
RUN if [ "$EPUB_CONVERTER" = "true" ]; then \
    apt-get install -y zip && \
    pip3 install --no-cache-dir -r /app/addons/epub_converter/requirements.txt; \
    fi

# Remove unnecessary packages and clean up
RUN apt-get autoremove -y
RUN rm -rf /var/lib/apt/lists/*

# Make start.sh executable
RUN chmod +x start.sh

# Switch to "appuser"
USER appuser

# Run start.sh which handles environment variable display and script execution
CMD ["./start.sh"]

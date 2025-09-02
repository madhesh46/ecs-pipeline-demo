# Start from scratch (minimal)
FROM python:3.11-alpine

# Set working directory
WORKDIR /app

# Copy your HTML file
COPY index.html .

# Expose port
EXPOSE 80

# Run a simple HTTP server
CMD ["python3", "-m", "http.server", "80"]
# Start from scratch (minimal)
FROM python:3.11-alpine

# Set working directory
WORKDIR /app

# Copy your HTML file
COPY index.html .

# Expose port
EXPOSE 80

# Run a simple HTTP server
CMD ["python3", "-m", "http.server", "80"]


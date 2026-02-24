FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements from the backend folder
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Pre-download MiDaS models during build phase to avoid startup timeouts
RUN python -c "import torch; torch.hub.load('intel-isl/MiDaS', 'MiDaS_small'); torch.hub.load('intel-isl/MiDaS', 'transforms')"

# Copy all files from the backend folder
COPY backend/ .

EXPOSE 8080

# Use the PORT environment variable provided by Cloud Run
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT:-8080}

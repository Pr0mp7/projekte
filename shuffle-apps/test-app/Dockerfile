# Use Python base image instead
FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install shuffle-sdk from source (since 0.0.25 might not be on PyPI)
RUN pip3 install git+https://github.com/Shuffle/app_sdk.git@0.0.25 || \
    pip3 install git+https://github.com/Shuffle/app_sdk.git

# Install additional requirements
COPY requirements.txt /app/requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy app source code
COPY src/ /app/src/
COPY api.yaml /app/

# Set environment variables
ENV PYTHONPATH=/app/src

# Make sure the app script is executable
RUN chmod +x /app/src/app.py

CMD ["python3", "/app/src/app.py"]

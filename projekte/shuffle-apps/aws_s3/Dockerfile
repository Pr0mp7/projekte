# For airgapped environment - use your local registry
ARG LOCAL_REGISTRY=your-registry.local:5000
FROM ${LOCAL_REGISTRY}/shuffle/app_sdk:0.0.25 AS base

FROM base
WORKDIR /app

# Install shuffle_sdk first
RUN pip3 install --no-cache-dir shuffle_sdk==0.0.18

# Install boto3 and dependencies without version conflicts
RUN pip3 install --no-cache-dir --no-deps \
    boto3==1.26.137 \
    botocore==1.29.137 \
    s3transfer==0.6.1 \
    jmespath==1.0.1 \
    python-dateutil==2.8.2 \
    six==1.16.0

# Copy app source code
COPY src /app

# No import fixes needed since we're writing it correctly from the start

CMD ["python", "app.py", "--log-level", "DEBUG"]
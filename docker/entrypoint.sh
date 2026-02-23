#!/bin/bash
set -e

# Activate conda environment
source /opt/conda/etc/profile.d/conda.sh
conda activate maxlab

# Use environment variables with defaults
PORT=${JUPYTER_PORT:-8888}
NOTEBOOK_DIR=${JUPYTER_NOTEBOOK_DIR:-/home/maxlab/workspace}

echo "Starting JupyterLab on port ${PORT}..."
echo "Notebook directory: ${NOTEBOOK_DIR}"

# Start JupyterLab
exec jupyter lab \
    --ip=0.0.0.0 \
    --port=${PORT} \
    --notebook-dir=${NOTEBOOK_DIR} \
    --ServerApp.allow_remote_access=True \
    --ServerApp.allow_origin="*" \
    --ServerApp.trust_xheaders=True \
    --ServerApp.token='' \
    --ServerApp.password='' \
    --ServerApp.base_url="/" \
    --no-browser

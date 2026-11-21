# MaxLab Docker Image
# JupyterLab-based data science environment

FROM continuumio/miniconda3:latest

LABEL maintainer="MaxLab"
LABEL description="MaxLab - JupyterLab data science environment"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV CONDA_ENV=maxlab
ENV JUPYTER_PORT=8888
ENV JUPYTER_NOTEBOOK_DIR=/home/maxlab/workspace

# Create non-root user
RUN useradd -m -s /bin/bash maxlab && \
    mkdir -p /home/maxlab/workspace && \
    chown -R maxlab:maxlab /home/maxlab

# Install git and GitHub CLI (system-wide)
RUN apt-get update && \
    apt-get install -y --no-install-recommends git curl ca-certificates && \
    mkdir -p -m 755 /etc/apt/keyrings && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends gh && \
    rm -rf /var/lib/apt/lists/*

# Configure conda and create environment
RUN conda config --add channels conda-forge && \
    conda config --set channel_priority strict && \
    conda create -n ${CONDA_ENV} python=3.12 -y && \
    conda clean -afy

# Install packages in the maxlab environment
RUN conda run -n ${CONDA_ENV} conda install -y \
    jupyterlab \
    pandas \
    numpy \
    scipy \
    matplotlib \
    seaborn \
    scikit-learn \
    ipykernel \
    python-dotenv \
    && conda clean -afy

# Preinstall JupyterLab extensions (PyPI search in the Extension Manager no longer works,
# so extensions are added here instead of via the UI)
RUN conda run -n ${CONDA_ENV} python -m pip install --no-cache-dir \
    jupyterlab-git \
    jupyterlab-lsp \
    "python-lsp-server[all]" \
    jupyterlab_code_formatter \
    black \
    isort

# Install the bundled MaxLab JupyterLab themes and branding extensions
COPY packages/maxlab_navigator_theme /tmp/maxlab_navigator_theme
RUN conda run -n ${CONDA_ENV} python -m pip install /tmp/maxlab_navigator_theme && \
    rm -rf /tmp/maxlab_navigator_theme

# Default JupyterLab to the bundled MaxLab dark theme on startup
COPY docker/jupyter_lab_settings/overrides.json /tmp/maxlab-jupyter-overrides.json
RUN mkdir -p /opt/conda/envs/${CONDA_ENV}/share/jupyter/lab/settings && \
    cp /tmp/maxlab-jupyter-overrides.json /opt/conda/envs/${CONDA_ENV}/share/jupyter/lab/settings/overrides.json && \
    rm /tmp/maxlab-jupyter-overrides.json

# Register the Jupyter kernel
RUN conda run -n ${CONDA_ENV} python -m ipykernel install \
    --sys-prefix \
    --name ${CONDA_ENV} \
    --display-name "Python (maxlab)"

# Copy entrypoint script
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to non-root user
USER maxlab
WORKDIR /home/maxlab

# Expose JupyterLab port
EXPOSE ${JUPYTER_PORT}

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]

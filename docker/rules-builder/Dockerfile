FROM python:3.11-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends git \
 && rm -rf /var/lib/apt/lists/* \
 && pip install --no-cache-dir sigma-cli pysigma-backend-sqlite pysigma-pipeline-sysmon pysigma-pipeline-windows

# Sources de règles (clonées au build ; --no-cache pour les mettre à jour)
RUN git clone --depth 1 https://github.com/SigmaHQ/sigma.git /src/sigma \
 && git clone --depth 1 https://github.com/mdecrevoisier/SIGMA-detection-rules.git /src/mdecrevoisier

COPY entrypoint.sh merge.py /build/
RUN sed -i 's/\r$//' /build/entrypoint.sh && chmod +x /build/entrypoint.sh

ENTRYPOINT ["/build/entrypoint.sh"]

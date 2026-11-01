FROM python:3.11-slim

# Version testée. Pour une autre : docker build --build-arg ZIRCOLITE_REF=<tag ou branche> ...
ARG ZIRCOLITE_REF=v4.7.0
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends git build-essential \
 && git clone --depth 1 --branch "${ZIRCOLITE_REF}" https://github.com/wagga40/Zircolite.git /opt/Zircolite \
 && cd /opt/Zircolite \
 && python -c "import tomllib; print('\n'.join(d for d in tomllib.load(open('pyproject.toml','rb'))['project']['dependencies'] if not d.startswith('pysigma-pipeline-')))" > /tmp/deps.txt \
 && pip install --no-cache-dir -r /tmp/deps.txt \
 && pip install --no-cache-dir --no-deps "pysigma-pipeline-sysmon>=2.0.0" "pysigma-pipeline-windows>=2.0.0" \
 && apt-get purge -y build-essential && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/* /opt/Zircolite/.git

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh && chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /opt/Zircolite
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

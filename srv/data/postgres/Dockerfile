FROM postgis/postgis:18-3.6

# Install pgvector extension
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    postgresql-server-dev-18 \
    && git clone --branch v0.5.1 https://github.com/pgvector/pgvector.git /tmp/pgvector \
    && cd /tmp/pgvector \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/pgvector \
    && apt-get purge -y --auto-remove build-essential git \
    && rm -rf /var/lib/apt/lists/*


FROM postgis/postgis:16-3.4-alpine

# Install pgvector extension
RUN apk add --no-cache \
    build-base \
    git \
    postgresql-dev \
    musl-dev \
    && git clone --branch v0.5.1 https://github.com/pgvector/pgvector.git /tmp/pgvector \
    && cd /tmp/pgvector \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/pgvector \
    && apk del build-base git musl-dev


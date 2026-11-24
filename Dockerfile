FROM ghcr.io/astral-sh/uv:0.13.9 AS uv

FROM ghcr.io/actions/actions-runner:2.338.2

ARG GH_VERSION=2.105.0
ARG NODE_VERSION=26.13.1

USER root
# Node needs libatomic, which the base image lacks.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libatomic1 \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" \
      | tar -xz -C /usr/local --strip-components=1 "gh_${GH_VERSION}_linux_amd64/bin/gh" \
    && curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz" \
      | tar -xz -C /usr/local --strip-components=1 --wildcards '*/bin' '*/lib' '*/include' '*/share'
COPY --from=uv /uv /uvx /usr/local/bin/
COPY --chmod=755 start.sh /usr/local/bin/start-runner

USER runner
ENTRYPOINT ["/usr/local/bin/start-runner"]

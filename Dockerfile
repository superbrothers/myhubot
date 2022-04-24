FROM docker.io/node:16

ARG TARGETARCH

WORKDIR /app

COPY package.* .

RUN set -x && \
    npm install --production

COPY . .

RUN set -x && \
    wget -O /tmp/dumb-init.deb "https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_${TARGETARCH}.deb" && \
    dpkg -i /tmp/dumb-init.deb && \
    rm /tmp/dumb-init.deb

USER 65534

ENTRYPOINT ["dumb-init"]
CMD ["bin/hubot", "-a", "slack"]

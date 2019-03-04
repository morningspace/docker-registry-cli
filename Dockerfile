FROM docker:dind

LABEL maintainer="morningspace@yahoo.com"

RUN apk add --no-cache bash curl jq

WORKDIR /root

COPY lib README.md LICENSE ./

RUN ln -s $HOME/bin/reg-cli.sh /usr/local/bin/reg-cli

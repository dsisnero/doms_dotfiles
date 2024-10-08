FROM alpine:edge

LABEL maintainer="dsisnero@gmail.com"

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories

RUN apk update && \
    apk upgrade
RUN apk add --no-cache \
    curl \
    gcc \
    zsh \
    tmux \
    perl \
    sudo \
    git \
    build-base \
    ruby \
    ruby-dev \
    linux-headers \
    musl-dev\
    neovim \
    python-dev \
    py-pip \
    python3-dev \
    py3-pip && \
    rm -rf /var/cache/apk/*

ENV LANG="ja_JP.UTF-8" LANGUAGE="ja_JP:ja" LC_ALL="ja_JP.UTF-8"

RUN pip3 install --upgrade pip neovim && \
    gem install neovim colorls

WORKDIR /usr/src/nvim

ENTRYPOINT ["nvim"]

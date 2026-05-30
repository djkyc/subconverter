# 第一阶段：构建环境 (Ubuntu 22.04)
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# 可选：使用阿里云镜像源（多架构支持较好）
RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list

# 安装编译依赖，移除可能出问题的 pcre2-utils，只保留 libpcre2-dev
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    cmake \
    g++ \
    make \
    pkg-config \
    libssl-dev \
    libpcre3-dev \
    libpcre2-dev \
    zlib1g-dev \
    libcurl4-openssl-dev \
    libyaml-cpp-dev \
    rapidjson-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 安装 toml11
RUN git clone --depth 1 https://github.com/ToruNiina/toml11.git /tmp/toml11 && \
    cd /tmp/toml11 && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make install && \
    rm -rf /tmp/toml11

WORKDIR /app

# 克隆上游源码（包含子模块）
RUN git clone --recursive https://github.com/asdlokj1qpi233/subconverter.git .

# 编译
RUN cmake . && make -j2

# 第二阶段：运行时
FROM alpine:latest

RUN apk add --no-cache \
    ca-certificates \
    libssl3 \
    pcre2 \
    libcurl \
    yaml-cpp \
    tzdata

WORKDIR /subconverter

COPY --from=builder /app/subconverter .
COPY --from=builder /app/base ./base
COPY --from=builder /app/config ./config
COPY --from=builder /app/generate.ini ./generate.ini

EXPOSE 25500
ENTRYPOINT ["./subconverter"]

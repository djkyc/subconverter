# 使用 Ubuntu 22.04 作为基础构建镜像，提供稳定且完整的编译环境
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# 更换为国内源，加速 apt 下载（可选）
RUN sed -i 's/archive.ubuntu.com/mirrors.tencent.com/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.tencent.com/g' /etc/apt/sources.list

# 安装编译依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    cmake \
    g++ \
    make \
    pkg-config \
    libssl-dev \
    libpcre3-dev \
    pcre2-utils \
    libpcre2-dev \
    zlib1g-dev \
    libcurl4-openssl-dev \
    libyaml-cpp-dev \
    rapidjson-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 安装 toml11 (从源码编译以确保生成 cmake 配置文件)
RUN git clone --depth 1 https://github.com/ToruNiina/toml11.git /tmp/toml11 && \
    cd /tmp/toml11 && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make install && \
    rm -rf /tmp/toml11

WORKDIR /app

# 克隆上游源码（这里使用 --recursive 以包含所有子模块）
RUN git clone --recursive https://github.com/asdlokj1qpi233/subconverter.git .

# 编译项目，限制并发数以防 OOM
RUN cmake . && make -j2

# 最终运行镜像
FROM alpine:latest

# 安装运行时依赖
RUN apk add --no-cache \
    ca-certificates \
    libssl3 \
    pcre2 \
    libcurl \
    yaml-cpp \
    tzdata

WORKDIR /subconverter

# 从构建阶段复制二进制文件和必要的配置目录
COPY --from=builder /app/subconverter .
COPY --from=builder /app/base ./base
COPY --from=builder /app/config ./config
COPY --from=builder /app/generate.ini ./generate.ini

EXPOSE 25500
ENTRYPOINT ["./subconverter"]

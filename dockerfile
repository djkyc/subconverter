# 第一阶段：构建环境 (Ubuntu 22.04)
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# 使用阿里云镜像源（对多架构支持较好），并更新
RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    apt-get update

# 分批安装依赖，避免单次 RUN 时间过长被取消
RUN apt-get install -y --no-install-recommends \
    git ca-certificates && \
    apt-get install -y --no-install-recommends \
    cmake g++ make pkg-config && \
    apt-get install -y --no-install-recommends \
    libssl-dev libpcre3-dev libpcre2-dev zlib1g-dev \
    libcurl4-openssl-dev libyaml-cpp-dev rapidjson-dev && \
    rm -rf /var/lib/apt/lists/*

# 编译安装 toml11 (生成 CMake 配置文件)
RUN git clone --depth 1 https://github.com/ToruNiina/toml11.git /tmp/toml11 && \
    cd /tmp/toml11 && mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make install && rm -rf /tmp/toml11

# 编译安装 QuickJS (因为 Ubuntu 仓库没有提供 libquickjs-dev)
RUN git clone --depth 1 https://github.com/bellard/quickjs.git /tmp/quickjs && \
    cd /tmp/quickjs && \
    make -j2 && \
    make install && \
    rm -rf /tmp/quickjs

WORKDIR /app

# 克隆上游源码（包含子模块）
RUN git clone --recursive https://github.com/asdlokj1qpi233/subconverter.git .

# 编译项目（限制并发为 1 或 2，防止 QEMU OOM）
RUN cmake . && make -j1

# 第二阶段：运行时 (Alpine)
FROM alpine:latest

# 安装运行时动态库（QuickJS 运行时不需要额外库）
RUN apk add --no-cache \
    ca-certificates \
    libssl3 \
    pcre2 \
    libcurl \
    yaml-cpp \
    tzdata

WORKDIR /subconverter

# 复制编译产物和配置目录
COPY --from=builder /app/subconverter .
COPY --from=builder /app/base ./base
COPY --from=builder /app/config ./config
COPY --from=builder /app/generate.ini ./generate.ini

# 复制 QuickJS 运行时库（Alpine 阶段没有编译 QuickJS，但二进制可能动态链接）
# 实际上 quickjs 编译安装的库在 /usr/local/lib，需要复制过来
COPY --from=builder /usr/local/lib/libquickjs.so* /usr/local/lib/
RUN apk add --no-cache libgcc libstdc++  # 可能需要的 C++ 运行时

EXPOSE 25500
ENTRYPOINT ["./subconverter"]

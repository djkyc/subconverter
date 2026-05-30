# 第一阶段：构建环境
FROM ubuntu:22.04 AS builder

LABEL maintainer="your-email@example.com"

# 更换 apt 源为国内源，加快构建速度（可选）
RUN sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list

# 安装编译所需工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    cmake \
    build-essential \
    libssl-dev \
    libpcre3-dev \
    zlib1g-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 克隆你想打包的项目
RUN git clone https://github.com/asdlokj1qpi233/subconverter.git .

# 执行编译
RUN cd subconverter \
    && cmake . \
    && make -j$(nproc)

# 第二阶段：运行环境
FROM ubuntu:22.04

# 更换 apt 源（可选，保持与第一阶段一致）
RUN sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list

# 安装运行时动态库依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libssl-dev \
    libpcre3-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# 从 builder 阶段复制编译好的产物
COPY --from=builder /app/subconverter /subconverter

WORKDIR /subconverter

# 直接运行主程序（subconverter）
ENTRYPOINT ["./subconverter"]

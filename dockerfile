# 直接使用上游官方镜像，不进行任何编译
FROM asdlokj1qpi23/subconverter:latest

# 如需添加自定义配置文件，可以在这里 COPY
# COPY my-config.toml /subconverter/

EXPOSE 25500

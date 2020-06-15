# 构建好的centsos+jdK镜像，为测试方便，使用的是本地镜像，而不是docker公有的【私服/公服】仓库
FROM gyt_jdk1.8_base:latest
MAINTAINER smy<dsgl_blue@aliyun.com>

ENV TZ "Asia/Shanghai"
#ENV ACTIVE_PROFILE local
ENV DOCKER_HOST_IP 127.0.0.1
ENV JVM_XMS 128m
ENV JVM_XMX 256m
ENV JVM_XMN 48m
ENV APP_FILE_NAME vhr.jar

# 创建JVM垃圾回收日志目录
RUN mkdir -p /root/logs/java/ \
    && mkdir -p /opt/app/
# 将需要在容器内部跑的脚步放进去
ADD start.sh /opt/app
ADD setenv.sh /opt/app/
RUN chmod u+x /opt/app/*.sh
ADD ${APP_FILE_NAME} /opt/app/
ENV ENV_APP_FILE_PATH=/opt/app/${APP_FILE_NAME}

#SpringBoot项目端口暴露到宿主机
EXPOSE 8069
#容器启动命令的目录
WORKDIR /opt/app/
# 启动docker容器
ENTRYPOINT ["/opt/app/start.sh"]
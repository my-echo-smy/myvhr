#!/bin/sh
# 清除docker容器的脚本，路径都是容器内部的
#删除未被挂载点卷
docker volume prune
#删除所有停止运行的容器
docker container prune
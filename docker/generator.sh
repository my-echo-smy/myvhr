#!/bin/bash
# @Desc 此脚本用于获取一个新的user容器
# @Author dsg_blue <dsg_blue@aliyun.com>
PROJECT_PORT=`sh random_port.sh`
docker run -d -p "$PROJECT_PORT":8069 vhr
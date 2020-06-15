#!/bin/bash
# @Desc 此脚本用于获取一个指定区间且未被占用的随机端口号
# @Author dsg_blue <dsg_blue@aliyun.com>

PORT=0
#判断当前端口是否被占用，没被占用返回0，反之1
function Listening() {
  TCPListeningnum=$(netstat -an | grep ":$1 " | awk '$1 == "tcp" && $NF == "LISTEN" {print $0}' | wc -l)
  UDPListeningnum=$(netstat -an | grep ":$1 " | awk '$1 == "udp" && $NF == "0.0.0.0:*" {print $0}' | wc -l)
  ((Listeningnum = TCPListeningnum + UDPListeningnum))
  if [ $Listeningnum == 0 ]; then
    echo "0"
  else
    echo "1"
  fi
}

#指定区间随机数
function random_range() {
  shuf -i $1-$2 -n1
}

#得到随机端口
function get_random_port() {
  templ=0
  while [ $PORT == 0 ]; do
    temp1=$(random_range $1 $2)
    if [ $(Listening $temp1) == 0 ]; then
      PORT=$temp1
    fi
  done
  echo "$PORT"
}
# 限定返回的端口范围，此端口范围对应阿里云的安全组开放的端口范围
#get_random_port 29000 30000

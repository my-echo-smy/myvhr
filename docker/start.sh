#!/bin/sh
# 该脚本是dockerfile构建容器后运行的shell脚本，路径都是容器内部的
if [ -r /opt/app/setenv.sh ]; then
  . /opt/app/setenv.sh
fi
#查看jar包是否正常
which java
java -version
echo 'ENV_APP_FILE_PATH IS ' $ENV_APP_FILE_PATH
exec java -jar $CATALINA_OPTS $ENV_APP_FILE_PATH
exec rm -rf $APP_FILE_NAME
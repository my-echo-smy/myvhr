#!/bin/bash
# @Desc java Spring Boot打包shell，集成了docker镜像及容器操作，QA测试分支部署
# @Author dsg_blue <dsg_blue@aliyun.com>
PROJECT_VERSION=0.0.1-SNAPSHOT.jar
PROJECT_NAME=spring_cloud_user
PROJECT_HOME=$PROJECT_ROOT/$PROJECT_NAME
DOCKER_BUILD_HOME=$PROJECT_HOME/docker
PROJECT_JAR=$PROJECT_HOME/core/target/core-$PROJECT_VERSION
# 定义分隔符为换行符
IFS=$'\n'
# 部署
function packageJar() {
  branch=QA
  echo "分支：${branch}进行部署"
  cd $PROJECT_HOME
  query=0
  #3.查看本地是否有切好了的分支，如果有，不需要新切分支
  for loc in $(git branch | sed 's/^.\{2\}//'); do
    if [ $(basename $branch) = $loc ]; then
      query=1
      break
    fi
  done
  if [ $query -eq 0 ]; then
    echo "本地没有这个分支"
    git checkout -b $(basename $branch) $branch
  else
    curBranch=$(git branch | grep "*" | sed -n -e '1p' -e 's/^.\{2\}//')
    if [ $curBranch = $(basename $branch) ]; then
      echo "当前分支，直接更新"
    else
      echo "本地分支，直接checkout成本地新分支"
      git checkout $(basename $branch)
    fi
    echo '拉取最新项目代码'
    git pull
  fi
  #4.部署分支的项目
  echo "=======================mvn install start======================="
  mvn -U clean install  -Dmaven.test.skip=true -P qa
  echo "======================= mvn install end ======================="
  #5.将jar包位置移动到和dockerfile一样的目录
  DEPLOY_JAR="$PROJECT_NAME".jar
  # 更名，去掉jar包版本号
  mv $PROJECT_JAR $DEPLOY_JAR
  mv $DEPLOY_JAR $(pwd)/docker
  echo "MV将jar包位置移动到和dockerfile一样的目录: "$(pwd)/docker
}
# 定义镜像版本
IMAGE_NAME=user_qa
function initdockerImage() {
  # 移除原来的镜像
  echo '=======================停止并且移除旧的容器====================='
  if [ $(docker ps -a | grep $IMAGE_NAME | awk '{print $1}' | wc -l) -gt 0 ]; then
    docker stop $(docker ps -a | grep $IMAGE_NAME | awk '{print $1}')
    docker rm $(docker ps -a | grep $IMAGE_NAME | awk '{print $1}')
    docker rmi $IMAGE_NAME
  else
    echo '暂无旧的[$IMAGE_NAME]容器'
  fi
  echo '=======================开始构建新的镜像======================'
  cd $DOCKER_BUILD_HOME
  docker build -t $IMAGE_NAME .
  PROJECT_PORT=$(sh $DOCKER_BUILD_HOME/random_port.sh)
  echo '=======================启动镜像生成新的容器======================'
  docker run -d -v ${LOG_PATH}/user:/opt/app/logs/user -p "$PROJECT_PORT":10000 $IMAGE_NAME
  # 移除旧的jar包
  echo "项目映射端口号: ${PROJECT_PORT}"
  rm $DEPLOY_JAR
}

# 1.打成jar包
echo '=======================分支打包开始======================'
packageJar
echo '=======================分支打包结束======================'
# 2.根据dockerfile构建镜像
echo '=======================构建分支容器开始=================='
initdockerImage
echo '=======================构建分支容器结束=================='

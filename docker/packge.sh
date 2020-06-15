#!/bin/bash
# @Desc java Spring Boot打包shell，集成了docker镜像及容器操作，可选分支脚本部署
# @Author dsg_blue <dsg_blue@aliyun.com>
PROJECT_VERSION=0.0.1-SNAPSHOT.jar
PROJECT_NAME=vhr
PROJECT_HOME=$PROJECT_ROOT/$PROJECT_NAME
DOCKER_BUILD_HOME=$PROJECT_HOME/docker
PROJECT_JAR=$PROJECT_HOME/core/target/core-$PROJECT_VERSION
BRANCHES=()
# 定义分隔符为换行符
IFS=$'\n'
function getBranches() {
  #清屏
  clear
  echo "=======================branch start========================"
  cd $PROJECT_HOME
  index=1
  # 去除每行前2个字符,其实只是为了去掉*号而已【select命令可以优化】
  for branch in $(git branch -a | grep -v "remotes/origin/HEAD" | sed 's/^.\{2\}//'); do
    echo "$index) $branch"
    BRANCHES[$index]=$branch
    index=$(($index + 1))
  done
  echo "=======================branch end ======================="
}
# 部署
function packageJar() {
  while true; do
    read -p "分支编号: " input
    #1.校验参数格式
    echo $input | grep -q '[^0-9]'
    n1=$?
    if [ $n1 -eq 0 ]; then
      echo "编号格式必须为数字！"
      continue
    fi
    #2.校验数字区间
    if [ $input -ge 1 ] && [ $input -le ${#BRANCHES[*]} ]; then
      branch=${BRANCHES[$(echo $input)]}
      echo "已选择编号[$input]:${branch}进行部署,优先部署其他项目依赖"
      packageDependencyes
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
      mvn -U clean install
      echo "======================= mvn install end ======================="
      #5.将jar包位置移动到和dockerfile一样的目录
      DEPLOY_JAR="$PROJECT_NAME".jar
      # 更名，去掉jar包版本号
      mv $PROJECT_JAR $DEPLOY_JAR
      mv $DEPLOY_JAR $(pwd)/docker
      echo "MV将jar包位置移动到和dockerfile一样的目录: "$(pwd)/docker
      break
    else
      echo "请输入正确的分支编号范围"
    fi
  done
}
#执行部署
function packageDependencyes() {
  echo '打包common模块依赖开始'
  cd $PROJECT_ROOT/spring_cloud_common
  git pull
  mvn -U clean install
  echo '打包common模块依赖结束'
}
# 定义镜像版本
IMAGE_TYPE=user
function initdockerImage() {
  # 移除原来的镜像
  echo '=======================停止并且移除旧的容器====================='
  if [ $(docker ps -a | grep $IMAGE_TYPE | awk '{print $1}' | wc -l) -gt 0 ]; then
    docker stop $(docker ps -a | grep $IMAGE_TYPE | awk '{print $1}')
    docker rm $(docker ps -a | grep $IMAGE_TYPE | awk '{print $1}')
    docker rmi $IMAGE_TYPE
  else
    echo '暂无旧的[$IMAGE_TYPE]容器'
  fi
  echo '=======================开始构建新的镜像======================'
  cd $DOCKER_BUILD_HOME
  docker build -t $IMAGE_TYPE .
  PROJECT_PORT=`sh $DOCKER_BUILD_HOME/random_port.sh`
  echo '=======================启动镜像生成新的容器[]======================'
  docker run -d -p "$PROJECT_PORT":10000 $IMAGE_TYPE
  # 打印日志
  rm $DEPLOY_JAR
}

# 1.选取分支
getBranches
# 2.打成jar包
echo '=======================分支打包开始======================'
packageJar
echo '=======================分支打包结束======================'
# 3.根据dockerfile构建镜像
echo '=======================构建分支容器开始======================'
initdockerImage
echo '=======================构建分支容器结束======================'

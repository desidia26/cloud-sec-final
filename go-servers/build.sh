#!/bin/bash
set -e

build_go_server () {
  SERVER_NAME=$1
  TAG=$2
  echo "Building $SERVER_NAME..."
  pushd $SERVER_NAME
  rm -rf build
  mkdir build
  cp ../Dockerfile ./build
  cp go.mod ./build
  cp *.go ./build
  cd build
  docker build \
    -t ${SERVER_NAME}:latest \
    --progress plain \
    --no-cache \
    --build-arg SERVER_NAME=${SERVER_NAME} .
  if [ ! -z "${TAG}" ]; then
    tag_and_push_go_server $SERVER_NAME $TAG
  fi
  popd
}
export -f build_go_server

tag_and_push_go_server () {
  SERVER_NAME=$1
  TAG=$2
  echo "Tagging and pushing $SERVER_NAME..."
  docker tag $SERVER_NAME:latest ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/$SERVER_NAME:$TAG
  docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/$SERVER_NAME:$TAG
}
export -f tag_and_push_go_server

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
export REGION=$(aws configure get region)
cd $SCRIPT_DIR
SERVER_NAME=$1
TAG=$2
if [ -z "${SERVER_NAME}" ]; then
  echo "You must specify a server to build, or pass 'ALL' to build all."
  exit 1
fi

if [ ! -z "${TAG}" ]; then
  aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com
fi

if [ "${SERVER_NAME}" == "ALL" ]; then
  echo "Building em all."
  find * -maxdepth 0 -type d \( ! -name . \) -exec bash -c "build_go_server '{}' $TAG" \;
else
  [ ! -d "$SERVER_NAME" ] && echo "Server $SERVER_NAME DOES NOT exist! Exiting" && exit 1
  build_go_server $SERVER_NAME $TAG
fi
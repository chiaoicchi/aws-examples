#!/bin/bash
set -e

repository_url=$1
aws_region=$2
path_module=$3

cd ${path_module}/../app
aws ecr get-login-password --region $aws_region | \
  docker login --username AWS --password-stdin $repository_url
docker buildx build --platform linux/amd64 --push -t ${repository_url}:latest -f docker/Dockerfile .


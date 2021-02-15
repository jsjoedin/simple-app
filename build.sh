#!/bin/bash

version=$1  #'2.0.0'
REGISTRY_USERNAME=$2 # docker login --username jsjoedin
REGISTRY_TOKEN=$3 # dockerhub: ae02c7ad-f76b-4ec2-976b-c3b89f32f6f7
                  # github: 530c9a0df403dbfbd22b05fd87ce2ba0b54174c6 

echo "create a build container"
buildcon=$(buildah from mcr.microsoft.com/dotnet/sdk:5.0)
buildah config --workingdir /scr $buildcon
buildah copy $buildcon ./simple-app.csproj ./
buildah run $buildcon dotnet restore ./simple-app.csproj
buildah copy $buildcon ./ ./
buildah run $buildcon dotnet publish ./simple-app.csproj -c Release -o /app/publish
buildconmount=$(buildah mount $buildcon)
echo $buildconmount

echo "create a final container"
finalcon=$(buildah from mcr.microsoft.com/dotnet/aspnet:5.0)
buildah config --workingdir /app $finalcon
buildah config --port 80 $finalcon
buildah config --port 443 $finalcon
finalconmount=$(buildah mount $finalcon)
echo $finalconmount

cp -r $buildconmount/app/publish $finalconmount/app

buildah config --entrypoint 'dotnet simple-app.dll' $finalcon

# echo "commit an image (with docker format)"
# buildah commit --format=docker $finalcon simple-app:$version 

echo "commit an image (with oci format)"
buildah commit $finalcon simple-app:$version 

echo "cleanup"
buildah umount --all
buildah rm --all

# echo "push to dockerhub"
# buildah push --creds $REGISTRY_USERNAME:$REGISTRY_TOKEN localhost/simple-app:$version docker://registry.hub.docker.com/$REGISTRY_USERNAME/simple-app:$version
# buildah push --creds $REGISTRY_USERNAME:$REGISTRY_TOKEN localhost/simple-app:$version docker://registry.hub.docker.com/$REGISTRY_USERNAME/simple-app:latest

echo "push to github"
buildah push --creds $REGISTRY_USERNAME:$REGISTRY_TOKEN localhost/simple-app:$version docker://ghcr.io/$REGISTRY_USERNAME/simple-app:$version
buildah push --creds $REGISTRY_USERNAME:$REGISTRY_TOKEN localhost/simple-app:$version docker://ghcr.io/$REGISTRY_USERNAME/simple-app:latest
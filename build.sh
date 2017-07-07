set -e

VER=1.3.6
docker build -t colek42/aide-dev:${VER} .
docker push colek42/aide-dev:${VER}
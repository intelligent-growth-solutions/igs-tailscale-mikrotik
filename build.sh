#!/usr/bin/env sh

#
# Updates tailscale respository and runs `docker build` with flags configured for
# docker distribution.
#
############################################################################
#
# WARNING: Tailscale is not yet officially supported in Docker,
# Kubernetes, etc.
#
# It might work, but we don't regularly test it, and it's not as polished as
# our currently supported platforms. This is provided for people who know
# how Tailscale works and what they're doing.
#
# Our tracking bug for officially support container use cases is:
#    https://github.com/tailscale/tailscale/issues/504
#
# Also, see the various bugs tagged "containers":
#    https://github.com/tailscale/tailscale/labels/containers
#
############################################################################
#
# Set PLATFORM as required for your router model. See:
# https://mikrotik.com/products/matrix
#

# Generate the docker builder
builder=$(docker buildx ls | awk '{print $1}' | grep x32bit | grep -v x32bit0)

if [[ $builder == '' ]];
then
  echo "Generating builder instance..."
  docker buildx create --name x32bit --driver docker-container --platform linux/arm/v7
fi

exit 0

set -eu

if [ ! -d ./tailscale/.git ]
then
    git clone https://github.com/tailscale/tailscale.git
fi

cd tailscale && eval $(./build_dist.sh shellvars) && cd ..

docker buildx build \
  --build-arg VERSION_LONG=$VERSION_LONG \
  --build-arg VERSION_SHORT=$VERSION_SHORT \
  --build-arg VERSION_GIT_HASH=$VERSION_GIT_HASH \
  --platform ${PLATFORM:="linux/arm/v7"} \
  --load \
  -t tailscale:tailscale .

docker save -o tailscale.tar tailscale:tailscale

# Clean up tailscale repo
rm -rf tailscale/
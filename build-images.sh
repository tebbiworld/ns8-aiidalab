#!/bin/bash

#
# Copyright (C) 2026 tebbi
# SPDX-License-Identifier: GPL-3.0-or-later
#

set -e

images=()
repobase="${REPOBASE:-ghcr.io/tebbiworld}"
reponame="aiidalab"

# aiidalab/full-stack: the official AiiDAlab image (JupyterLab/Notebook +
# AiiDA with PostgreSQL and RabbitMQ inside, all running as uid 1000
# "jovyan"), pinned. Exposed to the unit as ${FULL_STACK_IMAGE} through the
# org.nethserver.images label. Calendar tags YYYY.NNNN.
aiidalab_image="docker.io/aiidalab/full-stack:2026.1031"

runtime_images=(
    "${aiidalab_image}"
)

container=$(buildah from scratch)

if ! buildah containers --format "{{.ContainerName}}" | grep -q nodebuilder-aiidalab; then
    echo "Pulling NodeJS runtime..."
    buildah from --name nodebuilder-aiidalab -v "${PWD}:/usr/src:Z" docker.io/library/node:24.16.0-slim
fi

echo "Build static UI files with node..."
buildah run \
    --workingdir=/usr/src/ui \
    --env="NODE_OPTIONS=--openssl-legacy-provider" \
    nodebuilder-aiidalab \
    sh -c "yarn install && yarn build"

buildah add "${container}" imageroot /imageroot
buildah add "${container}" ui/dist /ui
# One TCP port: the Jupyter port published on the node loopback, fronted by
# Traefik (websockets included).
buildah config --entrypoint=/ \
    --label="org.nethserver.authorizations=traefik@node:routeadm" \
    --label="org.nethserver.tcp-ports-demand=1" \
    --label="org.nethserver.rootfull=0" \
    --label="org.nethserver.images=${runtime_images[*]}" \
    "${container}"
buildah commit "${container}" "${repobase}/${reponame}"

images+=("${repobase}/${reponame}")

if [[ -n "${CI}" ]]; then
    printf "images=%s\n" "${images[*],,}" >> "${GITHUB_OUTPUT}"
else
    printf "Publish the images with:\n\n"
    for image in "${images[@],,}"; do printf "  buildah push %s docker://%s:%s\n" "${image}" "${image}" "${IMAGETAG:-latest}" ; done
    printf "\n"
fi

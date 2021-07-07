#!/bin/bash

set -e
set -o pipefail

if [[ -z "${CIRCLE_CI_BRANCH:-}" ]]; then
    METERIAN_REPO_NAME=$(cat ../docker_repository.txt)
elif [[ "${CIRCLE_CI_BRANCH:-}" == "master" ]]; then
    METERIAN_REPO_NAME="meterian/cli"
else
    METERIAN_REPO_NAME="meterian/cli-canary"
fi

isValidVariant() {
    variant=$1 && shift
    variants=($@)

    result=1
    for var in ${variants[@]}; do
        if [[ "${variant}" = "${var}" ]];
        then
            result=0
            break
        fi
    done

    echo ${result}
}

buildVariantImage() {
    VARIANT=$1
    VERSION="$(cat variants/${VARIANT}/version.txt)"
    DOCKER_IMAGE_NAME="${METERIAN_REPO_NAME}"
    DOCKER_FULL_IMAGE_NAME="${DOCKER_IMAGE_NAME}:${VERSION}-${VARIANT}"
    BUILD=${CIRCLE_BUILD_NUM:-000}
    VERSION_WITH_BUILD=${VERSION}-${VARIANT}.${BUILD}

    echo "~~~~~~ Building the docker container for the Meterian Scanner client"
    docker build -t ${DOCKER_FULL_IMAGE_NAME} -t ${DOCKER_IMAGE_NAME}:latest-${VARIANT} --build-arg VERSION=${VERSION_WITH_BUILD} \
                 -f variants/${VARIANT}/Dockerfile .
}

buildFullImage() {
    VERSION="$(cat ../version.txt)"
    DOCKER_IMAGE_NAME="${METERIAN_REPO_NAME}"
    DOCKER_FULL_IMAGE_NAME="${DOCKER_IMAGE_NAME}:${VERSION}"
    BUILD=${CIRCLE_BUILD_NUM:-000}
    VERSION_WITH_BUILD=${VERSION}.${BUILD}

    echo "~~~~~~ Building the docker container for the Meterian Scanner client"
    docker build -t ${DOCKER_FULL_IMAGE_NAME}-tmp -t ${DOCKER_IMAGE_NAME}:latest-tmp --build-arg VERSION=${VERSION_WITH_BUILD} .

    set -x
    DOCKER_BIN="$(which docker)"
    echo "~~~~~~ Squashing ${DOCKER_FULL_IMAGE_NAME} & ${DOCKER_IMAGE_NAME}:latest"
    docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock \
                    -v "${DOCKER_BIN}":"${DOCKER_BIN}" \
                    meterian/docker-squash:latest -t ${DOCKER_FULL_IMAGE_NAME} ${DOCKER_FULL_IMAGE_NAME}-tmp
    docker tag ${DOCKER_FULL_IMAGE_NAME} ${DOCKER_IMAGE_NAME}:latest
}

getVariants() {
    IFS=$'\r\n'
    echo "$(ls variants)" > variants/variants.txt
    file=variants/variants.txt

    variants=()
    while read -r variant
    do
        variants=("${variants[@]}" "$variant")
    done < "$file"

    rm "${file}"
    echo "${variants[@]}"
}

VARIANTS=$(getVariants)
# # test checking VARIANTS 
#echo "${VARIANTS[@]}"

if [[ "$#" -eq 0 ]];
then
    buildFullImage
    exit
fi

if [[ "$*" =~ "--build-all" ]];
then
    echo Building all...

    buildFullImage
    for variant in ${VARIANTS[@]}; do
        buildVariantImage "${variant}"
    done
else
    echo "Specific variant build requested: ${1}"
    if [[ "$(isValidVariant ${1} ${VARIANTS[@]})" -eq 0 ]];
    then
        echo "'${1}' is a supported variant"
        buildVariantImage "${1}"
    else
        echo "'${1}' is not a supported variant"
    fi
fi
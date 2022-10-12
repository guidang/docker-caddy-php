#!/usr/bin/env bash

####### 构建脚本 #######

show_errmsg() {
    printf "\e[1;31m%s \e[0m\n" "${1}"
    exit 1
}

version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "${1}"; }

version_init() {
    full_ver="${1}"
    pre_ver=$(echo ${1}| awk -F"." '{ print $1"."$2 }')
    check_ver=$(echo ${1}| awk -F"." '{ print $1$2 }')

    printf 'full_ver: %s\npre_ver: %s\ncheck_ver: %s\n' "${full_ver}" "${pre_ver}" "${check_ver}"
}

check_alpine_exist() {
    test "$(wget -q https://hub.docker.com/v2/repositories/library/php/tags/${1}-fpm-alpine -O -  | tr ',' '\n' | grep '"name"' | tr -d '[]" ' | awk -F: '{print $2}' | grep ${1}-fpm-alpine)" == ""
}

docker_build() {
    echo "docker buildx build ${pre_ver} vs ${full_ver}-fpm-alpine"
    
    if [[ "${pre_ver}" = "8.1" ]]; then 
        docker buildx build --platform linux/amd64,linux/arm64 \
        --output "type=image,push=true" \
        --tag "${prefix}caddy-php:${full_ver}" \
        --tag "${prefix}caddy-php:${pre_ver}" \
        --tag "${prefix}caddy-php:latest" \
        --build-arg PHP_IMAGE_VER="${full_ver}-fpm-alpine" \
        .   
    else
        docker buildx build --platform linux/amd64,linux/arm64 \
        --output "type=image,push=true" \
        --tag "${prefix}caddy-php:${full_ver}" \
        --tag "${prefix}caddy-php:${pre_ver}" \
        --build-arg PHP_IMAGE_VER="${full_ver}-fpm-alpine" \
        .   
    fi 

    # git_push
}

# only current arch
docker_tag_push() {
    echo "${full_ver}-fpm-alpine ${prefix}caddy-php:${full_ver}" 
    docker build \
      -t ${prefix}caddy-php:${full_ver} \
      --build-arg PHP_IMAGE_VER="${full_ver}-fpm-alpine" \
      --no-cache . || \
      show_errmsg "docker build failed"

    image_id=$(docker images | grep ${prefix}caddy-php | grep ${full_ver} | awk '{print $3}')

    docker tag ${image_id} ${prefix}caddy-php:${pre_ver} || show_errmsg "docker tag failed"

    if [[ "${pre_ver}" = "8.1" ]]; then 
        docker tag ${image_id} ${prefix}caddy-php:latest
    fi

    docker push ${prefix}caddy-php:${full_ver}
    docker push ${prefix}caddy-php:${pre_ver}

    if [[ "${pre_ver}" = "8.1" ]]; then 
        docker push ${prefix}caddy-php:latest
    fi
}

build() {
    if [[ -z "${1}" ]]; then
        show_errmsg "invalid argument for version"
    fi 

    version_init "${1}"

    if check_alpine_exist $full_ver; then
        show_errmsg "no image ${full_ver}-fpm-alpine"
        return 
    fi

    if [[ -z "${2}" ]]; then
        prefix="devcto/"
    else
        prefix="${2}"
    fi

    # 不使用 buildx，只编译 amd64
    # docker_tag_push

    docker_build
}

main() {
    build "${PHP_VERSION}" || exit 1
}

main "$@" || exit 1

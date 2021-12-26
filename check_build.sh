#!/bin/bash

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

    # printf 'full_ver: %s\npre_ver: %s\ncheck_ver: %s\n' "${full_ver}" "${pre_ver}" "${check_ver}"
}

check_alpine_exist() {
    test "$(wget -q https://registry.hub.docker.com/v1/repositories/php/tags -O - | tr -d '[]" ' | tr '}' '\n' | awk -F: '{print $3}' | grep ${1}-fpm-alpine | head -n 1)" == ""
}

docker_build() {
    echo "docker buildx build ${pre_ver} vs ${full_ver}-fpm-alpine"
    
    if [ "${pre_ver}" == "8.1" ]; then 
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

    if [ "${pre_ver}" == "8.1" ]; then 
        docker tag ${image_id} ${prefix}caddy-php:latest
    fi

    docker push ${prefix}caddy-php:${full_ver}
    docker push ${prefix}caddy-php:${pre_ver}

    if [ "${pre_ver}" == "8.1" ]; then 
        docker push ${prefix}caddy-php:latest
    fi
}

git_push() {
    git config --global user.name "${PUSH_USER}"
    git config --global user.email "${PUSH_EMAIL}"

    git add .
    git commit -am "Auto push git update(${UPDATE_VERSION})"
    # git push
    git push https://${GH_TOKEN}@github.com/flydo/docker-caddy-php.git
}

build() {
    if [ "${1}"x = ""x ]; then
        show_errmsg "invalid argument for version"
    fi 

    version_init "${1}"

    if check_alpine_exist $full_ver; then
        echo "no image ${full_ver}-fpm-alpine"
        return 
    fi

    if [ "${2}"x = ""x ]; then
        prefix="devcto/"
    else
        prefix="${2}"
    fi

    # 不使用 buildx，只编译 amd64
    # docker_tag_push

    docker_build
}

main() {
    set -e

    LATEST_VERSIONS=$(curl -s https://www.php.net | sed -n '/download-link/p' | head -n 3 | cut -d '>' -f3 | cut -d '<' -f1)

    . .version

    UPDATE_VERSION=""

    for first_version in $LATEST_VERSIONS
    do
        BUILT=0

        if test "$(printf '%s' $first_version | grep 7.4)"; then
            if version_gt $first_version $PHP_74; then
                echo "(NEW)$first_version is greater than (OLD)$PHP_74 !"
                UPDATE_VERSION=" $UPDATE_VERSION $first_version"

                build "${first_version}" || exit 1

                sed -i "s@^PHP_74=.*@PHP_74=${first_version}@" .version

                BUILT=1
            fi
        elif test "$(printf '%s' $first_version | grep 8.0)"; then
            if version_gt $first_version $PHP_80; then
                echo "(NEW)$first_version is greater than (OLD)$PHP_80 !"
                UPDATE_VERSION=" $UPDATE_VERSION $first_version"

                build "${first_version}" || exit 1

                sed -i "s@^PHP_80=.*@PHP_80=${first_version}@" .version

                BUILT=1
            fi
        elif test "$(printf '%s' $first_version | grep 8.1)"; then
            if version_gt $first_version $PHP_81; then
                echo "(NEW)$first_version is greater than (OLD)$PHP_81 !"
                UPDATE_VERSION=" $UPDATE_VERSION $first_version"

                build "${first_version}" || exit 1

                sed -i "s@^PHP_81=.*@PHP_81=${first_version}@" .version

                BUILT=1
            fi
        fi
    done

    if [[ "${BUILT}" == "1" ]]; then
        echo "GIT PUSH"
        git_push
    fi
}

main "$@" || exit 1
#!/bin/bash

# sets colors for output logs
BLUE='\033[34m'
RED='\033[31m'
CLEAR='\033[0m'

# pre-configured log levels
INFO="(${BLUE}INFO${CLEAR})"
ERROR="(${RED}ERROR${CLEAR})"

log_info() {
  echo -e "$script:$INFO $1"
}

log_error() {
  echo -e "$script:$ERROR $1" >&2
}

CATALOG_NUM=500 # page size of catalog
MANIFEST_HEAD="Accept:application/vnd.docker.distribution.manifest.v2+json"

split() {
  local array=()
  local IFS=","; read -r -a array <<<$1
  echo ${array[@]}
}

find_home() {
  local script=$0
  [ -h "$script" ] && script="$(readlink "$script")"
  echo "$(cd -P "$(dirname "$script")" && pwd)"
}

has_option() {
  [[ "${@:2}" =~ ^$1[[:space:]] || \
     "${@:2}" =~ [[:space:]]$1$ || \
     "${@:2}" =~ [[:space:]]$1[[:space:]] ]] \
  && return 0 || return 255
}

is_option() {
  [[ $1 =~ ^-[a-zA-Z]+$ ]] && return 0 || return 255
}

get_repos() {
  local reg=$1
  curl -s "$reg/v2/_catalog?n=$CATALOG_NUM" | jq -r '.repositories|.[]' 2>/dev/null
}

get_tags() {
  local reg=$1 repo=$2
  curl -s "$reg/v2/$repo/tags/list" | jq -r '.tags|.[]' 2>/dev/null
}

get_digest() {
  local reg=$1 repo=$2 tag=$3
  local res=$(curl -v -s -H $MANIFEST_HEAD $reg/v2/$repo/manifests/$tag 2>&1)
  local digest=$(echo "$res" | grep -i "< Docker-Content-Digest:" | awk '{print ($3)}')
  echo ${digest//[$'\t\r\n']}
}

get_manifest() {
  local reg=$1 repo=$2 tag=$3
  curl -s "$reg/v2/$repo/manifests/$tag" 2>/dev/null
}

list_images() {
  local images=($@) display="default"
  has_option "-lt" $@ && display="tags"
  has_option "-ld" $@ && display="digest"
  has_option "-lm" $@ && display="manifest"

  local reg repo_tags repo repos tags
  for image in "${images[@]}" ; do
    is_option $image && continue

    # is image
    if [[ $image =~ / ]] ; then
      reg=${image%%/*}
      repo_tags=${image#*/}
      repo=${repo_tags%:*}

      # has tags
      [[ $repo_tags =~ : ]] && \
        tags=($(split ${repo_tags##*:})) || \
        tags=($(get_tags $reg $repo))

      echo $image
      echo ---------------------------------------
      for tag in "${tags[@]}" ; do
        case "$display" in
          "digest") echo $(get_digest $reg $repo $tag) $tag ;;
          "manifest") get_manifest $reg $repo $tag ; echo ;;
          *) echo ${tag:-"-"} ;;
        esac
      done
      echo
    # is registry
    else
      reg=$image
      repos=($(get_repos $reg))

      case "$display" in
        "tags") list_images -lt ${repos[@]/#/$reg/} ;;
        "digest") list_images -ld ${repos[@]/#/$reg/} ;;
        "manifest") list_images -lm ${repos[@]/#/$reg/} ;;
        *) 
        echo $reg
        echo ---------------------------------------
        for repo in "${repos[@]}" ; do echo $repo ; done
        echo
      esac
    fi
  done
}

copy_image() {
  local src_reg=$2 dest_reg=$3
  local src_image="$src_reg/$1"
  local dest_image="$dest_reg/$1"

  log_info "$src_image ➞ $dest_image"
  
  docker pull $src_image && \
  docker tag $src_image $dest_image && \
  docker push $dest_image
}

copy_image_tags() {
  local image=$1 dest_reg=$2
  local src_reg=${image%%/*}
  local repo_tags=${image#*/}
  # has tags
  if [[ $repo_tags =~ : ]] ; then
    local repo=${repo_tags%:*}
    local tags=($(split ${repo_tags##*:})) tag
    for tag in "${tags[@]}" ; do
      copy_image $repo:$tag $src_reg $dest_reg
    done
  else
    copy_image $repo_tags $src_reg $dest_reg
  fi
}

read_image_list() {
  local reg=$1 images=()
  if [ -f $reg.list ] ; then
    local IFS=$'\n'; read -d '' -r -a images <$reg.list
    echo ${images[@]}
  else
    log_error "$reg.list not found"
  fi
}

copy_images() {
  [ $# -lt 2 ] && log_error "more arguments required" && exit 255

  local images=${@:1:$#-1} reg=${!#} more
  for image in ${images[@]} ; do
    is_option $image && continue

    # is image
    if [[ $image =~ / ]] ; then
      copy_image_tags $image $reg
    # is registry
    else
      more=($(read_image_list $image))
      [ ${#more[@]} -ne 0 ] && copy_images ${more[@]} $reg
    fi
  done
}

remove_tag() {
  local reg=$1 repo=$2 tag=$3
  local digest=$(get_digest $@)
  if [ -n "$digest" ] ; then
    log_info "digest: $digest"

    res=$(curl -s -o /dev/null -w "%{http_code}" \
      -H $MANIFEST_HEAD -X DELETE $reg/v2/$repo/manifests/$digest)
    if [ $res -eq 202 ] ; then
      log_info "✔ $repo:$tag removed"
    else 
      log_error "✗ failed to remove $repo:$tag" ; exit 255
    fi
  fi
}

remove_tags() {
  local images=($@) force
  has_option "-f" $@ && force=1

  local reg repo_tags repo tags 
  for image in "${images[@]}" ; do
    is_option $image && continue

    reg=${image%%/*}
    repo_tags=${image#*/}
    repo=${repo_tags%:*}

    # has tags
    [[ $repo_tags =~ : ]] && \
      tags=($(split ${repo_tags##*:})) || \
      tags=($(get_tags $reg $repo))

    for tag in "${tags[@]}" ; do
      if [ -z $force ] ; then
        log_info "going to remove $repo:$tag"
        read -p "Are you sure? [y/N] " -r
      fi
      [[ $REPLY =~ ^[Yy]$ || $force ]] && remove_tag $reg $repo $tag
    done
  done
}

usage() {
  cat $home/help.txt | sed -e "s/@@script/$script/g"
}

script=${0##*/}
home=$(find_home)
images=()

case "$1" in
  "ls") list_images ${@:2} ;;
  "cp") copy_images ${@:2} ;;
  "rm") remove_tags ${@:2} ;;
  "")   usage ;;
  *)    log_error "unknown command" ; usage ;;
esac

# Docker Registry CLI ![version v0.1](https://img.shields.io/badge/version-v0.1-brightgreen.svg) ![License MIT](https://img.shields.io/badge/license-MIT-blue.svg)

Docker Registry CLI is a command line utility written in Bash Shell for easy and flexible manipulation of Docker registry that supports [V2 API](https://docs.docker.com/registry/spec/api/).

You can watch the tutorial **"Docker Registry CLI Tutorial"** video series on [YouTube](https://www.youtube.com/watch?v=j_Bd4G5aGXA&list=PLVQM6jLkNkfomYfooLTUmbaNlImMHkDTE) or [YouKu](https://v.youku.com/v_show/id_XNDE3ODk0NTk4MA==.html?f=52175776). Or, read the corresponding posts on [晴耕小筑](https://morningspace.github.io/tags/#studio-reg-cli).

| Title | Links
| ---- 	|:----
| Docker Registry CLI Tutorial - Basic Use | [Post](https://morningspace.github.io/tech/reg-cli-tutorial-1/) [YouTube](https://youtu.be/j_Bd4G5aGXA) [YouKu](https://v.youku.com/v_show/id_XNDE3ODk0NTk4MA==.html?f=52175776)
| Docker Registry CLI Tutorial - More Use  | [Post](https://morningspace.github.io/tech/reg-cli-tutorial-2/) [YouTube](https://youtu.be/wySn3fvtmdE) [YouKu](https://v.youku.com/v_show/id_XNDE5Nzk2OTA3Mg==.html?f=52175776)
| Docker Registry CLI轻松管理Docker注册表(上) | [文章](https://morningspace.github.io/tech/use-docker-reg-cli-1/)
| Docker Registry CLI轻松管理Docker注册表(下) | [文章](https://morningspace.github.io/tech/use-docker-reg-cli-2/)

## Table of Contents
* [Why Different](#why-different)
* [How to Run](#how-to-run)
  * [Inside Container](#inside-container)
  * [From Git Repository](#from-git-repository)
  * [Outside container](#outside-container)
* [How to Use](#how-to-use)
  * [Copy Images between Registries](#copy-images-between-registries)
  * [List images and More](#list-images-and-more)
  * [Remove Images and Tags](#remove-images-and-tags)
* [Notes](#notes)
* [Contact](#contact)

## Why Different

* *Copy in batch*: To copy images in batch is one interesting feature provided by the cli. It can be used to copy multiple images from different sources including both private and public registries to the target registry so that you can setup your own private registry easily.
* *Based on DIND*: The cli provides a Docker image based on [DIND(Docker-in-Docker)](https://github.com/jpetazzo/dind). By using DIND, not only the cli can be run inside container, it can even run docker commands in container without polluting the local registry cache on your host machine.
* *Less is more*: With the combination of a very little set of commands and options, it provides quite a few features to manipulate the registry. See "[How to Use](#how-to-use)" for details.
* *Easy to use*: The design rationale behind the cli is to reference existing linux command syntax as much as possible. So, it's fairly easy to learn and use if you are familiar with some ordinary linux commands such as `ls`, `rm`, and `cp`.

## How to Run

Docker Registry CLI can be run both inside and outside Docker container.

### Inside Container

It's much easier to run inside container since it has all dependencies installed and a soft link created for the shell script so that you can run the cli from anywhere in container.

Another advantage to run inside container is that it won't pollute the local registry cache on your host machine when run the cli copy command to copy images between registries, because the dockerized cli is based on [DIND(Docker-in-Docker)](https://github.com/jpetazzo/dind). If you exist the container after get the work done, nothing will be left.

The cli has been built as a Docker image and published to [Docker Hub](https://cloud.docker.com/u/morningspace/repository/docker/morningspace/docker-registry-cli). You can run below command to pull it to your local machine:

```shell
docker pull morningspace/docker-registry-cli
```

Then start the container to launch Docker daemon:

```shell
docker run --privileged --name reg-cli -d morningspace/docker-registry-cli
```

And connect to it from another container to run the cli:

```shell
docker exec -it reg-cli bash
```

### From Git Repository

You can clone the [Git repository](https://github.com/morningspace/docker-registry-cli) directly to your local to run the cli. There are docker-compose YAML file and some sample configurations distributed along with the cli.

To try it out, run docker-compose as below to launch the daemon and a sample private registry `mr.io` for your testing:

```shell
docker-compose up -d
```

Then connect to the daemon from another container to run the cli:

```shell
docker-compose exec registry-cli bash
```

### Outside Container

To run outside container, you need to install its dependencies at first. See "[Dependencies](#dependencies)" for details.

## How to Use

Run `reg-cli` inside container or `reg-cli.sh` outside container, it will give you help information by default including the usage syntax and examples.

### Copy Images between Registries

Just like the linux `cp` command to copy directories and files, to copy one or more images and tags between registries, all can be done by `reg-cli cp` command.

When specify an image with one or more tags separated by comma, it can copy one or more images with their tags to target registry. Without specifying any tag, it will copy the image with `latest` tag. The source registries can be private registries or public registries such as Docker Hub:

```shell
# copy an image with a tag to a registry
reg-cli cp morningspace/lab-web:1.0 mr.io

# copy an image with multiple tags to a registry
reg-cli cp morningspace/lab-web:1.0,latest mr.io

# copy an image with latest tag to a registry
reg-cli cp morningspace/lab-web mr.io
```

Like the linux `cp` command, it also supports to copy multiple items:

```shell
# copy multiple images to a registry
reg-cli cp morningspace/lab-web morningspace/lab-lb mr.io
```

When specify registry instead of image, it can even copy all configured images with their tags to target registry. This is done by a pre-configured `.list` file which includes all images that you want to copy from source registry. One image per line. When specify the registry, it will look for the `.list` file in current folder where the file name is the registry name:

```shell
# copy images to a registry by reading morningspace.list file
reg-cli cp morningspace mr.io
```

Moreover, the `.list` files can be organized in a nested manner, where entries defined in `.list` file can also be registries. The cli will parse `.list` files recursively. See `.list` sample files distributed along with the cli in folder `/samples/registries`.

### List Images and More

Just like the linux `ls` command to list directories and files, to list registry catalog, image tags, digests and manifests, all can be done by `reg-cli ls` command.

When specify an image, it lists tags for that image by default(or using `-lt`). It can also list digests using `-ld`, or manifest using `-lm`. Here are some examples:

```shell
# list all tags for an image
reg-cli ls mr.io/alpine

# list digests for all tags of an image
reg-cli ls -ld mr.io/alpine

# list manifests for all tags of an image
reg-cli ls -lm mr.io/alpine

# list digest for a tag of an image
reg-cli ls -ld mr.io/alpine:latest

# list manifest for a tag of an image
reg-cli ls -lm mr.io/alpine:latest
```

Like the linux `ls` command, it also supports to list multiple items:

```shell
# list tags for multiple images
reg-cli ls mr.io/alpine mr.io/busybox

# list digests for multiple images with their tags
reg-cli ls -ld mr.io/alpine:latest mr.io/busybox:1.26.2
```

When specify registry instead of image, it can even list all images, or tags, digests, manifests of images on that registry:

```shell
# list all images on a registry
reg-cli ls mr.io

# list tags for all images on a registry
reg-cli ls mr.io -lt

# list digests for all images on a registry
reg-cli ls mr.io -ld

# list manifests for all images on a registry
reg-cli ls mr.io -lm | less
```

### Remove Images and Tags

Just like the linux `rm` command to remove directories or files, to remove one or more images and tags, all can be done by `reg-cli rm` command.

When specify an image with one or more tags separated by comma, it can remove one or more tags of that image. Without specifying any tag, it will remove all tags for that image:

```shell
# remove a tag for an image
reg-cli rm mr.io/alpine:latest

# remove multiple tags for an image
reg-cli rm mr.io/alpine:3.9,latest

# remove all tags for one image
reg-cli rm mr.io/alpine
```

Like the linux `rm` command, it also supports to remove multiple items:

```shell
# remove tags for multiple images
reg-cli rm mr.io/alpine:3.9 mr.io/busybox
```

And, use `-f` to enforce removal without user prompt:

```shell
# force remove
reg-cli rm -f mr.io/alpine:latest
```

## Notes

* *Enable image deletion*: Before run the `reg-cli rm` command, make sure you have enabled `image deletion` on the registry. Otherwise, you may get 405 Error when run the command. This can be configured by either defining environment variable `REGISTRY_STORAGE_DELETE_ENABLED` to be `"true"` or adding corresponding configuration option to `config.yml` on the registry. See [here](https://docs.docker.com/registry/configuration/#delete) for details.

* *Dependencies*: The cli needs `bash`, `curl`, `jq`, `docker` to be installed as its dependencies. You may need to install some of them by yourself if run outside container and they do not exist.

* *Alternatives*: There are [other alternatives](https://github.com/search?q=docker+registry+cli&type=Repositories) that can be found on GitHub. Most of them are written in `Go` or `Python`. See "[Why Different](#why-it-is-different)" to understand why Docker Registry CLI is different from others.

## Contact

Feel free to contact me at morningspace@yahoo.com if you want to contribute.

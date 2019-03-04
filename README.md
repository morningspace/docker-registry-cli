# Docker Registry CLI

**Docker Registry CLI** is a command line utility written in *Bash Shell* for easy and flexible manipulation of Docker registry that supports [V2 API](https://docs.docker.com/registry/spec/api/).

## Table of Contents
* [Why It is Different?](#why-it-is-different?)
  * [Easy to Learn and Use](#easy-to-learn-and-use)
  * [Flexible and Powerful](#flexible-and-powerful)
  * [Setup Registry Easily](#setup-registry-easily)
  * [Run as Docker-in-Docker](#run-as-docker-in-docker)
* [How to Run?](#how-to-run?)
  * [Inside Docker Container](#inside-docker-container)
  * [From GitHub Repository](#from-github-repository)
  * [Outside Docker Container](#outside-docker-container)
* [How to Use?](#how-to-use?)
  * [Copy Images between Registries](#copy-images-between-registries)
  * [List Images and More](#list-images-and-more)
  * [Remove Images and Tags](#remove-images-and-tags)
* [Others You May Need to Know](#others-you-may-need-to-know)
  * [Enable Image Deletion](#enable-image-deletion)
  * [Dependencies](#dependencies)
  * [Alternatives](#alternatives)
* [Contact](#contact)

## Why It is Different?

### Easy to Learn and Use
The design rationale behind Docker Registry CLI is to reference existing linux commands syntax as much as possible. So, it's fairly **easy** to learn and use if you are familiar with some ordinary linux commands such as `ls`, `rm`, `cp`.

### Flexible and Powerful
With the combination of a very little set of commands, options and arguments, it provides very **flexible** and **powerful** features to manipulate the registry. See [How to Use?](#how-to-use?) for details.

### Setup Registry Easily

The `cli cp` command used to copy images between registries is one of the outstanding features that can be used to setup a private registry easily where the images come from multiple sources, including both public registries such as Docker Hub and other private registries.

### Run as Docker-in-Docker

The cli can be run in Docker container and it provides a Docker image based on [DIND(Docker-in-Docker)](https://github.com/jpetazzo/dind) where you can run `cli cp` in container to pull images from source registries then push to target registry without polluting the local images registry on your host machine. After you destroy the container, nothing will be left on your host machine.

## How to Run?

Docker Registry CLI can be run both inside and outside Docker container.

### Inside Docker Container

It's much easier to run inside container since it has all dependencies installed and a soft link created for the shell script so that you can run the cli anywhere.

Another advantage to run inside container is that it won't pollute your local images registry on your host machine when run `cli cp` command to copy images between registries, because the dockerized cli is based on [DIND(Docker-in-Docker)](https://github.com/jpetazzo/dind) which means it can run `docker` commands inside container that's needed by the `cli cp` command.

The cli has been built as a Docker image and published to [Docker Hub](https://cloud.docker.com/u/morningspace/repository/docker/morningspace/docker-registry-cli). You can run below command to pull it to your local machine:

```shell
docker pull morningspace/docker-registry-cli
```

Then start the container to launch the Docker daemon:

```shell
docker run --privileged --name reg-cli -d morningspace/docker-registry-cli
```

And connect to it from another container to run the cli:

```shell
docker exec -it reg-cli bash
```

### From GitHub Repository

You can clone the [GitHub repository](https://github.com/morningspace/docker-registry-cli) directly to your local to run the cli. It has docker-compose YAML file and some sample configurations distributed along with the cli.

To try it out, run docker-compose as below to launch the daemon for the cli and a sample private registry `mr.io` for your test:

```shell
docker-compose up -d
```

Then connect to the daemon from another container to run the cli:

```shell
docker-compose exec registry-cli bash
```

### Outside Docker Container

To run outside container, you need to install its dependencies at first. See [Dependencies](#dependencies) for details.

## How to Use?

Run `reg-cli` inside container or `reg-cli.sh` outside container, it gives you help information including the usage syntax and examples.

### Copy Images between Registries

Just like the linux `cp` command to copy directories and files, to copy image and its tags between registries, all can be done by `cli cp` command.

When specify an image with one tag or multiple tags separated by comma, it can copy one or more images with their tags to target registry for you. Without specifying any tag, it will copy the image with `latest` tag. The source registry can be private registry or public registry such as Docker Hub:

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

When specify registry instead of image, it can even copy all configured images with their tags to target registry for you. This is done by a pre-configured .list file which includes all images that you want to copy from the source registry. One image per line. When specify the registry, it will look for the .list file in the current folder where the file name is the registry name:

```shell
# copy images to a registry by reading morningspace.list file
reg-cli cp morningspace mr.io
```

Moreoever, registry .list files can be organized in a nested manner, where the entry in .list file can be a registry name. The cli will parse .list files recursively. See .list sample files distributed along with the cli in `/samples/registries` folder.

### List Images and More

Just like the linux `ls` command to list directories and files, to list registry catalog, image tags, digests and manifests, all can be done by `cli ls` command.

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

When specify registry instead of image, it can even list all images, tags, digests, manifests of images on that registry for you:

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

Just like the linux `rm` command to remove directories or files, to remove image and its tags, all can be done by `cli rm` command.

When specify an image with one tag or multiple tags separated by comma, it can remove one or more tags of that image for you. Without specifying any tag, it will remove all tags:

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

And, use `-f` to avoid the user prompt:

```shell
# force remove
reg-cli rm -f mr.io/alpine:latest
```

## Others You May Need to Know

### Enable Image Deletion

Before run the `cli rm` command, make sure you have enabled `image deletion` on the registry. Otherwise, you may get 405 Error when run the command.

This can be configured by either defining environment variable `REGISTRY_STORAGE_DELETE_ENABLED` to be `"true"` or adding configuration option to the `config.ym`l on the registry. See [Docker Registry Configuration](https://docs.docker.com/registry/configuration/#delete) for details.

### Dependencies

The cli needs `bash`, `curl`, `jq` to be installed as its dependencies. You may need to install them by yourself if run outside container.

### Alternatives

There are other alternatives that can be found at GitHub. Mostly written in `GO` or `Python`. See [Why It is Different?](#why-it-is-different?) to understand why the cli is different from those alternatives.

## Contact

Feel free to contact me at morningspace@yahoo.com if you want to contribute.

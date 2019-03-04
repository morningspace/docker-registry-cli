# Docker Registry CLI

Docker Registry CLI is a command line utility written in Bash Shell for easy and flexible manipulation of Docker registry that supports [V2 API](https://docs.docker.com/registry/spec/api/).

## Table of Contents
* [Why it is different](#why-it-is-different)
* [How to run](#how-to-run)
  * [Inside Docker container](#inside-docker-container)
  * [From GitHub repository](#from-github-repository)
  * [Outside Docker container](#outside-docker-container)
* [How to use](#how-to-use)
  * [Copy images between registries](#copy-images-between-registries)
  * [List images and more](#list-images-and-more)
  * [Remove images and tags](#remove-images-and-tags)
* [Something else you may need to know](#something-else-you-may-need-to-know)
* [Contact](#contact)

## Why it is different

* **Easy to learn and use**: The design rationale behind Docker Registry CLI is to reference existing linux command syntax as much as possible. So, it's fairly easy to learn and use if you are familiar with some ordinary linux commands such as `ls`, `rm`, `cp`.

* **Flexible and powerful**: With the combination of a very little set of commands, options and arguments, it provides very flexible and powerful features to manipulate the registry. See "[How to use](#how-to-use)" for details.

* **Setup registry easily**: The `cli cp` command used to copy images between registries is one outstanding feature that can be used to setup private registry easily where images can come from multiple sources, including private registries or public registries such as Docker Hub.

* **Run as Docker-in-Docker**: The cli provides a Docker image based on [DIND(Docker-in-Docker)](https://github.com/jpetazzo/dind) where you can run `cli cp` in container to pull images from source registries then push to target registry without polluting local image registry on your host machine. After destroy the container, nothing will be left on your host machine.

## How to run

Docker Registry CLI can be run both inside and outside Docker container.

### Inside Docker container

It's much easier to run inside container since it has all dependencies installed and a soft link created for the shell script so that you can run the cli anywhere in container.

Another advantage to run inside container is that it won't pollute your local image registry on your host machine when run `cli cp` command to copy images between registries, because the dockerized cli is based on [DIND(Docker-in-Docker)](https://github.com/jpetazzo/dind) and can run `docker` commands inside container that are needed by `cli cp`.

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

### From GitHub repository

You can clone the [GitHub repository](https://github.com/morningspace/docker-registry-cli) directly to your local to run the cli. There are docker-compose YAML file and some sample configurations distributed along with the cli.

To try it out, run docker-compose as below to launch the daemon and a sample private registry `mr.io` for your testing:

```shell
docker-compose up -d
```

Then connect to the daemon from another container to run the cli:

```shell
docker-compose exec registry-cli bash
```

### Outside Docker container

To run outside container, you need to install its dependencies at first. See "[Dependencies](#dependencies)" for details.

## How to use

Run `reg-cli` inside container or `reg-cli.sh` outside container, it will give you help information by default including the usage syntax and examples.

### Copy images between registries

Just like the linux `cp` command to copy directories and files, to copy one or more images and tags between registries, all can be done by `cli cp` command.

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

### List images and more

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

### Remove images and tags

Just like the linux `rm` command to remove directories or files, to remove one or more images and tags, all can be done by `cli rm` command.

When specify an image with one ore more tags separated by comma, it can remove one or more tags of that image. Without specifying any tag, it will remove all tags for that image:

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

## Something else you may need to know

* **Enable image deletion**: Before run the `cli rm` command, make sure you have enabled `image deletion` on the registry. Otherwise, you may get 405 Error when run the command. This can be configured by either defining environment variable `REGISTRY_STORAGE_DELETE_ENABLED` to be `"true"` or adding corresponding configuration option to `config.yml` on the registry. See "[Docker Registry Configuration](https://docs.docker.com/registry/configuration/#delete)" for details.

* **Dependencies**: The cli needs `bash`, `curl`, `jq` to be installed as its dependencies. You may need to install some of them by yourself if run outside container and they do not exist.

* **Alternatives**: There are [other alternatives](https://github.com/search?q=docker+registry+cli&type=Repositories) that can be found on GitHub. Most of them are written in `Go` or `Python`. See "[Why it is different](#why-it-is-different)" to understand why Docker Registry CLI is different from them.

## Contact

Feel free to contact me at morningspace@yahoo.com if you want to contribute.

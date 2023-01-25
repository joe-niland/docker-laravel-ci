# docker-laravel-ci

Laravel CI environment based on the official Ubuntu image.

Based on https://github.com/joe-niland/docker-phusion-laravel-build

## Variants

* $PHP_VERSION
  * PHP
  * Composer
  * NPM
  * Node-sass
  * awscli
  * sentry-cli
* $PHP_VERSION-docker
  * Above plus:
    * docker-cli
    * docker-compose
    * dockerd

## Building

`docker build -t joeniland/laravel-ci .`

## Testing

### Shell

`docker run --rm -it --mount src=$(pwd),target=/app,type=bind --workdir /app joeniland/laravel-ci bash`

For use with docker:

`docker run --privileged --rm -it --mount src=$(pwd),target=/app,type=bind -v /var/run/docker.sock:/var/run/docker.sock -v /cache --workdir /app joeniland/laravel-ci docker run hello-world`

### Run unit tests

To run Unit tests with phpunit:

```shell
cd /dev/my-project
docker run -it --mount src=`pwd`,target=/app,type=bind joeniland/laravel-ci phpunit
```

... where `/dev/my-project` is your project root.

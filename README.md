# docker-laravel-ci

CI images for Laravel projects. Each image bundles the tooling a typical Laravel pipeline needs — PHP, Composer, Node, database clients and drivers, awscli, sentry-cli — so your CI jobs start testing instead of installing.

Images are published to Docker Hub: [joeniland/laravel-ci](https://hub.docker.com/r/joeniland/laravel-ci)

If you need an image to *run* Laravel in production, use [serversideup/docker-php](https://github.com/serversideup/docker-php) instead. This project is only for CI pipelines.

## What's inside

Based on the official `php:<version>-cli` image, plus:

- Composer (latest, from the official image)
- PHP extensions: `zip`, `pdo_mysql`, `pdo_pgsql`, `gd`, `bcmath`, `intl`, and SQL Server drivers (`sqlsrv`/`pdo_sqlsrv` on PHP 8.x)
- Node.js 20, `sass`, `@sentry/cli`
- Database clients: `mariadb-client`, `postgresql-client`
- awscli v2
- Common utilities: `git`, `jq`, `rsync`, `zip`/`unzip`, `curl`, `openssh-client`, `netcat`, `dnsutils`
- A non-root `build` user

The `-docker` variant adds the Docker CLI, Compose, buildx, and `dockerd` (from the official dind image) for pipelines that build images or run testcontainers.

## Tags

| Tag | Meaning |
| --- | --- |
| `<php>-latest` (e.g. `8.3-latest`) | Latest build for that PHP version |
| `<php>-<yyyymmdd>` | Dated build, pin for reproducible pipelines |
| `<php>-docker-latest` | Docker-in-Docker variant |
| `<php>-docker-<yyyymmdd>` | Dated dind variant |

## Usage

### GitHub Actions

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    container: joeniland/laravel-ci:8.3-latest
    steps:
      - uses: actions/checkout@v4
      - run: composer install --prefer-dist --no-interaction
      - run: npm ci && npm run build
      - run: vendor/bin/phpunit
```

### Bitbucket Pipelines

```yaml
image: joeniland/laravel-ci:8.3-latest

pipelines:
  default:
    - step:
        script:
          - composer install --prefer-dist --no-interaction
          - vendor/bin/phpunit
```

### AWS CodeBuild

Set the project image to `joeniland/laravel-ci:8.3-latest` (or your ECR copy), then:

```yaml
version: 0.2

phases:
  install:
    commands:
      - composer install --prefer-dist --no-interaction
      - npm ci
  build:
    commands:
      - npm run build
      - vendor/bin/phpunit
```

### Locally

```shell
docker run --rm -it -v "$(pwd)":/app -w /app joeniland/laravel-ci:8.3-latest bash
```

Run your project's test suite:

```shell
docker run --rm -v "$(pwd)":/app -w /app joeniland/laravel-ci:8.3-latest vendor/bin/phpunit
```

### Docker-in-Docker variant

```shell
docker run --privileged --rm -it \
  -v "$(pwd)":/app -w /app \
  -v /var/run/docker.sock:/var/run/docker.sock \
  joeniland/laravel-ci:8.3-docker-latest docker run hello-world
```

## Building

`build.sh` handles buildx setup, multiarch (amd64 + arm64), tagging, and optional pushes to Docker Hub and ECR:

```shell
./build.sh <variant> <php-version> <platform> <push> [ecr_repo]

# Examples
./build.sh php 8.3 multiarch true
./build.sh php 8.3 linux/amd64 false
./build.sh docker 8.2 linux/arm64 true
./build.sh php 8.3 multiarch true public.ecr.aws/my-repo
```

The `docker` variant builds on top of the `php` variant, so build (or pull) that first.

Any PHP version with an official `php:<version>-cli` image should work; 8.2 and 8.3 are the versions built and published regularly.

## License

[MIT](LICENSE)

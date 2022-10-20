# static-ffmpeg-minimal
Static build of [ffmpeg](https://ffmpeg.org)

## Usage

### Run it now
```sh
# Built with alpine stable
docker run ghcr.io/ffbuilds/static-ffmpeg-minimal-alpine_3.16.2:main -version

# Built with alpine edge
docker run ghcr.io/ffbuilds/static-ffmpeg-minimal-alpine_edge:main -version
```

### Copy to your image
```Dockerfile
# syntax=docker/dockerfile:1

# Select from the Support Matrix
ARG ALPINE_VERSION=3.16.2

FROM ghcr.io/ffbuilds/static-ffmpeg-minimal-alpine_${ALPINE_VERSION}:main AS ffmpeg

FROM alpine:${ALPINE_VERSION} AS myimage
COPY --from=ffmpeg /ff* /usr/local/bin/
RUN ffmpeg -version
```

## Support Matrix

| Library | alpine:edge amd64 | alpine:edge arm64 | alpine:edge arm/v7 | alpine:edge arm/v6 | alpine:3.16.2 amd64 | alpine:3.16.2 arm64 | alpine:3.16.2 arm/v7 | alpine:3.16.2 arm/v6 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ffmpeg | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |

## Contributors
- [@wader](https://github.com/wader)
- [@binoculars](https://github.com/binoculars)

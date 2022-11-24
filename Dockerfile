# syntax=docker/dockerfile:1

# bump: ffmpeg /FFMPEG_VERSION=([\d.]+)/ https://github.com/FFmpeg/FFmpeg.git|^5
# bump: ffmpeg after ./hashupdate Dockerfile FFMPEG $LATEST
# bump: ffmpeg link "Changelog" https://github.com/FFmpeg/FFmpeg/blob/n$LATEST/Changelog
# bump: ffmpeg link "Source diff $CURRENT..$LATEST" https://github.com/FFmpeg/FFmpeg/compare/n$CURRENT..n$LATEST
ARG FFMPEG_VERSION=5.1.2
ARG FFMPEG_URL="https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.bz2"
ARG FFMPEG_SHA256=39a0bcc8d98549f16c570624678246a6ac736c066cebdb409f9502e915b22f2b

# Must be specified
ARG ALPINE_VERSION

FROM alpine:${ALPINE_VERSION} AS base

FROM base AS download
ARG FFMPEG_URL
ARG FFMPEG_SHA256
ARG WGET_OPTS="--retry-on-host-error --retry-on-http-error=429,500,502,503 -nv"
WORKDIR /tmp
RUN \
  apk add --no-cache --virtual download \
    coreutils wget tar && \
  wget $WGET_OPTS -O ffmpeg.tar.bz2 "$FFMPEG_URL" && \
  echo "$FFMPEG_SHA256  ffmpeg.tar.bz2" | sha256sum --status -c - && \
  mkdir ffmpeg && \
  tar xf ffmpeg.tar.bz2 -C ffmpeg --strip-components=1 && \
  rm ffmpeg.tar.bz2 && \
  apk del download

FROM base AS build
COPY --from=download /tmp/ffmpeg/ /tmp/ffmpeg/
WORKDIR /tmp/ffmpeg
ARG TARGETPLATFORM
RUN \
  apk add --no-cache --virtual build \
    build-base nasm \
  && \
  case ${TARGETPLATFORM} in \
    linux/arm/v*) \
      export config_opts="--extra-ldexeflags=-static" \
    ;; \
  esac && \
  # sed changes --toolchain=hardened -pie to -static-pie
  # extra ldflags stack-size=2097152 is to increase default stack size from 128KB (musl default) to something
  # more similar to glibc (2MB). This fixing segfault with libaom-av1 and libsvtav1 as they seems to pass
  # large things on the stack.
  sed -i 's/add_ldexeflags -fPIE -pie/add_ldexeflags -fPIE -static-pie/' configure && \
  ./configure \
  ${config_opts} \
  --pkg-config-flags="--static" \
  --extra-cflags="-fopenmp" \
  --extra-ldflags="-fopenmp -Wl,-z,stack-size=2097152" \
  --toolchain=hardened \
  --disable-debug \
  --disable-doc \
  --disable-shared \
  --disable-ffplay \
  --enable-static \
  --disable-runtime-cpudetect \
  || (cat ffbuild/config.log ; false) \
  && make -j$(nproc) install && \
  apk del build

FROM scratch AS final
COPY --from=build /usr/local/bin/ffmpeg /usr/local/bin/ffprobe /
# sanity tests
RUN ["/ffmpeg", "-version"]
RUN ["/ffprobe", "-version"]
RUN ["/ffmpeg", "-hide_banner", "-buildconf"]

FROM final
ENTRYPOINT ["/ffmpeg"]

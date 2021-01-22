# docker-secure-nginx-rtmp
This project is inspired by https://github.com/alfg/docker-nginx-rtmp but adding security features for pushing described by https://smartshitter.com/musings/2017/12/nginx-rtmp-streaming-with-simple-authentication/

Following Features are added to the original project alfg/docker-nginx-rtmp:
* ENV AUTH_KEY: used in the OBS stream rtmp://IP-ADDRESS/stream/NAME?psk=AUTH_KEY
* ENV DOMAIN_NAME: if specified, automatically initiate signing at letsencrypt

Selectable encoding features (default set to TRUE):
 * ENV ENABLE_720P_2628KBS "TRUE"
 * ENV ENABLE_480P_1128KBS "TRUE"
 * ENV ENABLE_360P_878KBS "TRUE"
 * ENV ENABLE_240P_528KBS "TRUE"
 * ENV ENABLE_240P_264KBS "TRUE"

A Dockerfile installing NGINX, nginx-rtmp-module and FFmpeg from source with
default settings for HLS live streaming. Built on Alpine Linux.

* Nginx 1.18.0 (Stable version compiled from source)
* nginx-rtmp-module 1.2.1 (compiled from source)
* ffmpeg 4.3.1 (compiled from source)
* Default HLS settings (See: [nginx.conf](nginx.conf))

[![Docker Stars](https://img.shields.io/docker/stars/ioexpert/secure-nginx-rtmp.svg)](https://hub.docker.com/r/ioexpert/secure-nginx-rtmp/)
[![Docker Pulls](https://img.shields.io/docker/pulls/ioexpert/secure-nginx-rtmp.svg)](https://hub.docker.com/r/ioexpert/secure-nginx-rtmp/)
[![Docker Automated build](https://img.shields.io/docker/automated/ioexpert/secure-nginx-rtmp.svg)](https://hub.docker.com/r/ioexpert/secure-nginx-rtmp/builds/)
[![Build Status](https://travis-ci.org/schreinerman/docker-secure-nginx-rtmp.svg?branch=master)](https://travis-ci.org/schreinerman/docker-ioexpert/secure-nginx-rtmp)

## Usage

### Server
* Pull docker image and run:
```
docker pull ioexpert/secure-nginx-rtmp
docker run -it -p 1935:1935 -p 8080:80 --rm ioexpert/secure-nginx-rtmp
```
or 

* Build and run container from source:
```
docker build -t nginx-secure-rtmp .
docker run -it -p 1935:1935 -p 8080:80 --rm ioexpert/secure-nginx-rtmp
```

* Stream live content to:
```
rtmp://<server ip>:1935/stream/$STREAM_NAME
```

### SSL 
To enable SSL, specify DOMAIN_NAME and the domain will be automatically registered with a SSL certificate by [Let's Encrypt](https://letsencrypt.org).

### Environment Variables
This Docker image uses `envsubst` for environment variable substitution. You can define additional environment variables in `nginx.conf` as `${var}` and pass them in your `docker-compose` file or `docker` command.


### Custom `nginx.conf`
If you wish to use your own `nginx.conf`, mount it as a volume in your `docker-compose` or `docker` command as `nginx.conf.template`:
```yaml
volumes:
  - ./nginx.conf:/etc/nginx/nginx.conf.template
```

### OBS Configuration
* Stream Type: `Custom Streaming Server`
* URL: `rtmp://localhost:1935/stream`
* Stream Key: `hello?psk=mysecret`
* Docker Container Env AUTH_KEY=mysecret

### Watch Stream
* In Safari, VLC or any HLS player, open:
```
http://<server ip>:8080/live/$STREAM_NAME.m3u8
```
* Example Playlist: `http://localhost:8080/live/hello.m3u8`
* [VideoJS Player](https://hls-js.netlify.app/demo/?src=http%3A%2F%2Flocalhost%3A8080%2Flive%2Fhello.m3u8)
* FFplay: `ffplay -fflags nobuffer rtmp://localhost:1935/stream/hello`

### FFmpeg Build
```
$ ffmpeg -buildconf

ffmpeg version 4.3.1 Copyright (c) 2000-2020 the FFmpeg developers
  built with gcc 9.3.0 (Alpine 9.3.0)
  configuration: --prefix=/usr/local --enable-version3 --enable-gpl --enable-nonfree --enable-small --enable-libmp3lame --enable-libx264 --enable-libx265 --enable-libvpx --enable-libtheora --enable-libvorbis --enable-libopus --enable-libfdk-aac --enable-libass --enable-libwebp --enable-postproc --enable-avresample --enable-libfreetype --enable-openssl --disable-debug --disable-doc --disable-ffplay --extra-libs='-lpthread -lm'
  libavutil      56. 51.100 / 56. 51.100
  libavcodec     58. 91.100 / 58. 91.100
  libavformat    58. 45.100 / 58. 45.100
  libavdevice    58. 10.100 / 58. 10.100
  libavfilter     7. 85.100 /  7. 85.100
  libavresample   4.  0.  0 /  4.  0.  0
  libswscale      5.  7.100 /  5.  7.100
  libswresample   3.  7.100 /  3.  7.100
  libpostproc    55.  7.100 / 55.  7.100

  configuration:
    --prefix=/usr/local
    --enable-version3
    --enable-gpl
    --enable-nonfree
    --enable-small
    --enable-libmp3lame
    --enable-libx264
    --enable-libx265
    --enable-libvpx
    --enable-libtheora
    --enable-libvorbis
    --enable-libopus
    --enable-libfdk-aac
    --enable-libass
    --enable-libwebp
    --enable-postproc
    --enable-avresample
    --enable-libfreetype
    --enable-openssl
    --disable-debug
    --disable-doc
    --disable-ffplay
    --extra-libs='-lpthread -lm'
```

## Resources
* https://alpinelinux.org/
* http://nginx.org
* https://github.com/arut/nginx-rtmp-module
* https://www.ffmpeg.org
* https://obsproject.com

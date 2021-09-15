# getouttahereau/docker-asterisk

![Docker Publish workflow](https://github.com/getouttahereau/docker-asterisk/actions/workflows/docker-publish.yml/badge.svg)

This will build a Docker image for Asterisk - a software implementation of private branch exchange (PBX).

* Debian 11.0 Bullseye (minideb)
* Asterisk 18.6.0
* Optional Cisco Enterprise IP Phone support thanks to [usecallmanager.nz](https://usecallmanager.nz/)

You can build the Docker image yourself, or find the pre-built Docker image that is available on the GitHub Container Registry.

[getouttahereau/docker-asterisk on ghcr.io](https://ghcr.io/getouttahereau/docker-asterisk)

## Usage

The simplest way to get up and running is to install Docker and run the following command:

    docker run -d --name=asterisk -v asterisk_config:/etc/asterisk ghcr.io/getouttahereau/docker-asterisk
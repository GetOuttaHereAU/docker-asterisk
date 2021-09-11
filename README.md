# getouttahereau/docker-asterisk

This will build a Docker image for Asterisk - a software implementation of private branch exchange (PBX).

* Debian 11.0 Bullseye
* Asterisk 18.6.0
* Optional [Cisco Enterprise IP Phone support](https://usecallmanager.nz)

You can build the Docker image yourself, or find the pre-built Docker image that is available on DockerHub.

## Usage

The simplest way to get up and running is install Docker and run the following command:

    docker run -dit --name=asterisk -v asterisk_config:/etc/asterisk getouttahereau/docker-asterisk
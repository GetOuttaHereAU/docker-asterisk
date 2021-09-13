FROM debian:bullseye
LABEL org.opencontainers.image.source=https://github.com/getouttahereau/docker-asterisk

ENV ASTERISK_VERSION=18.6.0 \
    RTP_START=10000 \
    RTP_END=20000 \
    CISCO=true

# Volumes
VOLUME /etc/asterisk
RUN apt update && apt -y upgrade && apt -y install \
    # Install runtime dependencies
    curl libedit2 libsqlite3-0 libxml2 \
    # Install build dependencies
    bzip2 gcc g++ libedit-dev libsqlite3-dev libxml2-dev make patch uuid-dev && \

    # Asterisk installation
    mkdir -p /usr/src/asterisk && cd /usr/src/asterisk && \
    curl https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${ASTERISK_VERSION}.tar.gz | tar xz --strip-components=1 && \

    # - This seems like overkill. Review and ensure cleanup after building before use.
    # # Set country code for libvpb1 in advance
    # echo 'libvpb1 libvpb1/countrycode string 61' | debconf-set-selections -v && \
    # contrib/scripts/install_prereq install && \
    # contrib/scripts/get_mp3_source.sh && \

    # - Cisco Patch by usecallmanager.nz
    if [ -z ${CISCO+x }]; then \
      echo "Env var CISCO unset, skipping CISCO IP Phone support"; \
    else \
      echo "Env var CISCO set, Patching Asterisk with CISCO IP Phone support"; \
      curl https://raw.githubusercontent.com/usecallmanagernz/patches/master/asterisk/cisco-usecallmanager-${ASTERISK_VERSION}.patch | patch -p1 -b; \
    fi && \
    ./configure --with-jansson-bundled && \
    make -j8 && \
    make install && \
    make samples && \
    make config && \

    # Update config with env vars
    sed -i "/^[ \t]*\[general\]/,/\[/s/^\([ \t]*rtpstart[ \t]*=[ \t]*\).*/\1${RTP_START}/" /etc/asterisk/rtp.conf && \
    sed -i "/^[ \t]*\[general\]/,/\[/s/^\([ \t]*rtpend[ \t]*=[ \t]*\).*/\1${RTP_END}/" /etc/asterisk/rtp.conf && \    

    # Cleanup
    cd / && rm -rf /usr/src/* && \
    apt -y purge gcc g++ make bzip2 patch libedit-dev uuid-dev libxml2-dev \
                 libsqlite3-dev && \
    apt -y autoremove --purge

# Required ports
EXPOSE 5060/udp 5060 5160/udp 5160 5036/udp ${RTP_START}-${RTP_END}/udp

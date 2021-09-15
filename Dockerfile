# syntax=docker/dockerfile:1
# escape=\

FROM bitnami/minideb:bullseye as builder
LABEL org.opencontainers.image.source=https://github.com/getouttahereau/docker-asterisk
ENV ASTERISK_VERSION=18.6.0 \
    RTP_START=10000 \
    RTP_END=20000 \
    CISCO=enabled \
    COUNTRY_CODE=61
RUN \
    # Upgrade system packages if required
    apt update && apt -y upgrade && apt -y install curl && \
    # Get Asterisk source
    mkdir -p /usr/src/asterisk && cd /usr/src/asterisk && \
    curl https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${ASTERISK_VERSION:-18.6.0}.tar.gz | tar xz --strip-components=1 && \
    # Set country code for libvpb1 in advance (default: Australia)
    echo "libvpb1 libvpb1/countrycode string ${COUNTRY_CODE:-61}" | debconf-set-selections -v && \
    # Install prerequisites
    contrib/scripts/install_prereq install && \
    contrib/scripts/get_mp3_source.sh && \
    # Get Cisco patch by usecallmanager.nz _IF_ CISCO environment variable set
    if [ -z ${CISCO+x }]; then \
      echo 'Env var CISCO unset, skipping CISCO IP Phone support'; \
    else \
      echo 'Env var CISCO set, Patching Asterisk with CISCO IP Phone support'; \
      curl https://raw.githubusercontent.com/usecallmanagernz/patches/master/asterisk/cisco-usecallmanager-${ASTERISK_VERSION:-18.6.0}.patch | patch -p1 -b; \
    fi && \
    # Build
    ./configure --with-jansson-bundled && \
    make && \
    make install && \
    make samples && \
    make config && \
    make install-logrotate && \
    # Update config with env vars
    sed -i "/^[ \t]*\[general\][ \t]/,/\[/s/^\([ \t]*rtpstart[ \t]*=[ \t]*\).*/\1${RTP_START:-10000}/" /etc/asterisk/rtp.conf && \
    sed -i "/^[ \t]*\[general\][ \t]/,/\[/s/^\([ \t]*rtpend[ \t]*=[ \t]*\).*/\1${RTP_END:-20000}/" /etc/asterisk/rtp.conf

FROM bitnami/minideb:bullseye
VOLUME /etc/asterisk
COPY --from=builder /etc/asterisk /etc/asterisk
COPY --from=builder /usr/lib/asterisk /usr/lib/asterisk
COPY --from=builder /var/lib/asterisk /var/lib/asterisk
COPY --from=builder /var/spool/asterisk /var/spool/asterisk
COPY --from=builder /var/run/asterisk /run/asterisk
COPY --from=builder /var/log/asterisk /var/log/asterisk
COPY --from=builder /usr/lib/libasteriskpj.so.2 /usr/lib/libasteriskssl.so.1 /usr/lib/
COPY --from=builder /usr/sbin/astcanary /usr/sbin/astdb2bdb /usr/sbin/astdb2sqlite3 /usr/sbin/asterisk /usr/sbin/astgenkey /usr/sbin/astversion /usr/sbin/autosupport /usr/sbin/rasterisk /usr/sbin/safe_asterisk /usr/sbin/
COPY --from=builder /etc/init.d/asterisk /etc/init.d/asterisk
COPY --from=builder /etc/logrotate.d/asterisk /etc/logrotate.d/asterisk
COPY --from=builder /etc/default/asterisk /etc/default/asterisk
# Install required packages
RUN install_packages libcap2 libcodec2-0.9 libcurl4 libedit2 libglib2.0-0 libgmime-3.0-0 libgsm1 libical3 libiksemel3 \
    libjack0 libldap-2.4-2 liblua5.2-0 libneon27 libodbc1 libogg0 libosptk4 libpq5 libradcli4 libresample1 libsnmp40 \
    libspandsp2 libspeex1 libspeexdsp1 libsqlite3-0 libsrtp2-1 libsybdb5 libunbound8 liburiparser1 libvorbis0a \
    libvorbisenc2 libvorbisfile3 libxml2 libxslt1.1 && \
    # Create symlinks 
    ln -s /usr/lib/libasteriskpj.so.2 /usr/lib/libasteriskpj.so && \
    ln -s /usr/lib/libasteriskssl.so.1 /usr/lib/libasteriskssl.so && \
    # Create asterisk user and make asterisk run as that user
    adduser --home /var/lib/asterisk/ --shell /usr/sbin/nologin --no-create-home --gecos "Asterisk PBX" --disabled-password --disabled-login asterisk && \
    usermod -a -G dialout,audio asterisk && \
    sed -i '/^[ \t]*\[options\][ \t]*/,/\[/s/^[ \t]*;[ \t]*\(\(rungroup\|runuser\)[ \t]*=[ \t]*\).*\([ \t]*(;.*)?\)$/\1asterisk \3/'  /etc/asterisk/asterisk.conf && \
    sed -i 's/^\([ \t]*\)#\([ \t]*\(AST_USER\|AST_GROUP\)[ \t]*=[ \t]*\).*\([ \t]*\)$/\1\2"asterisk"\4/' /etc/default/asterisk && \
    chown -R asterisk:asterisk /etc/asterisk /usr/lib/asterisk /var/lib/asterisk /var/spool/asterisk /var/log/asterisk
# Start asterisk!
CMD /usr/sbin/asterisk -f -G asterisk -U asterisk
EXPOSE 5060/udp 5060 5160/udp 5160 5036/udp ${RTP_START:-10000}-${RTP_END:-20000}/udp

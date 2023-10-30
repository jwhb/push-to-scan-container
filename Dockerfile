ARG ALPINE_VER=3.18

FROM alpine:$ALPINE_VER AS build

RUN apk add --no-cache \
  g++ make confuse-dev dbus-dev sane-dev patch

ARG SCANBD_VER=1.5.1

WORKDIR /usr/local/src/scanbd

RUN wget https://downloads.sourceforge.net/scanbd/scanbd-$SCANBD_VER.tgz -O- | tar -xzf - --strip-components=2 \
  && wget -O string-bounds.patch https://aur.archlinux.org/cgit/aur.git/plain/string-bounds.patch?h=scanbd \
  && patch --strip=1 < /usr/local/src/scanbd/string-bounds.patch \
  && ./configure --prefix=/usr --sysconfdir=/etc --sbindir=/usr/bin \
  && make \
  && mkdir /scanbd \
  && make DESTDIR=/scanbd install \
  && mkdir -p /scanbd/etc/dbus-1/system.d/ \
  && cp integration/scanbd_dbus.conf /scanbd/etc/dbus-1/system.d/scanbd_dbus.conf

FROM alpine:$ALPINE_VER

RUN apk add --no-cache \
  dbus \
  sane \
  sane-utils \
  confuse \
  qpdf \
  && echo "saned:x:114:7::/var/lib/saned:/usr/sbin/nologin" >> /etc/passwd

COPY --from=build /scanbd /
COPY action.script /etc/scanbd/scripts/action.script

RUN cd /etc/scanbd/ \
  && sed -i 's@\(SANE_CONFIG_DIR=\)\(/etc/scanbd\)@\1\2/sane.d@' scanbd.conf \
  && sed -i 's@\(user    = \)saned$@\1root@' scanbd.conf \
  && sed -i 's@\(<policy user="\)saned\(">\)@\1root\2@' /etc/dbus-1/system.d/scanbd_dbus.conf \
  && sed -i 's@\(script =\) "test.script"$@\1 "action.script"@' scanbd.conf

COPY docker-entrypoint.sh /

ENTRYPOINT /docker-entrypoint.sh

ENV SCANBD_DEBUG_LEVEL=2


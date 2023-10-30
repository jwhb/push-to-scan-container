#!/bin/sh -e

if [ -n "${SANE_BACKEND}" ]; then
  apk add -q "sane-backend-${SANE_BACKEND}"
fi

rm -rf /var/run/dbus
mkdir -p /var/run/dbus
dbus-daemon --config-file=/usr/share/dbus-1/system.conf

echo "Detecting scanner once..."
n=0
until [ "$n" -ge 5 ]; do
  scanner=$(scanimage -f "%d")
  [ -n "${scanner}" ] && break
  echo "No scanner found, retry in 15s..."
  sleep 15
done
echo "Found scanner ${scanner}."

echo "Start scanbd..."
exec scanbd -f "-d${SCANBD_DEBUG_LEVEL:-2}"


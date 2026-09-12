#!/bin/bash
set -e

RDP_PASSWORD="${RDP_PASSWORD:-1122}"

echo "========================================"
echo " CloudDesk RDP"
echo " Lightweight XFCE + Firefox ESR"
echo "========================================"
echo "RDP user: ubuntu"

echo "ubuntu:${RDP_PASSWORD}" | chpasswd

mkdir -p /run/dbus /run/user/1000 /var/run/xrdp /home/ubuntu/Workspace
chown ubuntu:ubuntu /run/user/1000 /home/ubuntu/Workspace
chown xrdp:xrdp /var/run/xrdp

if ! pgrep -x dbus-daemon >/dev/null 2>&1; then
    dbus-daemon --system || true
fi

rm -f /var/run/xrdp/xrdp.pid /var/run/xrdp/xrdp-sesman.pid

echo "Starting xrdp-sesman..."
xrdp-sesman &
sleep 1

echo "Starting xrdp on port 3389..."
exec xrdp --nodaemon

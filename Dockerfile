# syntax=docker/dockerfile:1
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Lightweight RDP desktop. This deliberately avoids the full Ubuntu desktop.
RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 \
    xfce4-terminal \
    thunar \
    thunar-archive-plugin \
    thunar-volman \
    xrdp \
    xorgxrdp \
    dbus \
    dbus-x11 \
    sudo \
    plank \
    ca-certificates \
    curl \
    wget \
    unzip \
    zip \
    p7zip-full \
    file \
    nano \
    less \
    procps \
    psmisc \
    htop \
    iproute2 \
    net-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Ubuntu 24.04 provides Firefox as a Snap transition package, which is not
# suitable for this systemd-free container. Install Mozilla's official
# Firefox ESR Linux tarball instead.
RUN arch="$(dpkg --print-architecture)" \
    && case "$arch" in amd64) mozarch="linux-x86_64";; arm64) mozarch="linux-aarch64";; *) echo "Unsupported architecture: $arch"; exit 1;; esac \
    && curl -fL "https://download.mozilla.org/?product=firefox-esr-latest-ssl&os=${mozarch}&lang=en-US" -o /tmp/firefox.tar.xz \
    && mkdir -p /opt/firefox \
    && tar -xJf /tmp/firefox.tar.xz -C /opt/firefox --strip-components=1 \
    && rm -f /tmp/firefox.tar.xz \
    && ln -sf /opt/firefox/firefox /usr/local/bin/firefox \
    && printf '%s\n' \
       '[Desktop Entry]' \
       'Name=Firefox ESR' \
       'Comment=Web Browser' \
       'Exec=/usr/local/bin/firefox %u' \
       'Terminal=false' \
       'Type=Application' \
       'Icon=/opt/firefox/browser/chrome/icons/default/default128.png' \
       'Categories=Network;WebBrowser;' \
       'MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;' \
       'StartupNotify=true' \
       > /usr/share/applications/firefox-esr.desktop \
    && update-desktop-database /usr/share/applications 2>/dev/null || true

# RDP account. Password can be overridden at runtime with RDP_PASSWORD.
RUN if id ubuntu >/dev/null 2>&1; then \
        usermod -s /bin/bash ubuntu; \
    else \
        useradd -m -s /bin/bash ubuntu; \
    fi \
    && usermod -c "CloudDesk" ubuntu \
    && usermod -aG sudo ubuntu \
    && echo "ubuntu:1122" | chpasswd \
    && mkdir -p /home/ubuntu/Workspace \
                 /home/ubuntu/.config/autostart \
                 /home/ubuntu/.config/plank/dock1/launchers \
    && chown -R ubuntu:ubuntu /home/ubuntu

# XRDP -> D-Bus session -> XFCE.
RUN printf '%s\n' \
    '#!/bin/sh' \
    'export LANG=C.UTF-8' \
    'export LANGUAGE=C.UTF-8' \
    'export LC_ALL=C.UTF-8' \
    'export XDG_CURRENT_DESKTOP=XFCE' \
    'export XDG_SESSION_DESKTOP=xfce' \
    'export DESKTOP_SESSION=xfce' \
    'unset DBUS_SESSION_BUS_ADDRESS' \
    'unset XDG_RUNTIME_DIR' \
    'exec dbus-run-session -- startxfce4' \
    > /etc/xrdp/startwm.sh \
    && chmod 755 /etc/xrdp/startwm.sh \
    && printf '%s\n' 'startxfce4' > /home/ubuntu/.xsession \
    && chown ubuntu:ubuntu /home/ubuntu/.xsession

# Minimal left-side macOS-inspired dock: Firefox, Files, Terminal, Trash.
RUN printf '%s\n' \
    '[PlankDockPreferences]' \
    'IconSize=44' \
    'HideMode=0' \
    'UnhideDelay=0' \
    'Monitor=-1' \
    'Position=0' \
    'Offset=0' \
    'Theme=Default' \
    'Alignment=3' \
    'ItemsAlignment=3' \
    'CurrentWorkspaceOnly=false' \
    'ZoomEnabled=false' \
    'LockItems=false' \
    'DockItems=firefox-esr.dockitem;thunar.dockitem;xfce4-terminal.dockitem;trash.dockitem' \
    > /home/ubuntu/.config/plank/dock1/settings \
    && for item in firefox-esr thunar xfce4-terminal; do \
         if [ -f "/usr/share/applications/$item.desktop" ]; then \
           printf '%s\n' \
             '[PlankItemsDockItemPreferences]' \
             "Launcher=file:///usr/share/applications/$item.desktop" \
             > "/home/ubuntu/.config/plank/dock1/launchers/$item.dockitem"; \
         fi; \
       done \
    && printf '%s\n' \
       '[PlankItemsDockItemPreferences]' \
       'Launcher=docklet://trash' \
       > /home/ubuntu/.config/plank/dock1/launchers/trash.dockitem \
    && printf '%s\n' \
       '[Desktop Entry]' \
       'Type=Application' \
       'Name=CloudDesk Dock' \
       'Exec=plank' \
       'OnlyShowIn=XFCE;' \
       'X-GNOME-Autostart-enabled=true' \
       > /home/ubuntu/.config/autostart/plank.desktop \
    && chown -R ubuntu:ubuntu /home/ubuntu/.config

# RDP performance defaults: no compositor, no screen blanking.
RUN runuser -u ubuntu -- dbus-run-session -- sh -c '\
    xfconf-query -c xfwm4 -p /general/use_compositing -s false || true; \
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0 || true; \
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false || true'

# No interactive crash-report popup inside the container.
RUN mkdir -p /etc/default \
    && printf '%s\n' 'enabled=0' > /etc/default/apport \
    && rm -f /var/crash/*

COPY start.sh /start.sh
RUN chmod 755 /start.sh

EXPOSE 3389
CMD ["/start.sh"]

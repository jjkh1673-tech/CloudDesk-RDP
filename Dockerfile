# syntax=docker/dockerfile:1
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Lightweight RDP desktop. This deliberately avoids the full Ubuntu desktop.
RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 \
    xfce4-terminal \
    thunar \
    ubuntu-wallpapers-noble \
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

# Smart Nano configuration for coding, scripts and file management.
RUN cat >> /etc/nanorc <<'EOF'

# ===== CloudDesk Nano =====

# Always show line numbers.
set linenumbers

# Show cursor position.
set constantshow

# Mouse support: click inside the editor to place the cursor.
set mouse

# Four spaces per indentation level.
set tabsize 4
set tabstospaces

# Automatically indent new lines.
set autoindent

# Keep long code lines readable without modifying the file.
set softwrap

# Do not automatically hard-wrap source code.
set nowrap

# Better navigation and editing.
set smarthome
set atblanks

# Show matching brackets more clearly when supported.
set matchbrackets "{}()[]"

# Enable syntax highlighting from the installed nano syntax files.
include "/usr/share/nano/*.nanorc"

EOF

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

# XRDP -> D-Bus -> XFCE session.
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

# Disable XFCE panel from the user's session.
RUN mkdir -p \
        /home/ubuntu/.config/autostart \
        /home/ubuntu/.cache \
    && printf '%s\n' \
       '[Desktop Entry]' \
       'Type=Application' \
       'Name=XFCE Panel' \
       'Comment=Disabled for CloudDesk macOS-style dock' \
       'Exec=xfce4-panel' \
       'Hidden=true' \
       'OnlyShowIn=XFCE;' \
       'X-GNOME-Autostart-enabled=false' \
       > /home/ubuntu/.config/autostart/xfce4-panel.desktop \
    && rm -rf /home/ubuntu/.cache/sessions \
    && chown -R ubuntu:ubuntu \
        /home/ubuntu/.config \
        /home/ubuntu/.cache

    
# Clean macOS-style left dock:
# Desktop, Trash, Settings, Firefox, Files, Terminal only.
RUN mkdir -p \
    /home/ubuntu/.config/plank/dock1/launchers \
    /home/ubuntu/.config/autostart \
    /home/ubuntu/.local/share/applications \
    && printf '%s\n' \
    '[PlankDockPreferences]' \
    'IconSize=60' \
    'HideMode=0' \
    'UnhideDelay=0' \
    'HideDelay=0' \
    'Monitor=-1' \
    'Position=0' \
    'Offset=0' \
    'Theme=Default' \
    'Alignment=3' \
    'ItemsAlignment=3' \
    'CurrentWorkspaceOnly=false' \
    'ZoomEnabled=true' \
    'ZoomPercent=120' \
    'LockItems=true' \
    'DockItems=desktop.dockitem;trash.dockitem;settings.dockitem;firefox-esr.dockitem;thunar.dockitem;xfce4-terminal.dockitem' \
    > /home/ubuntu/.config/plank/dock1/settings \
    && printf '%s\n' \
       '[PlankItemsDockItemPreferences]' \
       'Launcher=application://org.xfce.xfdesktop-settings.desktop' \
       > /home/ubuntu/.config/plank/dock1/launchers/settings.dockitem \
    && printf '%s\n' \
       '[PlankItemsDockItemPreferences]' \
       'Launcher=docklet://desktop' \
       > /home/ubuntu/.config/plank/dock1/launchers/desktop.dockitem \
    && printf '%s\n' \
       '[PlankItemsDockItemPreferences]' \
       'Launcher=docklet://trash' \
       > /home/ubuntu/.config/plank/dock1/launchers/trash.dockitem \
    && printf '%s\n' \
       '[PlankItemsDockItemPreferences]' \
       'Launcher=file:///usr/share/applications/firefox-esr.desktop' \
       > /home/ubuntu/.config/plank/dock1/launchers/firefox-esr.dockitem \
    && printf '%s\n' \
       '[PlankItemsDockItemPreferences]' \
       'Launcher=file:///usr/share/applications/thunar.desktop' \
       > /home/ubuntu/.config/plank/dock1/launchers/thunar.dockitem \
    && printf '%s\n' \
       '[PlankItemsDockItemPreferences]' \
       'Launcher=file:///usr/share/applications/xfce4-terminal.desktop' \
       > /home/ubuntu/.config/plank/dock1/launchers/xfce4-terminal.dockitem \
    && printf '%s\n' \
       '[Desktop Entry]' \
       'Type=Application' \
       'Name=CloudDesk Dock' \
       'Exec=plank' \
       'OnlyShowIn=XFCE;' \
       'X-GNOME-Autostart-enabled=true' \
       > /home/ubuntu/.config/autostart/plank.desktop \
    && chown -R ubuntu:ubuntu /home/ubuntu/.config /home/ubuntu/.local

# Clean desktop: no Home/File System/Trash icons and no XFCE panel.
RUN runuser -u ubuntu -- dbus-run-session -- sh -c '\
    xfconf-query -c xfce4-desktop -p /desktop-icons/style -s 0 || true; \
    xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-filesystem -s false || true; \
    xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-home -s false || true; \
    xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-trash -s false || true; \
    xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-removable -s false || true'
    
# Use an official Ubuntu 24.04 wallpaper as the native desktop background.
RUN runuser -u ubuntu -- dbus-run-session -- sh -c '\
    WALL=$(find /usr/share/backgrounds -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | head -n 1); \
    if [ -n "$WALL" ]; then \
        xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "$WALL" || true; \
        xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-style -s 5 || true; \
    fi'

# No interactive crash-report popup inside the container.
RUN mkdir -p /etc/default \
    && printf '%s\n' 'enabled=0' > /etc/default/apport \
    && rm -f /var/crash/*

COPY start.sh /start.sh
RUN chmod 755 /start.sh

EXPOSE 3389
CMD ["/start.sh"]

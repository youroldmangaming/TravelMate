# Base image - Using Debian as it's compatible with all our requirements
FROM debian:bullseye-slim

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages for travel router, Pi-hole dependencies, ZeroTier, Samba, NFS, and RaspAP
RUN apt-get update && apt-get install -y \
    dnsmasq \
    hostapd \
    iproute2 \
    iptables \
    iw \
    lighttpd \
    curl \
    wget \
    ca-certificates \
    procps \
    dhcpcd5 \
    wireless-tools \
    net-tools \
    iputils-ping \
    kmod \
    rfkill \
    sudo \
    cron \
    php-sqlite3 \
    php-intl \
    php-xml \
    php-json \
    php-cgi \
    php-curl \
    dnsutils \
    libcap2-bin \
    netcat-openbsd \
    openssl \
    php-common \
    php-fpm \
    idn2 \
    libcap2 \
    libcap2-bin \
    lighttpd-mod-deflate \
    git \
    supervisor \
    gnupg \
    lsb-release \
    apache2-utils \
    # SMB packages
    samba \
    samba-common \
    samba-common-bin \
    # NFS packages
    nfs-kernel-server \
    nfs-common \
    # RaspAP additional dependencies
    debconf \
    dhcpcd5 \
    php \
    php-cgi \
    php-fpm \
    vnstat \
    qrencode \
    sqlite3 \
    libsqlite3-dev \
    haveged \
    libmicrohttpd-dev \
    pkg-config \
    build-essential \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

# Set up Pi-hole
WORKDIR /root

# Clone Pi-hole repository
RUN git clone --depth 1 https://github.com/pi-hole/pi-hole.git /etc/.pihole
RUN git clone --depth 1 https://github.com/pi-hole/AdminLTE.git /var/www/html/admin
WORKDIR /etc/.pihole/

# Create required directories
RUN mkdir -p /etc/pihole /etc/dnsmasq.d /var/www/html/pihole

# Install Pi-hole
RUN bash /etc/.pihole/automated\ install/basic-install.sh --unattended

# ZeroTier installation
RUN curl -s https://install.zerotier.com | bash

# Install RaspAP
WORKDIR /tmp
# Clone RaspAP repository
RUN git clone -b latest https://github.com/RaspAP/raspap-webgui.git
WORKDIR /tmp/raspap-webgui

# Install RaspAP files
RUN mkdir -p /var/www/html/raspap
RUN cp -r raspap/* /var/www/html/raspap
RUN chown -R www-data:www-data /var/www/html/raspap
RUN mv installers/raspap.sudoers /etc/sudoers.d/090_raspap
RUN chmod 0440 /etc/sudoers.d/090_raspap
RUN mkdir /etc/raspap/
RUN mv config/hostapd.conf /etc/raspap/hostapd.conf.template
RUN mv config/090_raspap.conf /etc/sudoers.d/090_raspap
RUN mkdir -p /etc/raspap/lighttpd/
RUN mv config/50-raspap-router.conf /etc/raspap/lighttpd/
RUN ln -s /etc/raspap/lighttpd/50-raspap-router.conf /etc/lighttpd/conf-available/
RUN ln -s /etc/lighttpd/conf-available/50-raspap-router.conf /etc/lighttpd/conf-enabled/
RUN mv config/defaults.json /etc/raspap/
RUN chown -R www-data:www-data /etc/raspap
RUN usermod -a -G www-data root

# Configure lighttpd to allow access to RaspAP
RUN echo 'server.modules += ( "mod_auth" )' >> /etc/lighttpd/lighttpd.conf
RUN echo '$HTTP["url"] =~ "^/raspap/" {' >> /etc/lighttpd/lighttpd.conf
RUN echo '  auth.backend = "htpasswd"' >> /etc/lighttpd/lighttpd.conf
RUN echo '  auth.backend.htpasswd.userfile = "/etc/raspap/raspap.users"' >> /etc/lighttpd/lighttpd.conf
RUN echo '  auth.require = ( "" => (' >> /etc/lighttpd/lighttpd.conf
RUN echo '    "method" => "basic",' >> /etc/lighttpd/lighttpd.conf
RUN echo '    "realm" => "RaspAP",' >> /etc/lighttpd/lighttpd.conf
RUN echo '    "require" => "valid-user"' >> /etc/lighttpd/lighttpd.conf
RUN echo '  ))' >> /etc/lighttpd/lighttpd.conf
RUN echo '}' >> /etc/lighttpd/lighttpd.conf

# Create shared directory
RUN mkdir -p /shared
RUN chmod 777 /shared

# Copy template files for environment variable substitution
COPY smb.conf.template /etc/samba/smb.conf.template
COPY exports.template /etc/exports.template
COPY hostapd.conf.template /etc/hostapd/hostapd.conf.template

# Copy network interface setup script
COPY setup-interfaces.sh /usr/local/bin/setup-interfaces.sh
RUN chmod +x /usr/local/bin/setup-interfaces.sh

# Copy iptables configuration for internet sharing
COPY setup-iptables.sh /usr/local/bin/setup-iptables.sh
RUN chmod +x /usr/local/bin/setup-iptables.sh

# Supervisor configuration to manage all processes
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create a startup script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Expose ports for Pi-hole, SMB, NFS, and RaspAP
EXPOSE 80/tcp 53/tcp 53/udp 67/udp 
# SMB ports
EXPOSE 137/udp 138/udp 139/tcp 445/tcp
# NFS ports
EXPOSE 111/tcp 111/udp 2049/tcp 2049/udp

# Use supervisor to manage multiple processes in the container
CMD ["/usr/local/bin/start.sh"]

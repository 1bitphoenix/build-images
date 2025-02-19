FROM ubuntu:18.04

RUN groupadd --gid 1000 builduser \
  && useradd --uid 1000 --gid builduser --shell /bin/bash --create-home builduser \
  && mkdir -p /setup

# Set up TEMP directory
ENV TEMP=/tmp
RUN chmod a+rwx /tmp

# Install Linux packages
RUN echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
RUN dpkg --add-architecture i386
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    libnotify-bin \
    locales \
    lsb-release \
    nano \
    python-dbus \
    python-pip \
    python-setuptools \
    sudo \
    vim-nox \
    wget \
    g++-multilib \
    libgl1:i386 \
    libgtk-3-0:i386 \
    libgdk-pixbuf2.0-0:i386 \
    libdbus-1-3:i386 \
    lsof \
    libgbm1:i386 \
    libfuse2 \
  && curl https://chromium.googlesource.com/chromium/src/+/HEAD/build/install-build-deps.sh\?format\=TEXT | base64 --decode | cat > /setup/install-build-deps.sh \
  && chmod +x /setup/install-build-deps.sh \
  && bash /setup/install-build-deps.sh --syms --no-prompt --no-chromeos-fonts --lib32 --arm \
  && rm -rf /var/lib/apt/lists/*

# No Sudo Prompt
RUN echo 'builduser ALL=NOPASSWD: ALL' >> /etc/sudoers.d/50-builduser \
  && echo 'Defaults    env_keep += "DEBIAN_FRONTEND"' >> /etc/sudoers.d/env_keep

# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs \
  && rm -rf /var/lib/apt/lists/*

# crcmod is required by gsutil, which is used for filling the gclient git cache
RUN pip install -U crcmod

# dbusmock is needed for Electron tests
RUN pip install python-dbusmock==0.20.0

RUN mkdir /tmp/workspace
RUN chown builduser:builduser /tmp/workspace

# Add xvfb init script
ADD tools/xvfb-init.sh /etc/init.d/xvfb
RUN chmod a+x /etc/init.d/xvfb

USER builduser
WORKDIR /home/builduser

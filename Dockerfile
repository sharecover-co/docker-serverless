FROM node:12-stretch

#
# UID, GID on Linux if not the default 1337
ARG USERNAME=sharecover
ARG USER_UID=1337
ARG USER_GID=$USER_UID

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Suppress an apt-key warning about standard out not being a terminal. Use in this script is safe.
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn

# Configure apt and install packages
RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils 2>&1 \
# Install pre-requisite packages
    && apt-get -y install \
        curl \
        git \
        groff \
        iproute2 \
        less \
        locales \
        lsb-release \
        procps \
        sudo \
        unzip \
        wget \
# Creata a non-root user
    && groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
# Setup a locale compatible with perl/brew
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
# Clean up layer
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Ensure we have a locale so perl/brew don't complain
ENV LANG en_US.utf8

#
# Install awscli
RUN apt-get update && apt-get -y install python3-pip \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && pip3 install awscli \
    && rm -rf /var/lib/apt/lists/*
#
# Install Python3
RUN apt-get update && apt-get -y install python3 python3-pip \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
#
# Install Serverless Framework
RUN npm install -g serverless
#
# Docker Compose version
ARG COMPOSE_VERSION=1.24.1
#
# Install Docker CE CLI
RUN apt-get update \
    && apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common lsb-release \
    && curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | apt-key add - 2>/dev/null \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    #
    # Install Docker Compose
    && curl -sSL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
#
# Install Google Chrome
RUN apt-get update \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -y google-chrome-unstable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf \
      --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*
#
# Install Cypress dependencies
RUN apt-get update \
    && apt-get -y install libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 libxtst6 xauth xvfb
#
# Upgrade base packages
RUN apt-get -y upgrade \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Switch to the created user
USER $USERNAME
WORKDIR /opt/app
#
# Ensure our user can access /var/run/docker.sock for docker-in-docker support
RUN echo "# Ensure we can use docker-in-docker" >> ~/.bashrc \
    && echo "test -f /var/run/docker.sock && sudo chmod o+rw /var/run/docker.sock" >> ~/.bashrc
#
# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog
ENV AWS_SDK_LOAD_CONFIG=1

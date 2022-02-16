FROM ubuntu:14.04

# This is the release of Vault to pull in.
ARG VSH_VERSION=0.2.1


RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
    apt-get update -y && \
    apt-get install -y wget unzip openssh-server sudo && \
    wget -O /tmp/dumb-init.deb https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_amd64.deb && \
    wget https://releases.hashicorp.com/vault-ssh-helper/${VSH_VERSION}/vault-ssh-helper_${VSH_VERSION}_linux_amd64.zip && \
    dpkg -i /tmp/dumb-init.deb && \
    unzip vault-ssh-helper_${VSH_VERSION}_linux_amd64.zip -d /usr/local/bin/ && \
    chmod 0755 /usr/local/bin/vault-ssh-helper && \
    chown root:root /usr/local/bin/vault-ssh-helper

RUN useradd -m -d /home/ubuntu -s /bin/bash -U -G sudo -u 1000 ubuntu 
RUN service ssh start

EXPOSE 22

COPY run.sh ./
CMD ./run.sh
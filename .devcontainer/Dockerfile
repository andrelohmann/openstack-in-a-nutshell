FROM ubuntu:latest

ARG USERNAME=vscode
ARG USER_UID=1001
ARG USER_GID=$USER_UID

USER root

ENV DEBIAN_FRONTEND noninteractive

RUN apt update \
    && apt install --no-install-recommends -y locales \
    && rm -rf /var/lib/apt/lists/* \
    && echo "LC_ALL=en_US.UTF-8" >> /etc/environment \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "LANG=en_US.UTF-8" > /etc/locale.conf

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN apt upgrade -y

RUN apt update \
    && apt install -y sudo wget curl nano git iputils-ping \
    && apt install -y python3-pip pipx sshpass python3-jmespath

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USERNAME -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

COPY requirements.txt .
    
RUN pip3 install -r  requirements.txt --break-system-packages --root-user-action=ignore

#USER vscode

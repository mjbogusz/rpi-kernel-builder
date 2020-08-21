from ubuntu:20.04

MAINTAINER mjbogusz

ENV DEBIAN_FRONTEND noninteractive

RUN apt update && apt install -y git-core kernel-package gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf build-essential libncurses-dev bc u-boot-tools wget unzip bison flex kernel-package libssl-dev

COPY docker_files/run.sh /run.sh
COPY docker_files/linux_rt.config /linux_rt.config

ENTRYPOINT ["/run.sh"]

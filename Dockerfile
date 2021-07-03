from ubuntu:20.04

MAINTAINER mjbogusz

ENV DEBIAN_FRONTEND="noninteractive"

ARG NO_APT_CACHE=0
RUN apt -q update \
	&& apt upgrade -qy \
	&& apt install -qy \
		bc \
		bison \
		build-essential \
		flex \
		gcc-aarch64-linux-gnu \
		gcc-arm-linux-gnueabihf \
		git-core \
		kernel-package \
		kernel-package \
		libncurses-dev \
		libssl-dev \
		rsync \
		u-boot-tools \
		unzip \
		wget \
	&& rm -rf /var/lib/apt/lists/*

COPY docker_files/run.sh /run.sh
COPY docker_files/linux_rt.config /linux_rt.config

ENTRYPOINT ["/run.sh"]

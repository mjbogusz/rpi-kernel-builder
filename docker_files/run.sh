#!/bin/sh

set -e

print_help() {
	/bin/echo -e "Usage:"
	/bin/echo -e "$0 [build_options]"
	/bin/echo -e "\n build_options:"
	/bin/echo -e "\t (--full-clone) do a full git clone; increases time and space requirements! (default: shallow clone)"
	/bin/echo -e "\t (--64|--arm64|--aarch64) build a 64-bit version (default: build a 32-bit version)"
	/bin/echo -e "\t (--rt|--realtime) build an RT version (default: build a non-RT version"
	/bin/echo -e "\t (--rt-patch|--rtpatch|--realtime-patch PATCHSET) use the specified realtime PATCHSET (default: '5.4.58-rt35')"
	/bin/echo -e "\t (--branch BRANCHNAME) use the BRANCHNAME branch from https://github.com/raspberrypi/linux (default: rpi-5.4.y)"
	# /bin/echo -e "\t "
}

# Parse build options
FULL_CLONE=false
ARM64=false
RT=false
RT_PATCH="5.4.58-rt35"
BRANCH="rpi-5.4.y"

while [ "$#" -gt 0 ]; do
	case $1 in
		-h|--help)
			print_help
			exit 0
		;;
		--FULL_CLONE)
			FULL_CLONE=true
			shift
		;;
		--64|--arm64|--aarch64)
			ARM64=true
			shift
		;;
		--rt|--realtime)
			RT=true
			shift
		;;
		--rt-patch|--rtpatch|--realtime-patch)
			RT_PATCH="$2"
			shift 2
		;;
		--branch)
			BRANCH="$2"
			shift 2
		;;
		*)
			echo "Unknown option: $1"
			print_help
			exit 1
		;;
	esac
done

# Get the sources
if [ "$FULL_CLONE" = true ]; then
	git clone https://github.com/raspberrypi/linux.git -b $BRANCH
else
	git clone --single-branch --depth=1 https://github.com/raspberrypi/linux.git -b $BRANCH
fi

# Optionally: Download and apply the RT patchset
if [ "$RT" = true ]; then
	patch_branch=$(echo "5.4.58-rt35" | cut -c 1-3)
	wget "http://cdn.kernel.org/pub/linux/kernel/projects/rt/${patch_branch}/patch-${RT_PATCH}.patch.gz" -O /linux-rt.patch.gz
	cd /linux
	gzip -cd /linux-rt.patch.gz | patch -p1 --verbose
fi

# Prepare build
if [ "$ARM64" = true ]; then
	export ARCH=arm64
	export KPKG_ARCH=arm64
	export CROSS_COMPILE=aarch64-linux-gnu-
	export CC=${CROSS_COMPILE}gcc
	export $(dpkg-architecture -a arm64)
else
	export ARCH=arm
	export KPKG_ARCH=arm
	export CROSS_COMPILE=arm-linux-gnueabihf-
	export CC=${CROSS_COMPILE}gcc
	export $(dpkg-architecture -a armhf)
fi
cd /linux
make -j`nproc` bcm2711_defconfig

# Optionally: Patch config for RT
if [ "$RT" = true ]; then
	cd /linux
	cp .config .config.nonrt
	# Use the config merger script shipped with kernel sources
	# linux_rt.config comes from a diff generated after manually toggling the RT_PREEMPT flag in menuconfig
	scripts/kconfig/merge_config.sh -m .config /linux_rt.config
fi

# Build the kernel
cd /linux
# Plain build (disabled)
# make -j`nproc`
# KPKG build (build and create DEBs)
make-kpkg -j`nproc` kernel_image kernel_headers kernel_source

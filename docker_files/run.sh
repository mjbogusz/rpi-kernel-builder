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
	/bin/echo -e "\t (--revision REVISION) package version revision (default: 1)"
	/bin/echo -e "\t (--version-append APPEND) string to append to the kernel version (default: \"\")"
	# /bin/echo -e "\t "
}

# Parse build options
FULL_CLONE=false
ARM64=false
RT=false
RT_PATCH="5.10.47-rt45"
BRANCH="rpi-5.10.y"
REVISION="1"
APPEND=""

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
		--revision)
			REVISION="$2"
			shift 2
		;;
		--version-append)
			APPEND="$2"
			shift 2
		;;
		*)
			echo "Unknown option: $1"
			print_help
			exit 1
		;;
	esac
done

# Stage 1: Get the sources
echo -e "\n######\n Stage 1/4: retrieving the Linux source\n######\n"
if [ "$FULL_CLONE" = true ]; then
	git clone https://github.com/raspberrypi/linux.git -b $BRANCH
else
	git clone --single-branch --depth=1 https://github.com/raspberrypi/linux.git -b $BRANCH
fi
# Remove the .git directory (it causes make-kpkg to include an extraneous '+' in the package name)
rm -rf linux/.git

# Stage 1.1: (Optionally) Download and apply the RT patchset
echo -e "\n######\n Stage 1.1/4: retrieving and applying the linux-rt patchset\n######\n"
if [ "$RT" = true ]; then
	patch_branch=$(echo ${RT_PATCH} | cut -d . -f 1-2 )
	wget "http://cdn.kernel.org/pub/linux/kernel/projects/rt/${patch_branch}/older/patch-${RT_PATCH}.patch.gz" -O /linux-rt.patch.gz
	cd /linux
	gzip -cd /linux-rt.patch.gz | patch -p1
fi

# Prepare the environment and config
echo -e "\n######\n Stage 2/4: preparing the environment and config\n######\n"
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
echo -e "\n######\n Stage 2.1/4: applying the linux-rt patchset\n######\n"
if [ "$RT" = true ]; then
	cd /linux
	cp .config .config.nonrt
	# Use the config merger script shipped with kernel sources
	# linux_rt.config comes from a diff generated after manually toggling the RT_PREEMPT flag in menuconfig
	scripts/kconfig/merge_config.sh -m .config /linux_rt.config
fi

# Build the kernel
echo -e "\n######\n Stage 3/4: building the Linux kernel\n######\n"
cd /linux
# Plain build (disabled)
# make -j`nproc`
# KPKG build (build and create DEBs)
KPKG_ARGS="-j`nproc` --revision=${REVISION}"
if [ -n "${APPEND}" ]; then
	KPKG_ARGS="${KPKG_ARGS} --append-to-version=${APPEND}"
fi
make-kpkg ${KPKG_ARGS} kernel_image kernel_headers kernel_source

echo -e "\n######\n Stage 4/4: saving the packages\n######\n"
mkdir -p /packages
cp /*.deb /packages/

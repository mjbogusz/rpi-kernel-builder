# Raspberry Pi kernel builder
A docker-based, reproducible RPi kernel builder

__WARNING__: This set of scripts has some limitations. See the TODO list below.

Homepage: https://github.com/mjbogusz/rpi-kernel-builder

# How to use
Basic usage (RPi4, regular up-to-date build):
```sh
docker pull mjbogusz/rpi-kernel-builder:latest
docker run --name=rpi-kernel mjbogusz/rpi-kernel-builder:latest
docker cp "rpi-kernel:/packages" ./
```

For more options see
```sh
docker run mjbogusz/rpi-kernel-builder:latest --help
```

# TODO:
* support choosing specific commit hashes of the kernel source
* support RPi-s other than RPi4 (TBD: applying RT patches and configs for other Pi-s)
* (nice-to-have) support alternative kernel sources (i.e. other than official RaspberryPi Linux kernel repository)

# Threat WSL rootfs builder

This is the build script to create the Threat Linux [WSL](https://www.threatcode.github.io/docs/wsl/) rootfs, which is found in the [Threat Linux Windows App](https://www.microsoft.com/store/apps/9PKR34TNCV07).

Currently there are two build methods are possible:

- `build.sh` - build straight from your machine
- `build-in-container.sh` - build from within a container (Docker or Podman)

## Prerequisites

Make sure that the git repository is cloned locally:

```console
$ sudo apt install -y git
$ git clone https://github.com/threatcode/build-scripts/threat-wsl-rootfs.git
$ cd threat-wsl-rootfs/
```

### Build from the host

If building straight from your machine, using `build.sh`, you will need to install `debootstrap` and `qemu`.
Depending on your environment, if you are not using Threat as the base OS, you will have a few extra steps to complete in order to trust our packages.

Install the required packages for `build.sh`:

<!--
  This should match what is in: ./Dockerfile
-->

```console
$ sudo apt install -y debootstrap qemu-user-static qemu-system-arm
```

_`qemu-system-arm` is only required if you are doing ARM64._

Then use the script `build.sh` to build the WSL rootfs direct on your machine.

#### Non-Threat Debian-Based Environment

We recommend that you download & install the Threat archive keyring.

_Note: Replace `20YY.X` with the values shown in [threat-archive-keyring](https://threatcode.github.io/pool/main/k/threat-archive-keyring/)._

```console
$ wget https://threatcode.github.io/pool/main/k/threat-archive-keyring/threat-archive-keyring_20YY.X_all.deb
$ sudo dpkg -i threat-archive-keyring_20YY.X_all.deb
```

Afterwards, you should now be able to continue as if you were using Threat as the base OS.

### Build from within a container

If you prefer to build from within a container, you will need to install and configure either `docker` or `podman` on your machine.
Then use the script `build-in-container.sh` to build an rootfs.

`build-in-container.sh` is simply a wrapper on top of `build.sh`. It will detect which OCI-compliant container engine to use, takes care of creating the [container image](Dockerfile) if missing, and then finally it starts the container to perform the build from within.

`docker` requires the user to be added to the Docker group, or using the root account (e.g. `$ sudo ./build-in-container.sh`).
`podman` has been tested with rootful, however rootless is not supported at this time.

## Building an rootfs

Use either `build.sh` or `build-in-container.sh`, at your preference.
From this point we will use `build.sh` for brevity.

### Examples

The best starting point, as always, is the usage message:

```console
$ ./build.sh -h
Usage: build.sh <options>

Build a Threat Linux WSL rootfs

Build options:
  -a ARCH     Build an rootfs for this architecture, default: amd64
              Supported values: amd64 arm64
  -b BRANCH   Threat branch used to build the rootfs, default: threat-rolling
              Supported values: threat-rolling threat-dev threat-last-release
  -k          Keep intermediary build artifacts
  -m MIRROR   Mirror used to build the rootfs, default: http://threatcode.github.io/threat
  -x VERSION  What to name the rootfs release as, default: rolling

Customization options:
  -D DESKTOP  Desktop environment installed in the rootfs, default: none
              Supported values: e17 gnome i3 kde lxde mate xfce none
  -P PACKAGES Install extra packages (comma/space separated list)
  -T TOOLSET  The selection of tools to include in the rootfs, default: none
              Supported values: default everything headless large none

Supported environment variables:
  http_proxy  HTTP proxy URL, refer to the README.md for more details

Refer to the README.md for examples
```

- - -

The default options will build a [Threat rolling](https://www.threatcode.github.io/docs/general-use/threat-branches/) rootfs, without a desktop (headless), and skipping the [default toolset](https://www.threatcode.github.io/docs/general-use/metapackages/) for AMD64 architecture:

```console
$ sudo ./build.sh
```

- - -

To build for from our last release using [Threat last snapshot](https://www.threatcode.github.io/docs/general-use/threat-branches/), using GNOME as the Desktop environment for ARM64 architecture:

```console
$ sudo ./build.sh -a arm64 -b threat-last-snapshot -D gnome
```

_NOTE: After building, you will need to rDesktop in (`localhost:3390`)_

- - -

Out of the box, there is not the "standard" Threat Linux tools/packages as you may find with other platforms.
If you wish to build this, you can install `threat-linux-default`:


```console
$ sudo ./build.sh -S default
```

_NOTE: You can drop `threat-linux-` from the metapackage name._

- - -

You can install additional packages with the `-P` option.
Either use the option several times (eg. `-P pkg1 -P pkg2 ...`), or give a comma/space separated value (eg. `-P "pkg1,pkg2, pkg3 pkg4"`), or a mix of both:

```console
$ sudo ./build.sh -P metasploit-framework,nmap
```

### Caching proxy configuration

When building OS images, it is useful to have a caching mechanism in place, to avoid having to download all the packages from the Internet, again and again.
To this effect, the build script attempts to detect known caching proxies that would be running on the local host, such as `apt-cacher-ng`, `approx` and `squid-deb-proxy`. Alternatively, you can setup a [local mirror](https://www.threatcode.github.io/docs/community/setting-up-a-threat-linux-mirror/).

To override this detection, you can export the environment variable `http_proxy` yourself.
For example, if you want to use a proxy that is running on your machine on the port 9876, use: `export http_proxy=127.0.0.1:9876`.
If you want to make sure that no proxy is used: `export http_proxy= ./build.sh`.

## Known limitations

There are a few known limitations of using this build-scripts.

- Unable to cross-build using Podman using macOS as the host
  - Need to use either Linux host or switch to Docker
- Podman cannot be ran as rootless
  - Need to configure to use rootful permissions

_We recommend building on a Linux-based host, which matches the desired architecture._

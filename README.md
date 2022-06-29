# Kali-WSL-chroot

Kali Linux Windows App for WSL chroot, builder script.

## Install

### Non-Kali Debian-Based Environment

We recommend that you download & install the Kali archive keyring:

```console
# wget https://http.kali.org/pool/main/k/kali-archive-keyring/kali-archive-keyring_20YY.X_all.deb
# dpkg -i kali-archive-keyring_20YY.X_all.deb
```

_Note: Replace `20YY.X` with the values from [kali-archive-keyring](https://http.kali.org/pool/main/k/kali-archive-keyring/)_

Afterwards, you should now be able to continue as if you were using Kali as the base OS!

### Kali

Install the required packages:

```console
# apt install -y  debootstrap  qemu-user-static qemu-system-arm  git
# git clone https://gitlab.com/kalilinux/build-scripts/kali-wsl-chroot.git
# cd kali-wsl-chroot/
```

## Build

To build x64 and ARM64 chroots:

```console
# ./build_chroot.sh
```

Afterwards, the files will be in the same directory:

```
# ls ARM64/ x64/
ARM64/:
install.tar.gz

x64/:
install.tar.gz
```

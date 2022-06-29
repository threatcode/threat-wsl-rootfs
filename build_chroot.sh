#!/bin/bash

set -e

BUILDIR=$(pwd)
TMPDIR_x64=$(mktemp -d)
TMPDIR_ARM64=$(mktemp -d)
MIRROR_REPO="http.kali.org"
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# create_rootfs <x64|ARM64>
create_rootfs() {
  ARCH=${1:-x64}

  echo -e "\n  [i] Bootstrapping a base Kali install ($ARCH)"
  if [ "$ARCH" == "ARM64" ]; then
    cd "$TMPDIR_ARM64/"
    ## Because we're using a foreign architecture (arm64 on amd64) we have to do the debootstrap in 2 stages
    LANG=C debootstrap --foreign --arch arm64 kali-rolling ./kali-root "http://$MIRROR_REPO/kali"
    cp -v /usr/bin/qemu-aarch64-static kali-root/usr/bin
    LANG=C chroot kali-root /debootstrap/debootstrap --second-stage
  elif [ "$ARCH" == "x64" ]; then
    cd "$TMPDIR_x64/"

    LANG=C debootstrap kali-rolling ./kali-root "http://$MIRROR_REPO/kali"
  else
    echo "[-] Unsupported architecture" >&2
    exit 1
  fi

  echo -e "\n  [i] Setting chroot's DNS"
  cat << EOF > kali-root/etc/resolv.conf
nameserver 8.8.8.8
EOF

  echo -e "\n  [i] Setting environment variables"
  export MALLOC_CHECK_=0 # workaround for LP: #520465 (https://bugs.launchpad.net/ubuntu/+bug/520465)
  export LC_ALL=C
  export DEBIAN_FRONTEND=noninteractive

  echo -e "\n  [i] Mounting for chroot"
  mount -v -t proc proc kali-root/proc
  mount -v -o bind /dev/ kali-root/dev/
  mount -v -o bind /dev/pts kali-root/dev/pts

  echo -e "\n  [i] Creating second-stage"
  cat << EOF > kali-root/second-stage
#!/bin/bash
apt-get update
apt-get --yes install locales-all mlocate sudo net-tools wget host dnsutils whois curl kali-defaults
#apt-get --yes --force-yes install kali-desktop-xfce xorg xrdp
rm -rf /root/.bash_history
apt-get clean
apt-get autoremove

rm -f /0
rm -f /hs_err*
rm -f /cleanup
rm -f /usr/bin/qemu*

updatedb
EOF

  echo -e "\n  [i] Executing second-stage (in chroot)"
  chmod -v +x kali-root/second-stage
  LANG=C chroot kali-root /second-stage

  #echo -e "\n  [i] Setting up xrdp"
  #sed -i 's/port=3389/port=3390/g' kali-root/etc/xrdp/xrdp.ini

  echo -e "\n  [i] Unmounting chroot"
  umount -v kali-root/dev/pts
  sleep 3
  umount -v kali-root/dev
  sleep 10
  umount -v kali-root/proc
  sleep 5

  echo -e "\n  [i] Cleaning up"
  # cd kali-root
  rm -vrf kali-root/second-stage
  rm -vrf kali-root/etc/resolv.conf
  rm -vrf kali-root/usr/bin/qemu-aarch64-static

  echo -e "\n  [i] Setting repo source"
  cat <<EOF > kali-root/etc/apt/sources.list
deb http://http.kali.org/kali kali-rolling main non-free contrib
#deb-src http://http.kali.org/kali kali-rolling main non-free contrib
EOF

  echo -e "\n  [i] Setting shell profile"
  cat << EOF > kali-root/etc/profile
# /etc/profile: system-wide .profile file for the Bourne shell (sh(1))
# and Bourne compatible shells (bash(1), ksh(1), ash(1), ...).

IS_WSL=`grep -i microsoft /proc/version` # WSL already sets PATH, shouldn't be overridden
if test "$IS_WSL" = ""; then
  if [ "`id -u`" -eq 0 ]; then
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  else
    PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games"
  fi
fi
export PATH

if [ "${PS1-}" ]; then
  if [ "${BASH-}" ] && [ "$BASH" != "/bin/sh" ]; then
    # The file bash.bashrc already sets the default PS1.
    # PS1='\h:\w\$ '
    if [ -f /etc/bash.bashrc ]; then
      . /etc/bash.bashrc
    fi
  else
    if [ "`id -u`" -eq 0 ]; then
      PS1='# '
    else
      PS1='$ '
    fi
  fi
fi

if [ -d /etc/profile.d ]; then
  for i in /etc/profile.d/*.sh; do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi
EOF

  echo -e "\n  [i] Compressing chroot: $BUILDIR/$ARCH/install.tar.gz"
  mkdir -vp "$BUILDIR/$ARCH/"
  cd kali-root/
  tar --ignore-failed-read -czf "$BUILDIR/$ARCH/install.tar.gz" ./*
}

echo -e "\n  [i] Kali WSL (Chroot)"

create_rootfs x64
create_rootfs ARM64

echo -e "\n  [i] Cleaning up temporary build folders"
rm -rf "$TMPDIR_x64/"
rm -rf "$TMPDIR_ARM64/"

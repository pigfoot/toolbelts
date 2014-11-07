#!/usr/bin/env bash

set -e

#STAGE3_DATE=20141030
STAGE3_DATE=

TMP_IMG_FILE=./gentoo-image.fs
TMP_IMG_DIR=./gentoo-image

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

function _update_latest_version {
    sed -i "/^#STAGE3_DATE=[0-9.a-zA-Z]*$/s/STAGE3_DATE=[0-9.a-zA-Z]*/STAGE3_DATE=${STAGE3_DATE}/" ${0}
}

function _check_if_root() {
    if [[ $EUID -ne 0 ]]; then

        echo "This script must be run as root"
        exit
    fi
}

function _find_stage3_date() {
    local _ver_msg
    if [[ -z ${STAGE3_DATE} ]]; then
        STAGE3_DATE=$(curl -sk 'http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-nomultilib/' | sed -rn 's@^.*"stage3-amd64-nomultilib-([[:digit:].]+)\.tar\.bz2".*$@\1@p' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | sed '$!d')
        _ver_msg="(${STAGE3_DATE})"
    else
        _ver_msg="(${STAGE3_DATE}, assigned)"
    fi
    STAGE3_URL="http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-nomultilib/stage3-amd64-nomultilib-${STAGE3_DATE}.tar.bz2"
    STAGE3_FILE=${STAGE3_URL##*/}
    STAGE3_DIR=${STAGE3_FILE%.*.*}
    #echo "stage3 url: ${STAGE3_URL} ${_ver_msg}"
}

function _check_if_latest() {
    local CUR_STAGE3_DATE=$(sed -rn 's@^#STAGE3_DATE=([[:digit:]]*)$@\1@p' ${0})
    local CUR_VER=(${CUR_STAGE3_DATE})
    local REMOTE_VER=(${STAGE3_DATE})
    if [[ ${CUR_VER} -ge ${REMOTE_VER} ]]; then
        echo "Current version is latest: ${CUR_STAGE3_DATE}"
        exit
    else
        echo "Find newer version ${STAGE3_DATE}, current is ${CUR_STAGE3_DATE}"
    fi
}

function _create_from_scratch() {
    dd if=/dev/zero of=${TMP_IMG_FILE} bs=1M count=4192
    _LODEV=`losetup --find --show ${TMP_IMG_FILE}`
    mkfs.btrfs -L ROOT ${_LODEV}
    mkdir -p ${TMP_IMG_DIR}-raw
    mount -t btrfs -o defaults,noatime,compress=lzo,autodefrag ${_LODEV} ${TMP_IMG_DIR}-raw
    mkdir -p ${TMP_IMG_DIR}
    btrfs subvol create ${TMP_IMG_DIR}-raw/root
    mount -t btrfs -o defaults,noatime,compress=lzo,autodefrag,subvol=root ${_LODEV} ${TMP_IMG_DIR}
    btrfs subvol create ${TMP_IMG_DIR}-raw/home
    mkdir -p ${TMP_IMG_DIR}/home
    mount -t btrfs -o defaults,noatime,compress=lzo,autodefrag,subvol=home ${_LODEV} ${TMP_IMG_DIR}/home

    # Extract stage3
    wget -O - ${STAGE3_URL} | tar -jxvf - -C "${TMP_IMG_DIR}"
    # Extract portage
    wget -O - http://distfiles.gentoo.org/snapshots/portage-latest.tar.xz | tar -Jxvf - -C "${TMP_IMG_DIR}/usr"
    # Extract pre-built kernel
    local KER_VER=$(curl -sk 'https://github.com/pigfoot/ec2-gentoo-kernels/releases' | sed -rn 's@^.*"\/pigfoot\/ec2-gentoo-kernels\/releases\/download\/v([[:digit:].]+)/kernel-genkernel-x86_64-([[:digit:].]+)-gentoo\.tar\.xz".*$@\1@p' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | sed '$!d')
    local KER_URL="https://github.com/pigfoot/ec2-gentoo-kernels/releases/download/v${KER_VER}/kernel-genkernel-x86_64-${KER_VER}-gentoo.tar.xz"
    curl -sLk ${KER_URL} | tar -Jxvf - -C "${TMP_IMG_DIR}"
    # Change ext4 to btrfs
    sed -ie '/root\=LABEL\=\/ rootfstype\=ext4$/s@root\=LABEL\=\/ rootfstype\=ext4@root\=LABEL\=root rootfstype\=btrfs rootflags=subvol=root,compress=lzo@' ${TMP_IMG_DIR}/boot/grub/menu.lst
}

function _bootstraping() {
    local _TMP_BUILD_SCRIPT="${TMP_IMG_DIR}/tmp/bootstraping.sh"

    # modify /etc/fstab
    echo "/etc/fstab"
    sed -i \
        -e '/^\/dev\/BOOT/d' \
        -e '/^\/dev\/SWAP/d' \
        -e '/^\/dev\/cdrom/d' \
        -e '/^\/dev\/fd0/d' \
        -e '/^\/dev\/ROOT/s/ext3/btrfs/' \
        -e '/^\/dev\/ROOT/s@/dev/ROOT@LABEL=ROOT@' ${TMP_IMG_DIR}/etc/fstab

    mkdir -p ${TMP_IMG_DIR}/etc/local.d
    echo "/etc/local.d/makeopts.start"
     cat << EOF > ${TMP_IMG_DIR}/etc/local.d/makeopts.start
# /etc/local.d/makeopts.start

# get physical cpus from lscpu
_SKTS="$(lscpu | sed -rn 's@^(CPU\s+)?[Ss]ocket\(s\):\s+(.*)$@\2@p')"

# get cores per socket from lscpu
_CORS="$(lscpu | sed -rn 's@^[Cc]ore\(s\) per socket:\s+(.*)$@\1@p')"

# multiply sockets * cores +1
CORES="$((${_SKTS}*${_CORS}+1))"
THDS="$((${CORES}+1))"

sed -i \\
    -e '/^MAKEOPTS=.*$/s@(-j|--jobs=)=[0-9]\+[[:blank:]]*@ @' \\
    -e '/^MAKEOPTS=.*$/s@--load-average=[0-9\.]\+[[:blank:]]*@ @' \\
    -e "/^MAKEOPTS=.*$/s/[[:blank:]]*\"$/ --jobs=${CORES} --load-average=${THDS}.0\"/" /etc/portage/make.conf
EOF
    chmod 755 ${TMP_IMG_DIR}/etc/local.d/makeopts.start

    # Customized portage
    mkdir -p ${TMP_IMG_DIR}/etc/portage
    echo "/etc/portage/package.keywords"
    cat << EOF > /etc/portage/package.keywords
app-admin/amazon-ec2-init ~amd64
EOF

    echo "/etc/portage/package.use"
    cat << EOF > ${TMP_IMG_DIR}/etc/portage/package.use
mail-mta/nullmailer -ssl # avoid install gnutls
dev-vcs/git -cgi -perl -gpg
EOF

    echo "/etc/portage/make.conf"
    sed -i -e '/^CFLAGS=\"-O2 -pipe\"$/s/-O2 -pipe/-march=native -ggdb -O3 -pipe -fomit-frame-pointer/' /etc/portage/make.conf
    cat << EOF >> ${TMP_IMG_DIR}/etc/portage/make.conf

# Customized config
ACCEPT_LICENSE="Oracle-BCLA-JavaSE"
MAKEOPTS="--with-bdeps y --jobs=2 --load-average=3.0"
FEATURES="splitdebug installsources"

USE="cjk threads aio idn vim-syntax bash-completion lzma \\
     python go lto \\
     mysql git sqlite \\
     php cgi fastcgi -cli authfile charconv bzip2 curl ctype tokenizer \\
     -alsa -cups -X"

#source /var/lib/layman/make.conf
EOF

    cat << EOF >> ${TMP_IMG_DIR}/var/lib/portage/world
app-admin/amazon-ec2-init
app-admin/sudo
app-admin/syslog-ng
app-editors/vim
app-misc/screen
app-portage/gentoolkit
dev-vcs/git
net-misc/curl
net-misc/dhcpcd
net-misc/ntp
EOF

    cat << EOF > ${_TMP_BUILD_SCRIPT}
#!/bin/bash

env-update
source /etc/profile
#emerge --sync

# eselect profile list
eselect profile set default/linux/amd64/13.0/no-multilib

EOF

# Networking
ln -s net.lo /etc/init.d/net.eth0
rc-update add net.eth0 default
rc-update add sshd default

# time zone
ln -sf /usr/share/zoneinfo/Asia/Taipei /etc/localtime
sed -i -e '/clock=\"UTC\"$/s/UTC/local/' conf.d/hwclock

# Essential packages
emerge -av amazon-ec2-init
rc-update add amazon-ec2 default

EOF

}

_chroot() {
    local _TMP_BUILD_SCRIPT="/tmp/bootstraping.sh"

    mount -t proc none ./proc
    mount --rbind /dev ./dev
    cp -L /etc/resolv.conf ./etc/
#    chroot ./ /bin/bash -c "su - -c ${_TMP_BUILD_SCRIPT}"
#    umount -l ./dev
#    umount ./proc
#    rm -rfv ./root/.bash_history ./etc/resolv.conf ./usr/portage/distfiles/* ./tmp/*
}

_check_if_root
_find_stage3_date
_check_if_latest
_create_from_scratch
_bootstraping
#_chroot
#_update_latest_version

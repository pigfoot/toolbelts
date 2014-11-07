#!/usr/bin/env bash

# Author: Descartes Chen
# Version: v1.6
# ChangeLog:
#    v1.6 (20140625): make gdb dynamic linked, and add git && curl
#    v1.5 (20140410): make gdb statically linked & fine tuning and bug fixing
#    v1.4 (20140227): add gdb and make gcc is statically linked with libgmp, libmpfr and libmpc
#    v1.3 (20140217): Add "--with-dwarf2" to configure gcc and "-ggdb -gdwarf-2" to enforce libstdlic++ to generate DWARF 2 debug symbol
#    v1.2 (20131206): use "sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n" instead of "sort -V" because it's supported in coreutils in centos
#    v1.1 (20131106): Initialized version
#
# time ./gcctoolchain.sh 2>&1 | tee >(bzip2 -c > Build.log.bz2)
#

## Predefine fixed version
#
#GMP_VER=
#MPFR_VER=
#MPC_VER=
#ZLIB_VER=
#BINUTILS_VER=
#GCC_VER=
#EXPAT_VER=
#GDB_VER=
#OPENSSL_VER=
#CURL_VER=
#GIT_VER=
#CMAKE_VER=
GMP_VER=
MPFR_VER=
MPC_VER=
BINUTILS_VER=
GCC_VER=
EXPAT_VER=
OPENSSL_VER=
CURL_VER=
GIT_VER=
CMAKE_VER=

OUT=${OUT:-/opt}
MAKEOPT=${MAKEOPT:--j4}

## guessing gmp
function _find_gmp_version {
    local _ver_msg
    if [[ -z ${GMP_VER=""} ]]; then
        GMP_VER=$(curl -sk 'http://ftp.gnu.org/gnu/gmp/' | sed -rn 's@^.*"gmp-(.*)\.tar\.bz2".*$@\1@p' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | sed '$!d')
        _ver_msg="(${GMP_VER})"
    else
        _ver_msg="(${GMP_VER}, assigned)"
    fi
    GMP_URL="http://ftp.gnu.org/gnu/gmp/gmp-${GMP_VER}.tar.bz2"
    GMP_FILE=${GMP_URL##*/}
    _GMP_DIR=${GMP_FILE%.*.*}
    GMP_DIR=${_GMP_DIR%[:alpha:]}
    echo "gmp: ${GMP_URL} ${_ver_msg}"
}

function _find_mpfr_version {
    local _ver_msg
    if [[ -z ${MPFR_VER=""} ]]; then
        MPFR_VER=$(curl -sk 'http://ftp.gnu.org/gnu/mpfr/' | sed -rn 's@^.*"mpfr-(.*)\.tar\.bz2".*$@\1@p' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | sed '$!d')
        _ver_msg="(${MPFR_VER})"
    else
        _ver_msg="(${MPFR_VER}, assigned)"
    fi
    MPFR_URL="http://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VER}.tar.bz2"
    MPFR_FILE=${MPFR_URL##*/}
    _MPFR_DIR=${MPFR_FILE%.*.*}
    MPFR_DIR=${_MPFR_DIR%[:alpha:]}
    echo "mpfr: ${MPFR_URL} ${_ver_msg}"
}

function _find_mpc_version {
    local _ver_msg
    if [[ -z ${MPC_VER=""} ]]; then
        MPC_VER=$(curl -sk 'http://ftp.gnu.org/gnu/mpc/' | sed -rn 's@^.*"mpc-(.*)\.tar\.gz".*$@\1@p' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | sed '$!d')
        _ver_msg="(${MPC_VER})"
    else
        _ver_msg="(${MPC_VER}, assigned)"
    fi
    MPC_URL="http://ftp.gnu.org/gnu/mpc/mpc-${MPC_VER}.tar.gz"
    MPC_FILE=${MPC_URL##*/}
    _MPC_DIR=${MPC_FILE%.*.*}
    MPC_DIR=${_MPC_DIR%[:alpha:]}
    echo "mpc: ${MPC_URL} ${_ver_msg}"
}

function _find_zlib_version {
    local _ver_msg
    if [[ -z ${ZLIB_VER=""} ]]; then
        ZLIB_VER=$(curl -sk 'http://sourceforge.net/projects/libpng/files/zlib/' | sed -rn 's@^.*"/projects/libpng/files/zlib/(.*)/".*$@\1@p' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | sed '$!d')
        _ver_msg="(${ZLIB_VER})"
    else
        _ver_msg="(${ZLIB_VER}, assigned)"
    fi
    ZLIB_URL="http://sourceforge.net/projects/libpng/files/zlib/${ZLIB_VER}/zlib-${ZLIB_VER}.tar.gz"
    ZLIB_FILE=${ZLIB_URL##*/}
    _ZLIB_DIR=${ZLIB_FILE%.*.*}
    ZLIB_DIR=${_ZLIB_DIR%[:alpha:]}
    echo "zlib: ${ZLIB_URL} ${_ver_msg}"
}

## guessing binutils
function _find_binutils_version {
    local _ver_msg
    if [[ -z ${BINUTILS_VER=""} ]]; then
        BINUTILS_VER=$(curl -sk 'http://ftp.gnu.org/gnu/binutils/' | sed -rn 's@^.*"binutils-(.*)\.tar\.bz2".*$@\1@p' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | sed '$!d')
        _ver_msg="(${BINUTILS_VER})"
    else
        _ver_msg="(${BINUTILS_VER}, assigned)"
    fi
    BINUTILS_URL="http://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VER}.tar.bz2"
    BINUTILS_FILE=${BINUTILS_URL##*/}
    _BINUTILS_DIR=${BINUTILS_FILE%.*.*}
    BINUTILS_DIR=${_BINUTILS_DIR%[:alpha:]}
    echo "binutils: ${BINUTILS_URL} ${_ver_msg}"
}

function _find_gcc_version {
    local _ver_msg
    if [[ -z ${GCC_VER=""} ]]; then
        GCC_VER=$(curl -sk 'http://ftp.gnu.org/gnu/gcc/' | sed -rn 's@^.*"gcc-(.*)\/".*$@\1@p' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | sed '$!d')
        _ver_msg="(${GCC_VER})"
    else
        _ver_msg="(${GCC_VER}, assigned)"
    fi
    GCC_URL="http://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.bz2"
    GCC_FILE=${GCC_URL##*/}
    _GCC_DIR=${GCC_FILE%.*.*}
    GCC_DIR=${_GCC_DIR%[:alpha:]}
    echo "gcc: ${GCC_URL} ${_ver_msg}"
}

function _find_expat_version {
    local _ver_msg
    if [[ -z ${EXPAT_VER=""} ]]; then
        EXPAT_VER=$(curl -sk 'http://sourceforge.net/projects/expat/files/expat/' | sed -rn 's@^.*"/projects/expat/files/expat/(.*)/".*$@\1@p' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | sed '$!d')
        _ver_msg="(${EXPAT_VER})"
    else
        _ver_msg="(${EXPAT_VER}, assigned)"
    fi
    EXPAT_URL="http://sourceforge.net/projects/expat/files/expat/${EXPAT_VER}/expat-${EXPAT_VER}.tar.gz"
    EXPAT_FILE=${EXPAT_URL##*/}
    _EXPAT_DIR=${EXPAT_FILE%.*.*}
    EXPAT_DIR=${_EXPAT_DIR%[:alpha:]}
    echo "expat: ${EXPAT_URL} ${_ver_msg}"
}

function _find_gdb_version {
    local _ver_msg
    if [[ -z ${GDB_VER=""} ]]; then
        GDB_VER=$(curl -sk 'http://ftp.gnu.org/gnu/gdb/' | sed -rn 's@^.*"gdb-(.*)\.tar\.bz2".*$@\1@p' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | sed '$!d')
        _ver_msg="(${GDB_VER})"
    else
        _ver_msg="(${GDB_VER}, assigned)"
    fi
    GDB_URL="http://ftp.gnu.org/gnu/gdb/gdb-${GDB_VER}.tar.bz2"
    GDB_FILE=${GDB_URL##*/}
    _GDB_DIR=${GDB_FILE%.*.*}
    GDB_DIR=${_GDB_DIR%[:alpha:]}
    echo "gdb: ${GDB_URL} ${_ver_msg}"
}

function _find_openssl_version {
    local _ver_msg
    if [[ -z ${OPENSSL_VER=""} ]]; then
        OPENSSL_VER=$(curl -sk 'https://www.openssl.org/source/' | sed -rn 's@^.*<font color="#cc3333">openssl-(.*)\.tar\.gz<\/font>.*[LATEST].*$@\1@p')
        _ver_msg="(${OPENSSL_VER})"
    else
        _ver_msg="(${OPENSSL_VER}, assigned)"
    fi
    OPENSSL_URL="http://ftp.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz"
    OPENSSL_FILE=${OPENSSL_URL##*/}
    OPENSSL_DIR=${OPENSSL_FILE%.*.*}
    echo "openssl: ${OPENSSL_URL} ${_ver_msg}"
}

function _find_curl_version {
    local _ver_msg
    if [[ -z ${CURL_VER=""} ]]; then
        CURL_VER=$(curl -sk 'http://curl.haxx.se/download.html' | sed -rn 's@^.*"\/download\/curl-(.*)\.tar\.bz2".*$@\1@p')
        _ver_msg="(${CURL_VER})"
    else
        _ver_msg="(${CURL_VER}, assigned)"
    fi
    CURL_URL="http://curl.haxx.se/download/curl-${CURL_VER}.tar.bz2"
    CURL_FILE=${CURL_URL##*/}
    _CURL_DIR=${CURL_FILE%.*.*}
    CURL_DIR=${_CURL_DIR%[:alpha:]}
    echo "curl: ${CURL_URL} ${_ver_msg}"
}

function _find_git_version {
    local _ver_msg
    if [[ -z ${GIT_VER=""} ]]; then
        GIT_VER=$(curl -s -k 'https://github.com/git/git/releases' | sed -rn 's@^.*"\/git\/git\/archive\/v([[:digit:].]+)\.tar\.gz".*$@\1@p' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | sed '$!d')
        _ver_msg="(${GIT_VER})"
    else
        _ver_msg="(${GIT_VER}, assigned)"
    fi
    GIT_URL="https://github.com/git/git/archive/v${GIT_VER}.tar.gz"
    GIT_FILE="git-${GIT_VER}.tar.gz"
    _GIT_DIR=${GIT_FILE%.*.*}
    GIT_DIR=${_GIT_DIR%[:alpha:]}
    echo "git: ${GIT_URL} ${_ver_msg}"
}

function _find_cmake_version {
    local _ver_msg
    if [[ -z ${CMAKE_VER=""} ]]; then
        CMAKE_VER=$(curl -sk 'http://www.cmake.org/cmake/resources/software.html' | sed -rn 's@^.*<td><a href="http:\/\/www.cmake.org\/files\/v[0-9.a-zA-Z]*/cmake-([0-9.a-zA-Z]*).tar.gz">cmake-[0-9.a-zA-Z]*.tar.gz</a></td>.*$@\1@p' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | sed '$!d')
        _ver_msg="(${CMAKE_VER})"
    else
        _ver_msg="(${CMAKE_VER}, assigned)"
    fi
    IFS=. read -r -a _CMAKE_VERS <<< "${CMAKE_VER}"
    CMAKE_URL="http://www.cmake.org/files/v${_CMAKE_VERS[0]}.${_CMAKE_VERS[1]}/cmake-${CMAKE_VER}.tar.gz"
    CMAKE_FILE=${CMAKE_URL##*/}
    _CMAKE_DIR=${CMAKE_FILE%.*.*}
    CMAKE_DIR=${_CMAKE_DIR%[:alpha:]}
    echo "cmake: ${CMAKE_URL} ${_ver_msg}"
}

function _determine_os_cflags {
    if [[ $(uname -m) == "x86_64" ]]; then
        _arch="x86_64"
        BUILD="x86_64-pc-linux-gnu"
        MULTILIB="--enable-multilib"
        ABI=""
        export _CFLAGS="-O3 -pipe -fomit-frame-pointer -fPIC -ggdb -gdwarf-2"
    else
        # set CFLAGS will cause build problem in 32 bits unless set ABI=32
        _arch="i686"
        BUILD="i686-pc-linux-gnu"
        MULTILIB="--disable-multilib"
        ABI="ABI=32"
        export _CFLAGS="-O3 -pipe -fomit-frame-pointer -fPIC -ggdb -gdwarf-2"
    fi

    if [[ -r "/etc/redhat-release" ]]; then
        _distro=$(cat /etc/redhat-release)
        _distro=$(echo ${_distro} | sed -r 's@CentOS release ([0-9])+((\.?[0-9]+))? .*@\1@g')
        _distro=$(echo ${_distro} | sed -r 's@Red Hat Enterprise.*release ([0-9])+((\.?[0-9]+))? .*@\1@g')
    fi

    if [[ -z ${_distro} ]]; then
        EXTRA_VER="linux.${_arch}"
    else
        EXTRA_VER="el${_distro}.${_arch}"
    fi

    if [[ ${_distro} -le 4 ]]; then
        MPFR_DISABLE_THD_SAFE="--disable-thread-safe"
    else
        MPFR_DISABLE_THD_SAFE=
    fi

    #echo "${_CFLAGS}, ${EXTRA_VER}"
}

function _determine_cflags {
    # Check whether -static-libstdc++ -static-libgcc is supported

    IFS=. read -r -a _CXX_VERS <<< "$(g++ --version | sed -rn 's@^g\+\+ \(GCC\) ([[:digit:].]+).*$@\1@p')"

    if [[ ${_CXX_VERS[0]} -lt 4 || ${_CXX_VERS[0]} -eq 4 && ${_CXX_VERS[1]} -lt 5 ]]; then
        export CFLAGS="-static-libgcc ${_CFLAGS}"
        export CXXFLAGS="-static-libgcc ${_CFLAGS}" # Necessary otherwise -fPIC doesn't work
    else
        export CFLAGS="-static-libgcc ${_CFLAGS}"
        export CXXFLAGS="-static-libstdc++ -static-libgcc ${_CFLAGS}" # Necessary otherwise -fPIC doesn't work
    fi
}

function _determine_script_version {
    _script_version=$(cat ${0} | sed -rn 's@^#    v([0-9]+(\.?[0-9]+))? .*@\1@p' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | sed '$!d')
    export SCRIPT_VER=${_script_version}
}

function _determine_glibc_version {
    _glibc_version=$(ldd /bin/bash | grep libc.so | cut -d ' ' -f 3 | /bin/bash | head -n 1 | sed -rn 's@^.*version ([[:digit:].]+).*@\1@p')
    export GLIBC_VER=${_glibc_version}
}

function detect_environment {
    _find_gmp_version
    _find_mpfr_version
    _find_mpc_version
    _find_zlib_version
    _find_binutils_version
    _find_gcc_version
    _find_expat_version
    _find_gdb_version
    _find_openssl_version
    _find_curl_version
    _find_git_version
    _find_cmake_version
    _determine_os_cflags
    _determine_script_version
    _determine_glibc_version

    _REDIST="${PWD}/redist"
    [[ ! -d ${_REDIST} ]] && mkdir -p "${_REDIST}"

    # Workaround for gcc library path (maybe multilib side-effect?)
    # new gcc: $ LIBRARY_PATH=/redist/lib /opt/pdk-1.6/bin/gcc -print-search-dirs
    #          library path order is /redist/lib/x86_64-pc-linux-gnu/4.9.0/ then /redist/lib/../lib64/
    #          No "/redist/lib" !!
    if [[ $(uname -m) == "x86_64" && ! -h "${_REDIST}/lib" ]]; then
        [[ ! -d ${_REDIST}/lib64 ]] && mkdir -p "${_REDIST}/lib64"
        ln -sf lib64 "${_REDIST}/lib"
    fi

    _OUT="${OUT}/pdk"
    _OUT_ALIAS="${_OUT}-${SCRIPT_VER}"
    [[ ! -d ${_OUT_ALIAS} ]] && mkdir -p "${_OUT_ALIAS}"
    [[ ! -h ${_OUT} ]] && ln -s "${_OUT_ALIAS}" "${_OUT}"

    PATH=${_OUT}/bin:${_REDIST}/bin:${PATH}

    export C_INCLUDE_PATH="${_REDIST}/include"
    export CPLUS_INCLUDE_PATH="${C_INCLUDE_PATH}"
    export LIBRARY_PATH="${_REDIST}/lib"
    export CMAKE_PREFIX_PATH="${_REDIST}"
    export CMAKE_LIBRARY_PATH="${LIBRARY_PATH}"
}

function untar {
    local _file=${1}
    local _extra_conf=${2}

    if [[ ${_file} =~ ^.*\.tar\.gz$ ]]; then
        echo "tar -zxvf ${_file} ${_extra_conf}"
        tar -zxvf ${_file} ${_extra_conf}
    elif [[ ${_file} =~ ^.*\.tar\.bz2$ ]]; then
        echo "tar -jxvf ${_file} ${_extra_conf}"
        tar -jxvf ${_file} ${_extra_conf}
    elif [[ ${_file} =~ ^.*\.tar*\.xz$ ]]; then
        echo "tar -Jxvf ${_file} ${_extra_conf}"
        tar -Jxvf ${_file} ${_extra_conf}
    else
        echo "undetermined archiver."
        exit
    fi
}

# vercomp 1            1            => 1
# vercomp 2.1          2.2          => 0
# vercomp 3.0.4.10     3.0.4.2      => 1
# vercomp 4.08         4.08.01      => 0
# vercomp 3.2.1.9.8144 3.2          => 1
# vercomp 3.2          3.2.1.9.8144 => 0
# vercomp 1.2          2.1          => 0
# vercomp 2.1          1.2          => 1
# vercomp 5.6.7        5.6.7        => 1
# vercomp 1.01.1       1.1.1        => 0 (!)
# vercomp 1            1.0          => 0 (!)
# vercomp 1.0          1            => 1
# vercomp 1.0.2.0      1.0.2        => 1
# vercomp 1..0         1.0          => 1
# vercomp 1.0          1..0         => 0 (!)
#
function vercomp {
    if [[ "$1" == $(echo -e "${1}\n${2}" | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | sed '$!d') ]]; then
        return 1
    else
        return 0
    fi
}

function fetch {
    local _url="${1}"
    local _file="${2}"

    if [[ ${_FORCE_OLD_CURL} ]]; then
        if [[ -z ${_file} ]]; then
            _file=$(curl -sLIk ${_url} | sed -rn 's@^Content-Disposition: .*filename=(.*)\"?$@\1@p')
        fi
        if [[ -z ${_file} ]]; then
            echo "XXXX curl -sLOk \"${_url}\""
            curl -sLOk "${_url}"
            if [ $? != 0 ]; then
                echo "XXXX download file failed from ${_url}."
                exit 1
            fi
        else
            echo "XXXX curl -sLOk \"${_url}\" -o \"${_file}\""
            curl -sLOk "${_url}" -o "${_file}"
            if [ $? != 0 ]; then
                echo "XXXX download file failed from ${_url}."
                exit 1
            fi
        fi
        return
    fi

    if [[ ! -x ${_REDIST}/bin/curl ]]; then
        _FORCE_OLD_CURL=1
        build_curl_possible
        _FORCE_OLD_CURL=
    fi

    if [[ -n ${_file} ]]; then
        echo "XXXX ${_REDIST}/bin/curl -sLJOk \"${_url}\" -o \"${_file}\""
        ${_REDIST}/bin/curl -sLJOk "${_url}" -o "${_file}"
        if [ $? != 0 ]; then
            echo "XXXX download file failed from ${_url}."
            exit 1
        fi
    else
        echo "XXXX ${_REDIST}/bin/curl -sLJOk \"${_url}\""
        ${_REDIST}/bin/curl -sLJOk "${_url}"
        if [ $? != 0 ]; then
            echo "XXXX download file failed from ${_url}."
            exit 1
        fi
    fi
}

function build_prerequisite {
    _determine_cflags

    if [[ ! -r "${_REDIST}/lib/libgmp.a" && ! -r "${_REDIST}/lib/libgmp.so" ]]; then
        [[ ! -d ${GMP_DIR} && ! -f ${GMP_FILE} ]] && fetch "${GMP_URL}"
        [[ ! -d ${GMP_DIR} ]] && untar "${GMP_FILE}"
        [[ -d ${GMP_DIR}-objdir ]] && rm -rf "${GMP_DIR}-objdir"
        mkdir -p "${GMP_DIR}-objdir"
        echo "XXXX pushd \"${GMP_DIR}-objdir\" && \"../${GMP_DIR}/configure\" --prefix=${_REDIST} --enable-static --disable-shared ${ABI} && make ${MAKEOPT} all && make install && popd"
        pushd "${GMP_DIR}-objdir" && "../${GMP_DIR}/configure" --prefix=${_REDIST} --enable-static --disable-shared ${ABI} && make ${MAKEOPT} all && make install && popd
        if [[ $? -ne 0 ]]; then
            echo "make ${GMP_DIR} failed!"
            exit
        fi
    fi

    if [[ ! -r "${_REDIST}/lib/libmpfr.a" && ! -r "${_REDIST}/lib/libmpfr.so" ]]; then
        [[ ! -d ${MPFR_DIR} && ! -f ${MPFR_FILE} ]] && fetch "${MPFR_URL}"
        [[ ! -d ${MPFR_DIR} ]] && untar "${MPFR_FILE}"
        [[ -d ${MPFR_DIR}-objdir ]] && rm -rf "${MPFR_DIR}-objdir"
        mkdir -p "${MPFR_DIR}-objdir"
        echo "XXXX pushd \"${MPFR_DIR}-objdir\" && \"../${MPFR_DIR}/configure\" --prefix=${_REDIST} --enable-static --disable-shared ${MPFR_DISABLE_THD_SAFE} ${ABI} --with-gmp=${_REDIST} && make ${MAKEOPT} all && make install && popd"
        pushd "${MPFR_DIR}-objdir" && "../${MPFR_DIR}/configure" --prefix=${_REDIST} --enable-static --disable-shared ${MPFR_DISABLE_THD_SAFE} ${ABI} --with-gmp=${_REDIST} && make ${MAKEOPT} all && make install && popd
        if [[ $? -ne 0 ]]; then
            echo "make ${MPFR_DIR} failed!"
            exit
        fi
    fi

    if [[ ! -r "${_REDIST}/lib/libmpc.a" && ! -r "${_REDIST}/lib/libmpc.so" ]]; then
        [[ ! -d ${MPC_DIR} && ! -f ${MPC_FILE} ]] && fetch "${MPC_URL}"
        [[ ! -d ${MPC_DIR} ]] && untar "${MPC_FILE}"
        [[ -d ${MPC_DIR}-objdir ]] && rm -rf "${MPC_DIR}-objdir"
        mkdir -p "${MPC_DIR}-objdir"
        echo "XXXX pushd \"${MPC_DIR}-objdir\" && \"../${MPC_DIR}/configure\" --prefix=${_REDIST} --enable-static --disable-shared ${ABI} --with-mpfr=${_REDIST} --with-gmp=${_REDIST} && make ${MAKEOPT} all && make install && popd"
        pushd "${MPC_DIR}-objdir" && "../${MPC_DIR}/configure" --prefix=${_REDIST} --enable-static --disable-shared ${ABI} --with-mpfr=${_REDIST} --with-gmp=${_REDIST} && make ${MAKEOPT} all && make install && popd
        if [[ $? -ne 0 ]]; then
            echo "make ${MPC_DIR} failed!"
            exit
        fi
    fi
}

function build_zlib_possible {
    _determine_cflags

    if [[ ! -r "${_REDIST}/lib/libz.a" && ! -r "${_REDIST}/lib/libz.so" ]]; then
        [[ ! -d ${ZLIB_DIR} && ! -f ${ZLIB_FILE} ]] && fetch "${ZLIB_URL}"
        [[ ! -d ${ZLIB_DIR} ]] && untar "${ZLIB_FILE}"
        echo "XXXX pushd \"${ZLIB_DIR}\" && ./configure --prefix=${_REDIST} --static && make ${MAKEOPT} all && make install && popd"
        pushd "${ZLIB_DIR}" && ./configure --prefix=${_REDIST} --static && make ${MAKEOPT} all && make install && popd
        if [[ $? -ne 0 ]]; then
            echo "make ${ZLIB_DIR} failed!"
            exit
        fi
    fi
}

function cleanup {
    echo "XXXX pushd \"${ZLIB_DIR}\" && make uninstall && popd"
    pushd "${ZLIB_DIR}" && make uninstall && popd
    rm -rf "${ZLIB_FILE}" "${ZLIB_DIR}"
    echo "XXXX pushd \"${MPC_DIR}-objdir\" && make uninstall && popd"
    pushd "${MPC_DIR}-objdir" && make uninstall && popd
    rm -rf "${MPC_FILE}" "${MPC_DIR}" "${MPC_DIR}-objdir"
    echo "XXXX pushd \"${MPFR_DIR}-objdir\" && make uninstall && popd"
    pushd "${MPFR_DIR}-objdir" && make uninstall && popd
    rm -rf "${MPFR_FILE}" "${MPFR_DIR}" "${MPFR_DIR}-objdir"
    echo "XXXX pushd \"${GMP_DIR}-objdir\" && make uninstall && popd"
    pushd "${GMP_DIR}-objdir" && make uninstall && popd
    rm -rf "${GMP_FILE}" "${GMP_DIR}" "${GMP_DIR}-objdir"
    rm -rf ${_REDIST}

    rm -rf "${CMAKE_FILE}" "${CMAKE_DIR}" "${CMAKE_DIR}-objdir"
    rm -rf "${GIT_FILE}" "${GIT_DIR}" "${GIT_DIR}-objdir"
    rm -rf "${CURL_FILE}" "${CURL_DIR}" "${CURL_DIR}-objdir"
    rm -rf "${OPENSSL_FILE}" "${OPENSSL_DIR}"
    rm -rf "${GDB_FILE}" "${GDB_DIR}" "${GDB_DIR}-objdir"
    rm -rf "${EXPAT_FILE}" "${EXPAT_DIR}" "${EXPAT_DIR}-objdir"
    rm -rf "${GCC_FILE}" "${GCC_DIR}" "${GCC_DIR}-objdir"
    rm -rf "${BINUTILS_FILE}" "${BINUTILS_DIR}" "${BINUTILS_DIR}-objdir"
}

function strip_all {
    _out=${1}

    if [[ -x ${_out}/bin/strip ]]; then
        _STRIP="${_out}/bin/strip"
        strip "${_out}/bin/strip"
    else
        _STRIP="strip"
    fi

    if [[ -d ${_out} ]]; then
        [[ -x ${_out}/bin/strip ]] && _STRIP="${_out}/bin/strip"
        echo "find \"${_out}/\" -type f -perm -o+x ! -iname "*strip" ! -iname "*.la" ! -iname "*.py" -print0 | xargs -0 \"${_STRIP}\" -s"
        find "${_out}/" -type f -perm -o+x ! -iname "*strip" ! -iname "*.la" ! -iname "*.py" ! -iname "*.sh" -print0 | xargs -0 "${_STRIP}" -s
    fi
}

function update_latest_version {
    sed -i "/^#GMP_VER=[0-9.a-zA-Z]*$/s/GMP_VER=[0-9.a-zA-Z]*/GMP_VER=${GMP_VER}/" ${0}
    sed -i "/^#MPFR_VER=[0-9.a-zA-Z]*$/s/MPFR_VER=[0-9.a-zA-Z]*/MPFR_VER=${MPFR_VER}/" ${0}
    sed -i "/^#MPC_VER=[0-9.a-zA-Z]*$/s/MPC_VER=[0-9.a-zA-Z]*/MPC_VER=${MPC_VER}/" ${0}
    sed -i "/^#ZLIB_VER=[0-9.a-zA-Z]*$/s/ZLIB_VER=[0-9.a-zA-Z]*/ZLIB_VER=${ZLIB_VER}/" ${0}
    sed -i "/^#BINUTILS_VER=[0-9.a-zA-Z]*$/s/BINUTILS_VER=[0-9.a-zA-Z]*/BINUTILS_VER=${BINUTILS_VER}/" ${0}
    sed -i "/^#GCC_VER=[0-9.a-zA-Z]*$/s/GCC_VER=[0-9.a-zA-Z]*/GCC_VER=${GCC_VER}/" ${0}
    sed -i "/^#EXPAT_VER=[0-9.a-zA-Z]*$/s/EXPAT_VER=[0-9.a-zA-Z]*/EXPAT_VER=${EXPAT_VER}/" ${0}
    sed -i "/^#GDB_VER=[0-9.a-zA-Z]*$/s/GDB_VER=[0-9.a-zA-Z]*/GDB_VER=${GDB_VER}/" ${0}
    sed -i "/^#OPENSSL_VER=[0-9.a-zA-Z]*$/s/OPENSSL_VER=[0-9.a-zA-Z]*/OPENSSL_VER=${OPENSSL_VER}/" ${0}
    sed -i "/^#CURL_VER=[0-9.a-zA-Z]*$/s/CURL_VER=[0-9.a-zA-Z]*/CURL_VER=${CURL_VER}/" ${0}
    sed -i "/^#GIT_VER=[0-9.a-zA-Z]*$/s/GIT_VER=[0-9.a-zA-Z]*/GIT_VER=${GIT_VER}/" ${0}
    sed -i "/^#CMAKE_VER=[0-9.a-zA-Z]*$/s/CMAKE_VER=[0-9.a-zA-Z]*/CMAKE_VER=${CMAKE_VER}/" ${0}
}

function build_binutils {
    _out=${1}

    _determine_cflags
    build_zlib_possible

    [[ ! -d ${BINUTILS_DIR} && ! -f ${BINUTILS_FILE} ]] && fetch "${BINUTILS_URL}"
    [[ ! -d ${BINUTILS_DIR} ]] && untar "${BINUTILS_FILE}"

    [[ -d ${BINUTILS_DIR}-objdir ]] && rm -rf "${BINUTILS_DIR}-objdir"
    mkdir -p "${BINUTILS_DIR}-objdir"
    echo "XXXX pushd \"${BINUTILS_DIR}-objdir\" &&" \
         "\"${PWD}/../${BINUTILS_DIR}/configure\" --prefix=${_out} --build=${BUILD} --enable-static --disable-shared" \
         "--disable-nls ${MULTILIB} &&" \
         "make ${MAKEOPT} all &&" \
         "make install &&" \
         "popd"
    pushd "${BINUTILS_DIR}-objdir" && \
        "${PWD}/../${BINUTILS_DIR}/configure" --prefix=${_out} --build=${BUILD} --enable-static --disable-shared \
            --disable-nls ${MULTILIB} && \
        make ${MAKEOPT} all && \
        make install && \
        popd
    if [[ $? -ne 0 ]]; then
        echo "make ${BINUTILS_DIR} failed!"
        exit
    fi
}

function build_gcc {
    _out=${1}

    _determine_cflags

    # glibc 2.4 is required for GCC 4.9 to build with libsanitizer.
    # As a result, disable libsanitizer in RHEL4.
    #
    # In file included from /projects/gcc-4.9.0-objdir/../gcc-4.9.0/libsanitizer/sanitizer_common/sanitizer_platform_limits_linux.cc:49:0:
    # /projects/gcc-4.9.0/libsanitizer/include/system/linux/aio_abi.h:2:32: fatal error: linux/aio_abi.h: No such file or directory #include_next <linux/aio_abi.h>
    #                            ^
    # compilation terminated.
    # make[4]: *** [sanitizer_platform_limits_linux.lo] Error 1
    # make[4]: Leaving directory `/projects/gcc-4.9.0-objdir/x86_64-pc-linux-gnu/libsanitizer/sanitizer_common'
    # make[3]: *** [all-recursive] Error 1
    # make[3]: Leaving directory `/projects/gcc-4.9.0-objdir/x86_64-pc-linux-gnu/libsanitizer'
    # make[2]: *** [all] Error 2
    # make[2]: Leaving directory `/projects/gcc-4.9.0-objdir/x86_64-pc-linux-gnu/libsanitizer'
    # make[1]: *** [all-target-libsanitizer] Error 2
    # make[1]: Leaving directory `/projects/gcc-4.9.0-objdir'
    # make: *** [all] Error 2
    # make gcc-4.9.0 failed!
    #
    vercomp ${GLIBC_VER} 2.4
    local _GLIBC_GE=$?
    vercomp ${GCC_VER} 4.9.0
    local _GCC490_GE=$?
    [[ ${_GLIBC_GE} -eq 0 && _GCC490_GE -eq 1 ]] && __LIBSANITIZER="--disable-libsanitizer"

    [[ ! -d ${GCC_DIR} && ! -f ${GCC_FILE} ]] && fetch "${GCC_URL}"
    [[ ! -d ${GCC_DIR} ]] && untar "${GCC_FILE}"
    [[ -d ${GCC_DIR}-objdir ]] && rm -rf "${GCC_DIR}-objdir"
    mkdir -p "${GCC_DIR}-objdir"
    echo "XXXX pushd \"${GCC_DIR}-objdir\" &&" \
         "\"${PWD}/../${GCC_DIR}/configure\" --prefix=${_out} --build=${BUILD}" \
         "--disable-nls --without-included-gettext" \
         "--with-system-zlib --enable-obsolete --disable-werror ${MULTILIB} --enable-__cxa_atexit" \
         "--disable-fixed-point --disable-libssp --disable-libquadmath --disable-libmudflap ${__LIBSANITIZER}" \
         "--disable-libgcj --enable-libstdcxx-time" \
         "--enable-languages=c,c++" \
         "--enable-threads=posix --enable-targets=all --with-dwarf2" \
         "--enable-static --disable-shared --with-gmp=${_REDIST} --with-mpfr=${_REDIST} --with-mpc=${_REDIST} &&" \
         "make ${MAKEOPT} all &&" \
         "make install &&" \
         "popd"
    pushd "${GCC_DIR}-objdir" && \
        "${PWD}/../${GCC_DIR}/configure" --prefix=${_out} --build=${BUILD} \
            --disable-nls --without-included-gettext \
            --with-system-zlib --enable-obsolete --disable-werror ${MULTILIB} --enable-__cxa_atexit \
            --disable-fixed-point --disable-libssp --disable-libquadmath --disable-libmudflap ${__LIBSANITIZER} \
            --disable-libgcj --enable-libstdcxx-time \
            --enable-languages=c,c++ \
            --enable-threads=posix --enable-targets=all --with-dwarf2 \
            --enable-static --disable-shared --with-gmp=${_REDIST} --with-mpfr=${_REDIST} --with-mpc=${_REDIST} && \
        make ${MAKEOPT} all && \
        make install && \
        popd
    if [[ $? -ne 0 ]]; then
        echo "make ${GCC_DIR} failed!"
        exit
    fi
}

function build_expat_possible {

    _determine_cflags

    if [[ ! -r "${_REDIST}/lib/libexpat.a" && ! -r "${_REDIST}/lib/libexpat.so" ]]; then
        [[ ! -d ${EXPAT_DIR} && ! -f ${EXPAT_FILE} ]] && fetch "${EXPAT_URL}"
        [[ ! -d ${EXPAT_DIR} ]] && untar "${EXPAT_FILE}"
        [[ -d ${EXPAT_DIR}-objdir ]] && rm -rf "${EXPAT_DIR}-objdir"
        mkdir -p "${EXPAT_DIR}-objdir"
        echo "XXXX pushd \"${EXPAT_DIR}-objdir\" && \"../${EXPAT_DIR}/configure\" --prefix=${_REDIST} --enable-static --disable-shared && make ${MAKEOPT} all && make install && popd"
        pushd "${EXPAT_DIR}-objdir" && "../${EXPAT_DIR}/configure" --prefix=${_REDIST} --enable-static --disable-shared && make ${MAKEOPT} all && make install && popd
        if [[ $? -ne 0 ]]; then
            echo "make ${EXPAT_DIR} failed!"
            exit
        fi
    fi
}

function build_texinfo_possible {

    _determine_cflags

    # gdb depends on latet texinfo 4.x for makeinfo or it will build failed (RHEL-4.0 is buggy)
    if [[ "${EXTRA_VER%.*}" -eq "el4"  && ! -x "${_REDIST}/bin/makeinfo" ]]; then
        [[ ! -d "texinfo-4.13" && ! -f "texinfo-4.13a.tar.gz" ]] && fetch "http://ftp.gnu.org/gnu/texinfo/texinfo-4.13a.tar.gz"
        [[ ! -d "texinfo-4.13" ]] && untar "texinfo-4.13a.tar.gz"
        [[ -d "texinfo-4.13-objdir" ]] && rm -rf "texinfo-4.13-objdir"
        mkdir -p "texinfo-4.13-objdir"
        echo "XXXX pushd \"texinfo-4.13-objdir\" &&" \
             "\"${PWD}/../texinfo-4.13/configure\" --prefix=${_REDIST} &&" \
             "make ${MAKEOPT} all &&" \
             "make install &&" \
             "popd"
        pushd "texinfo-4.13-objdir" && \
            "${PWD}/../texinfo-4.13/configure" --prefix=${_REDIST} && \
            make ${MAKEOPT} all && \
            make install && \
            popd
        if [[ $? -ne 0 ]]; then
            echo "make texinfo-4.13 failed!"
            exit
        fi
    fi
}

function build_gdb {
    _out=${1}

    _determine_cflags
    build_texinfo_possible
    build_zlib_possible
    build_expat_possible

    [[ ! -d ${GDB_DIR} && ! -f ${GDB_FILE} ]] && fetch "${GDB_URL}"
    [[ ! -d ${GDB_DIR} ]] && untar "${GDB_FILE}"
    [[ -d ${GDB_DIR}-objdir ]] && rm -rf "${GDB_DIR}-objdir"
    mkdir -p "${GDB_DIR}-objdir"
    echo "XXXX pushd \"${GDB_DIR}-objdir\" &&" \
         "\"${PWD}/../${GDB_DIR}/configure\" --prefix=${_out} --build=${BUILD}" \
         "--disable-nls ${MULTILIB} --with-libexpat-prefix=${_REDIST}" \
         "--enable-static --disable-shared &&" \
         "make ${MAKEOPT} all &&" \
         "make install &&" \
         "popd"
    pushd "${GDB_DIR}-objdir" && \
        "${PWD}/../${GDB_DIR}/configure" --prefix=${_out} --build=${BUILD} \
            --disable-nls ${MULTILIB} --with-libexpat-prefix=${_REDIST} \
            --enable-static --disable-shared && \
        make ${MAKEOPT} all && \
        make install && \
        popd
    if [[ $? -ne 0 ]]; then
        echo "make ${GDB_DIR} failed!"
        exit
    fi

    rm -rf "texinfo-4.13" "texinfo-4.13-objdir" "texinfo-4.13a.tar.gz"
}

function build_openssl_possible {

    _determine_cflags

    if [[ ! -r "${_REDIST}/lib/libssl.a" && ! -r "${_REDIST}/lib/libssl.so" ]]; then
        [[ ! -d ${OPENSSL_DIR} && ! -f ${OPENSSL_FILE} ]] && fetch "${OPENSSL_URL}"
        [[ -d ${OPENSSL_DIR} ]] && rm -rf ${OPENSSL_DIR}
        untar "${OPENSSL_FILE}"
        echo "XXXX pushd \"${OPENSSL_DIR}\" && ./config --prefix=${_REDIST} no-shared && make all && make install && popd"
        pushd "${OPENSSL_DIR}" && ./config --prefix=${_REDIST} no-shared && make all && make install && popd
        if [[ $? -ne 0 ]]; then
            echo "make ${OPENSSL_DIR} failed!"
            exit
        fi
    fi
}

function build_curl_possible {

    _determine_cflags
    build_openssl_possible

    if [[ ! -r "${_REDIST}/lib/libcurl.a" && ! -r "${_REDIST}/lib/libcurl.so" ]]; then
        [[ ! -d ${CURL_DIR} && ! -f ${CURL_FILE} ]] && fetch "${CURL_URL}"
        [[ ! -d ${CURL_DIR} ]] && untar "${CURL_FILE}"
        [[ -d ${CURL_DIR}-objdir ]] && rm -rf "${CURL_DIR}-objdir"
        # workaround for detect customized static openssl library
        sed -ri '/[::space::]*LIBS="\$SSL_LIBS \$LIBS"[::space::]*$/s@\$SSL_LIBS@\$SSL_LIBS -ldl@' "${CURL_DIR}/configure"
        sed -ri '/[::space::]*LIBS="\$SSL_LIBS \$LIBS"[::space::]*$/s@\$SSL_LIBS@\$SSL_LIBS -ldl@' "${CURL_DIR}/configure.ac"
        mkdir -p "${CURL_DIR}-objdir"
        echo "XXXX pushd \"${CURL_DIR}-objdir\" &&" \
             "\"../${CURL_DIR}/configure\" --prefix=${_REDIST}" \
             "--with-ssl=${_REDIST} --without-gssapi --without-libssh2 --without-libidn --disable-ldap" \
             "--enable-static --disable-shared &&" \
             "make ${MAKEOPT} all &&" \
             "make install &&" \
             "popd"
        pushd "${CURL_DIR}-objdir" && \
            "../${CURL_DIR}/configure" --prefix=${_REDIST} \
                --with-ssl=${_REDIST} --without-gssapi --without-libssh2 --without-libidn --disable-ldap \
                --enable-static --disable-shared && \
            make ${MAKEOPT} all && \
            make install && \
            popd
        if [[ $? -ne 0 ]]; then
            echo "make ${CURL_DIR} failed!"
            exit
        fi
    fi
}

function build_git {
    _out=${1}

    _determine_cflags
    build_curl_possible
    build_expat_possible
    build_zlib_possible

    [[ ! -d ${GIT_DIR} && ! -f ${GIT_FILE} ]] && fetch "${GIT_URL}" "${GIT_FILE}"
    [[ ! -d ${GIT_DIR} ]] && untar "${GIT_FILE}"
    if [[ ! -x ${GIT_DIR}/configure ]]; then
        echo "XXXX pushd \"${GIT_DIR}\" && make configure && popd"
        pushd "${GIT_DIR}" && make configure && popd
    fi
    # workaround for detect customized static openssl library
    sed -ri '/[::space::]*LIBS="-lcurl  \$LIBS"[::space::]*$/s@-lcurl@-lcurl -lz -lssl -lcrypto -ldl -lrt@' "${GIT_DIR}/configure"
    sed -ri '/[::space::]*CURL_LIBCURL = \-L\$\(CURLDIR\)\/\$\(lib\) \$\(CC_LD_DYNPATH\)\$\(CURLDIR\)\/\$\(lib\) \-lcurl[::space::]*$/s@-lcurl@-lcurl -lz -lssl -lcrypto -ldl -lrt@' "${GIT_DIR}/Makefile"
    sed -ri '/[::space::]*OPENSSL_LIBSSL = \-lssl[::space::]*$/s@-lssl@-lssl -ldl@' "${GIT_DIR}/Makefile"
    echo "XXXX pushd \"${GIT_DIR}\" &&" \
         "./configure --prefix=${_out}" \
         "--with-openssl=${_REDIST} --with-curl=${_REDIST} --with-zlib=${_REDIST} --with-expat=${_REDIST} --without-python --without-tcltk NO_PERL=1 BLK_SHA1=1 &&" \
         "make ${MAKEOPT} all &&" \
         "make install &&" \
         "popd"
    pushd "${GIT_DIR}" && \
        ./configure --prefix=${_out} \
            --with-openssl=${_REDIST} --with-curl=${_REDIST} --with-zlib=${_REDIST} --with-expat=${_REDIST} --without-python --without-tcltk NO_PERL=1 BLK_SHA1=1 && \
        make ${MAKEOPT} all && \
        make install && \
        popd
    if [[ $? -ne 0 ]]; then
        echo "make ${GIT_DIR} failed!"
        exit
    fi
}

function build_cmake {
    _out=${1}

    _determine_cflags
    build_curl_possible
    build_expat_possible
    build_zlib_possible

    # Since cmake is c++ program, which is supposed to be statically linked.
    # As a result, new gcc is necessary.

    [[ ! -d ${CMAKE_DIR} && ! -f ${CMAKE_FILE} ]] && fetch "${CMAKE_URL}"
    [[ ! -d ${CMAKE_DIR} ]] && untar "${CMAKE_FILE}"
    [[ -d ${CMAKE_DIR}-objdir ]] && rm -rf "${CMAKE_DIR}-objdir"
    mkdir -p "${CMAKE_DIR}-objdir"
    # reset patch, reference: http://fahdshariff.blogspot.tw/2012/12/sed-mutli-line-replacement-between-two.html
    sed -ri \
        -e '/[::space::]*set\(CURL_LIBRARIES \$\{CURL_LIBRARY\} \$\{SSL_LIBRARY\} \$\{CRYPTO_LIBRARY\} \$\{RT_LIBRARY\}\)/s@\$\{CURL_LIBRARY\} \$\{SSL_LIBRARY\} \$\{CRYPTO_LIBRARY\} \$\{RT_LIBRARY\}@\$\{CURL_LIBRARY\}@' \
        -e '/^find_library\(CRYPTO_LIBRARY/,/^if\(CURL_FOUND\)$/ {/^find_library/N;/^if/!d}' \
        "${CMAKE_DIR}/Modules/FindCURL.cmake"
    # patch
    sed -ri \
        -e '/[::space::]*set\(CURL_LIBRARIES \$\{CURL_LIBRARY\}\)[::space::]*$/s@\$\{CURL_LIBRARY\}@\$\{CURL_LIBRARY\} \$\{SSL_LIBRARY\} \$\{CRYPTO_LIBRARY\} \$\{RT_LIBRARY\}@' \
        -e '/[::space::]*VERSION_VAR CURL_VERSION_STRING\)/a \
\
find_library(SSL_LIBRARY NAMES ssl libssl) \
find_library(CRYPTO_LIBRARY NAMES crypto libcrypto) \
find_library(RT_LIBRARY NAMES rt librt)' \
        "${CMAKE_DIR}/Modules/FindCURL.cmake"

    echo "XXXX pushd \"${CMAKE_DIR}-objdir\" &&" \
         "\"../${CMAKE_DIR}/bootstrap\" --prefix=${_out} --system-curl --system-expat --system-zlib --no-qt-gui &&" \
         "make ${MAKEOPT} all VERBOSE=1 &&" \
         "popd"
    pushd "${CMAKE_DIR}-objdir" && \
        "../${CMAKE_DIR}/bootstrap" --prefix=${_out} --system-curl --system-expat --system-zlib --no-qt-gui && \
        make ${MAKEOPT} all VERBOSE=1 && \
        popd
    if [[ $? -ne 0 ]]; then
        echo "make ${CMAKE_DIR} failed!"
        exit
    fi

    # restore FindCURL.cmake
    untar "${CMAKE_FILE}" "${CMAKE_DIR}/Modules/FindCURL.cmake"

    # Install in the last stage
    echo "XXXX pushd \"${CMAKE_DIR}-objdir\" && make install && popd"
    pushd "${CMAKE_DIR}-objdir" && make install && popd
}

detect_environment
update_latest_version
build_prerequisite
build_binutils "${_OUT}"
build_gcc "${_OUT}"
build_gdb "${_OUT}"
build_git "${_OUT}"
build_cmake "${_OUT}"
cleanup
strip_all "${_OUT}"

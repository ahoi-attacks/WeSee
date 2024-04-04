FROM ubuntu:23.10@sha256:5cd569b792a8b7b483d90942381cd7e0b03f0a15520d6e23fb7a1464a25a71b1


WORKDIR /workdir

COPY linux/guest /workdir/guest
COPY linux/host /workdir/host
COPY ovmf /workdir/ovmf

RUN apt-get update
RUN apt-get install -y gcc make git flex bison openssl libssl-dev libelf-dev libudev-dev libpci-dev libiberty-dev autoconf llvm dpkg-dev bc debhelper rsync kmod cpio zstd python-is-python3 python3 nasm iasl uuid-dev


WORKDIR /workdir/guest
RUN make -j$(nproc)

WORKDIR /workdir/host
RUN make -j$(nproc) deb-pkg LOCALVERSION=-custom

WORKDIR /workdir/ovmf
RUN make -C BaseTools
RUN bash -c ". ./edksetup.sh --reconfig ; nice build -q --cmd-len=64436 -DDEBUG_ON_SERIAL_PORT=TRUE -n $(nproc) -t GCC5 -a X64 -p OvmfPkg/OvmfPkgX64.dsc"

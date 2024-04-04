#!/bin/bash


QEMU_GIT_URL="https://github.com/AMDESE/qemu.git"
OVMF_GIT_URL="https://github.com/AMDESE/ovmf.git"
LINUX_GIT_URL="https://github.com/AMDESE/linux.git"


run_cmd()
{
	echo "$*"

	eval "$*" || {
		echo "ERROR: $*"
		exit 1
	}
}

build_install_qemu()
{
	DEST="${PWD}/qemu_artifacts"

	MAKE="make -j $(getconf _NPROCESSORS_ONLN) LOCALVERSION="

	pushd qemu >/dev/null
		run_cmd CC=gcc-9 ./configure --target-list=x86_64-softmmu --prefix=$DEST --enable-slirp
		run_cmd $MAKE
		run_cmd $MAKE install

		COMMIT=$(git log --format="%h" -1 HEAD)
		run_cmd echo $COMMIT >../source-commit.qemu
	popd >/dev/null
}

if [ -d "linux/guest" ] && [ -d "linux/host" ] && [ -d "qemu" ] && [ -d "ovmf" ]; then
    pushd linux/guest
    echo "Cleaning guest kernel"
    make clean && make mrproper
    popd
    pushd linux/host
    echo "Cleaning host kernel"
    make clean && make mrproper
    popd
else
    git clone ${LINUX_GIT_URL} linux/guest
    cp -r linux/guest linux/host
    git clone  ${QEMU_GIT_URL}
    git clone  ${OVMF_GIT_URL}
fi

cp linux/config/guest.conf linux/guest/.config
cp linux/config/host.conf linux/host/.config

pushd linux/host
git checkout ad9c0bf475ecde466a065af44fc94918f109c4c9
echo "applying host kernel patch"
git apply ../host.patch
popd

pushd linux/guest
git checkout ad9c0bf475ecde466a065af44fc94918f109c4c9
popd

pushd qemu
git checkout 94bec6ae7a81872ca0df2655dac18b2dea8c3090
popd

pushd ovmf
git checkout 80318fcdf1bccf5d503197825d62a157efd27c4b
git submodule update --init --recursive
popd

build_install_qemu

DOCKER_BUILDKIT=1 docker build . --progress=plain -t artifact/intfail:v1.0 --security-opt apparmor=unconfined

id=$(docker create artifact/intfail:v1.0)
docker cp $id:/workdir - > artifact.tar
docker rm -v $id

tar -xvf artifact.tar
rm -f artifact.tar

wget https://cloud.debian.org/images/cloud/trixie/daily/latest/debian-13-generic-amd64-daily.qcow2
virt-customize -a debian-13-generic-amd64-daily.qcow2 --root-password password:1234
sudo virt-copy-in -a debian-13-generic-amd64-daily.qcow2 20-wired.network /etc/systemd/network

mkdir -p qemu_artifacts/etc/qemu
echo 'allow virbr0' > qemu_artifacts/etc/qemu/bridge.conf
# WeSee

See [ahoi-attacks.github.io/wesee](ahoi-attacks.github.io/wesee).

## Overview

We introduce a new attack on AMD SEV SNP VMs, exploiting the VC handler . 
It allows the hypervisor to perform arbitrary memory reads and writes in the guest VM and does not depend on any application software running inside the VM.

## Platform

We ran our experiments on an AMD EPYC 9124 16-Core Processor. Any other AMD SEV SNP capable processor should work as well.

We've build our read / write primitives within the host kernel. We expose an API such that userspace can use read and write primitves. Our proof-of-concept injects shellcode into the CVM that can be triggered with an icmp package. The shellcode opens a shell on port 8001.

## Prerequisites

We performed our experiments on Ubuntu 23.10 as host. Every other version will work as well as long as it is capable of building the pinned `qemu` locally. All other build targets are dockerized.

On Ubuntu 23.10 execute:

`sudo apt-get install git libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev ninja-build gcc-9 make guestfish`

add your user to the docker group and relogin or continue as root

`sudo usermod -a -G docker $USER`

## Build

`./init.sh`

## Install

Install and boot the newly build host kernel. 
```
sudo dpkg -i linux-headers-6.5.0-rc2-snp-host-ad9c0bf475ec-custom_6.5.0-rc2-gad9c0bf475ec-1_amd64.deb
sudo dpkg -i linux-image-6.5.0-rc2-snp-host-ad9c0bf475ec-custom_6.5.0-rc2-gad9c0bf475ec-1_amd64.deb
sudo dpkg -i linux-libc-dev_6.5.0-rc2-gad9c0bf475ec-1_amd64.deb
```
## Boot the guest

If you boot the image for the first time login and install netcat

`apt update; apt install netcat-openbsd`

## Run the Exploit
```bash
cd userspace_vc
make
sudo chmod 666 /dev/kvm
./exploit
```

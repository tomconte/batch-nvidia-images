#!/bin/bash

# add the missing parts to the os image "CentOS-based 7.4 HPC" to make the GPU(s) working
# this script is following the direction provided in https://docs.microsoft.com/en-us/azure/virtual-machines/linux/n-series-driver-setup#

# check if this computer has at least one GPU. If not immediately leave
lspci | grep -i NVIDIA 2>1 >/dev/null || (echo "No GPU found on this system"; exit 2)

# is this Red Hat or CentOS?
[ -z "$(awk -F'=| ' '$1 ~ /^ID_LIKE/ && $2 ~ /rhel/ {print $2}' /etc/os-release)" ] && (echo "Not a Centos or RHEL system"; exit 1)

# check if we are "root"
[ $(whoami) != root ] && SUDO=sudo || SUDO=""

# prep the OS to include kernelmodules a.s.o.
[ $(rpm -qa | grep -i kernel | wc -l) -lt 6 ] || (REBOOTNEEDED="yes"; $SUDO yum install kernel kernel-tools kernel-headers kernel-devel)
#it is suggested that you do a reboot NOW
# reboot

# install epel to install "dkms"
rpm -qa | grep -i dkms >/dev/null || (
  $SUDO rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
  $SUDO yum -y install dkms)

# remove mesa-libGL to solve conflict
$SUDO rpm -e mesa-libGL.x86_64 --nodeps

# install CUDA Repository
CUDA_REPO_PKG=cuda-repo-rhel7-10.0.130-1.x86_64.rpm
rpm -qa | grep ${CUDA_REPO_PKG%.rpm} >/dev/null || ( \
  [ -f /tmp/${CUDA_REPO_PKG} ] || \
  wget http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/${CUDA_REPO_PKG} -O /tmp/${CUDA_REPO_PKG} && \
  $SUDO rpm -ivh /tmp/${CUDA_REPO_PKG} && \
  rm -f /tmp/${CUDA_REPO_PKG} && \
  $SUDO yum -y install cuda-drivers && \
  $SUDO yum -y install cuda )

# blacklist the nouveau driver it is incompatible with the Nvidia driver
[ -f $( find /etc/modprobe.d/ -name \*ouvea\* ) ] || cat << EOF > /etc/modprobe.d/nouveau.conf
blacklist nouveau
blacklist lbm-nouveau
options nouveau modeset=0
EOF

# is there a X server service started
$SUDO systemctl -a | grep lightdm.service && $SUDO systemctl stop lightdm.service

# install NVIDIA GRID driver if on NV6/12/24
which nvidia-smi 2>1 >/dev/null && nvidia-smi -L | grep M60 >/dev/null && ( \
  wget -O NVIDIA-Linux-x86_64-grid.run "https://go.microsoft.com/fwlink/?linkid=874272" && \
  chmod +x NVIDIA-Linux-x86_64-grid.run && \
  $SUDO ./NVIDIA-Linux-x86_64-grid.run --ui=none --no-questions --run-nvidia-xconfig && \
  rm -f ./NVIDIA-Linux-x86_64-grid.run )

# install Docker-CE
$SUDO yum install -y yum-utils device-mapper-persistent-data lvm2
$SUDO yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
$SUDO yum install -y docker-ce docker-ce-cli containerd.io
$SUDO systemctl enable docker

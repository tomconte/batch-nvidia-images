#!/bin/bash

set -e

# Check for GPU
lspci | grep -q NVIDIA || (echo "No GPU found on this system"; exit 2)

# Install kernel headers and development packages
sudo apt-get update && sudo apt-get install -y linux-headers-$(uname -r)

# Install build tools for use with CUDA (optional)
sudo apt-get install -y build-essential

# (NB: Nouveau driver already blacklisted by default on Ubuntu Azure cloud images)

# By default, install driver bundled with CUDA
INSTALL_CUDA_DRIVER="--driver"

# Install latest NVIDIA GRID driver if on NV6/12/24
lspci | grep -q M60 && ( \
  wget --quiet -O NVIDIA-Linux-x86_64-grid.run "https://go.microsoft.com/fwlink/?linkid=874272" && \
  chmod +x NVIDIA-Linux-x86_64-grid.run && \
  sudo ./NVIDIA-Linux-x86_64-grid.run --ui=none --no-questions --run-nvidia-xconfig && \
  rm -f ./NVIDIA-Linux-x86_64-grid.run \
) && INSTALL_CUDA_DRIVER=""

# Install CUDA (toolkit only if we already installed the GRID driver)
CUDA_INSTALLER=cuda_10.1.243_418.87.00_linux.run
wget --quiet http://developer.download.nvidia.com/compute/cuda/10.1/Prod/local_installers/${CUDA_INSTALLER}
sudo sh ${CUDA_INSTALLER} --silent --toolkit ${INSTALL_CUDA_DRIVER}

# Install the X server and some utilities
sudo apt-get install -y xserver-xorg-core x11-utils x11-apps

# Install Docker CE
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Install nvidia-docker
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit

# Install nvidia-container-runtime
sudo apt-get install nvidia-container-runtime
sudo tee /etc/docker/daemon.json <<EOF
{
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF

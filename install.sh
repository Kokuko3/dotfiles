#!/bin/bash

if [ ! -d /home/mmcdaniel ]; then
   read -p "Home directory for user mmcdaniel not found, enter username:" WHOAMI
else
   WHOAMI=mmcdaniel
fi

USERDIR=/home/$WHOAMI
DOTFILEREPO=https://github.com/mmcdaniel/dotfiles

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root, exiting." 
   exit 1
fi

if [ ! -d $USERDIR/git/dotfiles ]; then
   echo "Cannot find dotfiles repo @ $USERDIR/git/dotfiles, exiting."
   exit 1
fi

install_dependencies() {
#install pre-requisites for vim and environment
apt update && apt install -y \
   vim \
   python \
   python-dev \
   python3-dev \
   build-essential \
   cmake \
   autoconf \
   automake \
   cryptsetup \
   git \
   libfuse-dev \
   libglib2.0-dev \
   libseccomp-dev \
   libtool \
   pkg-config \
   runc \
   squashfs-tools \
   squashfs-tools-ng \
   uidmap \
   wget \
   zlib1g-dev
   

echo "Finished installing pre-requisites"
}

singularity_install() {
echo "Installing Go"
export VERSION=1.21.0 OS=linux ARCH=amd64 && \
    wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz && \
    sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz && \
    rm go$VERSION.$OS-$ARCH.tar.gz
    export PATH=/usr/local/go/bin:${PATH}:${GOPATH}/bin

export VERSION=4.1.0 && \
    wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-${VERSION}.tar.gz && \
    tar -xzf singularity-$VERSION.tar.gz && \
    rm singularity-$VERSION.tar.gz && \
    cd ./singularity && \
    ./mconfig && \
    make -C ./builddir && \
    make -C ./builddir install
    cd ~
    rm -rf ./singularity
}

home_config() {
  ln -sfb ~/git/dotfiles/.bashrc ~/.bashrc
  ln -sfb ~/git/dotfiles/.vimrc ~/.vimrc
  mkdir -p ~/.ssh/
  mkdir -p ~/.singularity/
  ln -sfb ~/git/dotfiles/.ssh/authorized_keys ~/.ssh/authorized_keys
  ln -sfb ~/git/dotfiles/.ssh/config ~/.ssh/config
}
export -f home_config

git_config() {
  git config --global user.email "mcdaniel.121@wright.edu"
  git config --global user.name "Mason McDaniel"
  git config --global core.editor vim
}
export -f git_config

## Install dependencies?
read -p \
  "Install system dependencies? (Y/N): " depconfirm
if [[ $depconfirm == [yY] || $depconfirm == [yY][eE][sS] ]]; then
  install_dependencies
fi

## Install singularity?
read -p \
  "Install Singularity container software? (Y/N): " singconfirm
if [[ $singconfirm == [yY] || $singconfirm == [yY][eE][sS] ]]; then
  singularity_install
fi

## Configure system for mmcdaniel
read -p \
  "Would you like to configure this system for mmcdaniel? (Y/N): " mkconfirm
if [[ $mkconfirm == [yY] || $mkconfirm == [yY][eE][sS] ]]; then
  su -m $WHOAMI -c "bash -c home_config $USERDIR"
  su -m $WHOAMI -c "bash -c git_config"
  su -m $WHOAMI -c "bash -c vim_config"
fi



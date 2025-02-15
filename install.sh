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
   python \
   python-dev \
   python3-dev \
   build-essential \
   cmake \
   dh-autoreconf \
   build-essential \
   libarchive-dev \
   squashfs-tools \
   libncurses5-dev \
   libgtk2.0-dev \
   libatk1.0-dev \
   libcairo2-dev \
   libx11-dev \
   libxpm-dev \
   libxt-dev \
   ruby-dev \
   lua5.1 \
   liblua5.1-0-dev \
   libperl-dev \
   uuid-dev \
   libssl-dev \
   libgpgme11-dev \
   libseccomp-dev \
   pkg-config \
   wget \
   cryptsetup

echo "Finished installing pre-requisites"
}

singularity_install() {
echo "Installing Go"
export VERSION=1.15.2 OS=linux ARCH=amd64 && \
    wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz && \
    sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz && \
    rm go$VERSION.$OS-$ARCH.tar.gz
    export PATH=/usr/local/go/bin:${PATH}:${GOPATH}/bin

export VERSION=3.6.3 && \
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

# vim configuration
vim_config() {
  if [ -d ~/.vim/bundle/Vundle.vim ]; then
    rm -rf ~/.vim/bundle/Vundle.vim
  fi
  git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
  if [ -f ~/.vimrc ]; then
    vim -C PluginInstall
  fi
}
export -f vim_config

# vim needs to be compiled with python support for autocomplete to work
vim_from_src() {
apt remove -y vim vim-runtime gvim && \
cd ~
git clone https://github.com/vim/vim.git
cd vim

## Check Python 2 config, if you want python 3 support a lot of this needs changed...
if [ -d /usr/lib/python3.6/config-3.6m-x86_64-linux-gnu/ ]; then
  PYCONF=/usr/lib/python3.6/config-3.6m-x86_64-linux-gnu
else
  read -p "Standard python 2 config not found ( /usr/lib/python3.6/config-3.6m-x86_64-linux-gnu/ )
  Please locate python 2 config and enter here: " PYCONF \
    && [ -d $PYCONF ] || (echo "$PYCONF not found, exiting." && exit 1)
fi

./configure --with-features=huge \
  --enable-multibyte \
  --enable-rubyinterp=yes \
  --enable-pythoninterp=yes \
  --enable-python3interp=yes \
  --enable-perlinterp=yes \
  --enable-luainterp=yes \
  --enable-gui=gtk2 \
  --enable-cscope \
  --prefix=/usr/local \
  --with-python-config-dir=$PYCONF

make VIMRUNTIMEDIR=/usr/local/share/vim/vim82
make install
update-alternatives --install /usr/bin/editor editor /usr/local/bin/vim 1
update-alternatives --set editor /usr/local/bin/vim
update-alternatives --install /usr/bin/vi vi /usr/local/bin/vim 1
update-alternatives --set vi /usr/local/bin/vim

cd ..
rm -rf ./vim
}

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

## Compile Vim from source?
read -p \
  "Most fancy vim plugins require vim to be compiled with
  python support.  Would you like to uninstall vim and recompile?
  (Y/N): " vimconfirm

if [[ $vimconfirm == [yY] || $vimconfirm == [yY][eE][sS] ]]; then
  vim_from_src
  su -m $WHOAMI -c "bash -c vim_config"
  su -m $WHOAMI -c "python $USERDIR/.vim/bundle/YouCompleteMe/install.py --clang-completer"
else
  su -m $WHOAMI -c "bash -c vim_config"
  su -m $WHOAMI -c "python $USERDIR/.vim/bundle/YouCompleteMe/install.py --clang-completer"
fi

## Configure system for mmcdaniel
read -p \
  "Would you like to configure this system for mmcdaniel? (Y/N): " mkconfirm
if [[ $mkconfirm == [yY] || $mkconfirm == [yY][eE][sS] ]]; then
  su -m $WHOAMI -c "bash -c home_config $USERDIR"
  su -m $WHOAMI -c "bash -c git_config"
  su -m $WHOAMI -c "bash -c vim_config"
fi



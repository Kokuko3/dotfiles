Stolen from @mkijowski 

This repository contains my ~/.vimrc file which I will keep updated here.
Usage instructions:

Step 1: Install prerequisites:
```
sudo apt-get install vim git python3-dev build-essential cmake
git clone git@github.com:VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```
Step 2: Clone this repo
```
git clone git@github.com:Kokuko3/dotfiles.git
mv dotfiles/.bashrc ~/.bashrc
mv dotfiles/.vimrc ~/.vimrc
```
Step 3: Open vim, ignore errors, install plugins using :PluginInstall
```
vim -c 'PluginInstall'
```
 Step 4: upon completion, exit vim and run the following
```
python ~/.vim/bundle/YouCompleteMe/install.py --clang-completer
```
Step 5: Enjoy!


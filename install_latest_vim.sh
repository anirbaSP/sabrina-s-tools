# Create the directories you need
sudo mkdir -p /Users/Sabrina/bin
# Download, compile, and install the latest Vim
cd ~
# hg clone https://bitbucket.org/vim-mirror/vim or 
git clone https://github.com/vim/vim.git

cd vim
./configure --prefix=/Users/Sabrina
make
sudo make install
# Add the binary to your path, ahead of /usr/bin
echo 'export PATH=/Users/Sabrina/bin:$PATH' >> ~/.bash_profile
# Reload bash_profile so the changes take effect in this window
source ~/.bash_profile

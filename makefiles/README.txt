
Tested on Ubuntu 12.04 Desktop 64-bit

cd cocotron/makefiles
make

This will compile cocotron's Foundation using the libobjc2 runtime provided below into a .so and compile a test program against it in test.


PRE-REQUIREMENTS:

sudo apt-get install mercurial -y
sudo apt-get install clang
sudo apt-get install libblocksruntime-dev -y
sudo apt-get install git -y
sudo apt-get install g++


git clone https://github.com/timburks/gnustep-libobjc2.git
echo Installing libobjc2
export CC=clang

cd gnustep-libobjc2
make clean
make
sudo make install


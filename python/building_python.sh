# Install packages to build Python:

apt install -y libffi-dev libffi6 libncurses5 zlib1g-dev wget

yum install -y libffi-devel



# Python Version environment:

read -p 'What is the Python version (X.Y.Z) to download? ' PYTHON_VERSION



# Download the Python source code:

cd /tmp

wget -c https://www.python.org/ftp/python/${PYTHON_VERSION}/\
Python-${PYTHON_VERSION}.tar.xz



# Unpack the file and enter into directory:

tar xf Python-${PYTHON_VERSION}.tar.xz && cd Python-${PYTHON_VERSION}/



# Número de jobs conforme a quantidade cores de CPU (cores + 1):

NJOBS=`expr \`cat /proc/cpuinfo | egrep ^processor | wc -l\` + 1`



# Make Options:

MAKEOPTS="-j${NJOBS}"



# Configure:

./configure \
    --prefix /usr/local/python \
    --includedir /usr/local/include \
    --enable-optimizations



# Make

make && make altinstall



# Profile file:

cat << EOF > /etc/profile.d/python.sh
#!/bin/bash

export PATH="/usr/local/python/bin:\${PATH}"
EOF



# Make a tar package:

tar cvf /tmp/Python-bin-${PYTHON_VERSION}.tar \
/etc/profile.d/python.sh \
/usr/local/{python,include}



# Compact with XZ:

xz -9 /tmp/Python-bin-${PYTHON_VERSION}.tar









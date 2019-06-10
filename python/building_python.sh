# Install packages to build Python:

apt-get update && apt-get install -y \
    lib{ffi6,ncurses5} \
    {libbz2,zlib1g,libssl,libncurses,libffi,uuid,tk}-dev \
    wget gcc g++ make xz-utils

apt clean

yum install -y libffi-devel



# Python Version environment (XYZ):

read -p 'What is the Python version (X.Y.Z) to download? ' PY_VERSION_XYZ



# Python Version environment (XY):

export PY_VERSION_XY=`echo ${PY_VERSION_XYZ} | awk -F '.' '{print $1 "." $2}'`



# Download the Python source code:

cd /tmp

wget -c https://www.python.org/ftp/python/${PY_VERSION_XYZ}/\
Python-${PY_VERSION_XYZ}.tar.xz



# Unpack the file and enter into directory:

tar xf Python-${PY_VERSION_XYZ}.tar.xz && cd Python-${PY_VERSION_XYZ}/



# Número de jobs conforme a quantidade cores de CPU (cores + 1):

export NJOBS=`expr \`cat /proc/cpuinfo | egrep ^processor | wc -l\` + 1`



# Make Options:

export MAKEOPTS="-j${NJOBS}"



# Configure:

./configure \
    --prefix /usr/local/python \
    --includedir /usr/local/include \
    --enable-optimizations \
    --with-lto



# Make

make && make altinstall



# Profile file:

cat << EOF > /etc/profile.d/python.sh && source /etc/profile.d/python.sh
#!/bin/bash

export PATH="/usr/local/python/bin:\${PATH}"
EOF



# Install the last version of PIP:

wget -O- https://bootstrap.pypa.io/get-pip.py | python${PY_VERSION_XY}



# Make a tar package:

tar cvf /tmp/Python-bin-${PY_VERSION_XYZ}.tar \
/etc/profile.d/python.sh \
/usr/local/{python,include}



# Compact with XZ:

xz -9 /tmp/Python-bin-${PY_VERSION_XYZ}.tar









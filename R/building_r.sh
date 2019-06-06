# Install packages to build R:

apt install -y gcc make gfortran libreadline-dev zlib1g-dev libbz2-dev liblzma-dev libpcre-ocaml-dev libcurl-ocaml-dev g++

yum install -y libffi-devel



# Python Version environment:

read -p 'What is the R version (X.Y.Z) to download? ' R_VERSION



# Download the Python source code:

cd /tmp

wget -c https://cloud.r-project.org/src/base/R-${R_VERSION:0:1}/\
R-${R_VERSION}.tar.gz



# Unpack the file and enter into directory:

tar xf R-${R_VERSION}.tar.gz && cd R-${R_VERSION}/



# Configure:

./configure \
    --prefix /usr/local/r \
    --includedir /usr/local/include \
    --mandir /usr/local/man \
    --enable-R-shlib \
    --enable-lto \
    --enable-byte-compiled-packages \
    --with-readline \
    --with-x=no
    

    


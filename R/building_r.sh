# Install packages to build Python:

aptitude install -y libffi-dev

yum install -y libffi-devel



# Python Version environment:

read -p 'What is the R version (X.Y.Z) to download? ' R_VERSION



# Download the Python source code:

cd /tmp

wget -c https://cloud.r-project.org/src/base/R-${R_VERSION:0:1}/\
R-${R_VERSION}.tar.gz


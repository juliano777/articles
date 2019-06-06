# Install packages to build Python:

aptitude install -y libffi-dev

yum install -y libffi-devel



# Python Version environment:

read -p 'What is the Python version (X.Y.Z) to download? ' PYTHON_VERSION



# Download the Python source code:

cd /tmp

wget -c https://www.python.org/ftp/python/${PYTHON_VERSION}/\
Python-${PYTHON_VERSION}.tar.xz


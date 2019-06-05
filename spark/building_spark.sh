"
Requirements

- Java JDK
- R
- Scala
"



# Install packages:

yum install -y python-setuptools R-Rcpp R-Rcpp-devel git mesa-libGLU-devel



# Install PIP:

wget -O- https://bootstrap.pypa.io/get-pip.py | python



# Install Python packages:

pip install pypandoc setuptools


# R Script for install packages:

cat << EOF > /tmp/pkg.R
my_pkgs <- c(
             'knitr',
             'shiny',
             'miniUI',
             'htmltools',
             'htmlwidgets',
             'rmarkdown',
             'devtools',
             'e1071',
             'survival',
             'roxygen2',
             'markdown'
            );

my_repos <- c(
              'http://rforge.net',
              'http://cran.rstudio.org',
              'http://R-Forge.R-project.org',
              'http://cran.us.r-project.org'
             );

install.packages(my_pkgs, repos=my_repos, type='source', dependencies=TRUE);
EOF



# Install R packages:

Rscript /tmp/pkg.R


# You must provide the version to download:

read -p 'What is the Spark version? (X.Y.Z): ' SPARK_VERSION



# What is the Scala version?:

read -p 'What is the Scala version? (X.Y): ' SCALA_VERSION



# Download the source code based on the Spark version:

wget -c https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/\
spark-${SPARK_VERSION}.tgz -P /tmp



# 

cd /tmp/ && tar xf spark-${SPARK_VERSION}.tgz && cd spark-${SPARK_VERSION}



# Clean unnecessary files:

rm -vf bin/*.cmd



# You'll need to configure Maven to use more memory than usual by setting MAVEN_OPTS:

export MAVEN_OPTS='-Xmx2g -XX:ReservedCodeCacheSize=512m'



# Set the environment variable LANG:

export LANG='en_US.UTF-8'



# Change the Scala version:

./dev/change-scala-version.sh ${SCALA_VERSION}



# If you have the last (stable) version of Maven installed...

export MVN=`which mvn 2> /dev/null`

if [ ! -z ${MVN} ]; then  # If the environment variable is not empty
    # New value for the MVN variable inside the script
    sed "s|\(^MVN=.*\)|#\1\nMVN='${MVN}'|g" -i dev/make-distribution.sh
fi




# Start the compilation to make your own distribution of Spark:

./dev/make-distribution.sh \
    --pip \
    --r \
    -Psparkr \
    -Phive \
    -Phive-thriftserver \
    -Pkubernetes \
    -Pkafka \
    -Pflume \
    -Pscala-${SCALA_VERSION} \
    -T 1C



# Rename dist directory:

mv dist/ spark-${SPARK_VERSION}



# Tar package creation (without compression):

tar cvf spark-${SPARK_VERSION}-k8s.tar spark-${SPARK_VERSION}



# Compress the Tar file with XZ maximum compression:

xz -9 spark-${SPARK_VERSION}-k8s.tar



# Remove the old directory:

rm -fr spark-${SPARK_VERSION}
























"
Requirements

- Java JDK
- R
- Scala
"



# Install packages:

yum install -y python-setuptools R-Rcpp git



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

rm -f bin/*.cmd



# You’ll need to configure Maven to use more memory than usual by setting MAVEN_OPTS:

export MAVEN_OPTS="-Xmx2g -XX:ReservedCodeCacheSize=512m"



# Change the Scala version:

./dev/change-scala-version.sh ${SCALA_VERSION}



# 

./dev/make-distribution.sh \
    --name my_spark \
    --pip \
    --r \
    --tgz \
    -Psparkr \
    -Phive \
    -Phive-thriftserver \
    -Pkubernetes \
    -Pkafka-0.10 \
    -Pflume \
    -Phadoop-provided \
    -Pscala-${SCALA_VERSION}



Rscript -e "update.packages(ask = FALSE, checkBuilt = TRUE, repos = 'https://cloud.r-project.org')"

Rscript -e "install.packages('knitr', dependencies = TRUE)"










#
# Azkaban + kafka + spark + hadoop
#
ARG BASE_IMAGE_TAG
# Build stage
FROM openjdk:${BASE_IMAGE_TAG:-8u342-jre} AS builder
ARG KAFKA_VERSION
ARG SCALA_VERSION
ARG SPARK_SCALA
ARG HADOOP_VERSION
ARG AZ_VERSION
ARG AZ_TYPE

## Build
### tooling
RUN apt-get update \
 && apt-get install -y git curl gcc g++

### AZKABAN
ENV AZ_VERSION ${AZ_VERSION:-3.90.0}
ENV NATIVE_ARTIFACTS azkaban-solo-server-${AZ_VERSION}.tar.gz azkaban-exec-server-${AZ_VERSION}.tar.gz azkaban-web-server-${AZ_VERSION}.tar.gz main
RUN mkdir /build \
    && cd /build \
    && git clone https://github.com/azkaban/azkaban.git \
    && cd /build/azkaban \
    && git checkout $AZ_VERSION \
    && ./gradlew clean build installDist -x test \
    && mkdir /artifacts \
    && for p in $(echo "${NATIVE_ARTIFACTS}" | sed -e "s/ /\\n/g") ; do find /build -type f -name ${p} -exec cp {} /artifacts/ \;  ; done \
    && find . -not -path  "*server*" -name "*-3.90.0.jar" -exec cp {} /artifacts/ \;

# Final image
ARG BASE_IMAGE_TAG
FROM openjdk:${BASE_IMAGE_TAG:-8u342-jre}
LABEL MAINTAINER=borisbond@gmail.com
ARG KAFKA_VERSION
ARG SCALA_VERSION
ARG SPARK_SCALA
ARG HADOOP_VERSION
ARG AZ_VERSION
ARG AZ_TYPE

## Install
### locale
RUN apt-get update \
 && apt-get install -y locales \
 && dpkg-reconfigure -f noninteractive locales \
 && locale-gen C.UTF-8 \
 && /usr/sbin/update-locale LANG=C.UTF-8 \
 && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
 && locale-gen \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

### set locales
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

### tooling
RUN apt-get update \
 && apt-get install -y jq curl nfs-common default-mysql-client \
    curl python3 python3-setuptools python3-pip \
&&  ln -s /usr/bin/python3 /usr/bin/python \
&&  pip3 install requests databricks-cli

### KAFKA
ENV KAFKA_VERSION ${KAFKA_VERSION:-2.6.0}
ENV SCALA_VERSION ${SCALA_VERSION:-2.12}
RUN curl -sL --retry 3 \
  "https://archive.apache.org/dist/kafka/$KAFKA_VERSION/kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz" \
  | gunzip \
  |  tar x -C /opt/ \
  && ln -s /opt/kafka_$SCALA_VERSION-$KAFKA_VERSION /opt/kafka

# http://blog.stuart.axelbrooke.com/python-3-on-spark-return-of-the-pythonhashseed
ENV PYTHONHASHSEED 0
ENV PYTHONIOENCODING UTF-8
ENV PIP_DISABLE_PIP_VERSION_CHECK 1

### HADOOP
RUN useradd -ms /bin/sh  hadoop
ENV HADOOP_VERSION ${HADOOP_VERSION:-3.2.1}
ENV HADOOP_HOME /usr/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV PATH $PATH:$HADOOP_HOME/bin
RUN curl -sL --retry 3 \
  "http://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" \
  | gunzip \
  | tar -x -C /usr/ \
 && rm -rf $HADOOP_HOME/share/doc \
 && chown -R root:root $HADOOP_HOME

### SPARK
ENV SPARK_VERSION ${SPARK_VERSION:-3.1.1}
ENV SPARK_SCALA ${SPARK_SCALA:-scala-2.12}
ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-without-hadoop
ENV SPARK_HOME /usr/spark-${SPARK_VERSION}
ENV SPARK_DIST_CLASSPATH="$HADOOP_HOME/etc/hadoop/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*"
ENV PATH $PATH:${SPARK_HOME}/bin
RUN curl -sL --retry 3 \
  "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz" \
  | gunzip \
  | tar x -C /usr/ \
 && mv /usr/$SPARK_PACKAGE $SPARK_HOME \
 && chown -R root:root $SPARK_HOME

### Artifacts
ENV AZ_VERSION ${AZ_VERSION:-3.90.0}
RUN mkdir /artifacts
COPY --from=builder /artifacts /artifacts/

### AZKABAN
ENV AZ_TYPE ${AZ_TYPE:-solo}
RUN  tar xzf /artifacts/azkaban-${AZ_TYPE}-server-${AZ_VERSION}.tar.gz -C /opt \
    && ln -s /opt/azkaban-${AZ_TYPE}-server-${AZ_VERSION} /opt/azkaban && mkdir -p /opt/azkaban/logs \
    && sed -i 's/\$@ &$/\$@/' /opt/azkaban/bin/internal/*start-${AZ_TYPE}*.sh
ENV AZ_TYPE ${AZ_TYPE:-solo}
COPY ./entrypoint.${AZ_TYPE}.sh /bin/entrypoint.sh
RUN chmod 755 /bin/entrypoint.sh

ENTRYPOINT ["/bin/entrypoint.sh"]

#!/usr/bin/env sh

export SPARK_HOME="/usr/local/spark"
export PATH="$PATH:${SPARK_HOME}/bin:${SPARK_HOME}/sbin"
export SPARK_DIST_CLASSPATH=$(hadoop classpath)

export HADOOP_USER_NAME="hadoop"
export HADOOP_HOME="/usr/local//hadoop"
export HADOOP_CONF_DIR="${HADOOP_HOME}/etc/hadoop"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${HADOOP_HOME}/lib/native"
export JAVA_HOME="{{ fact_java_home }}"
export PATH="${PATH}:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin"


cd  /opt/azkaban
/opt/azkaban/bin/internal/internal-start-solo-server.sh "$@"

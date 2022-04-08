#!/bin/bash
# *-* encoding : UTF-8 *-*

# hosts
echo "172.18.0.2      hadoop0" >> /etc/hosts
echo "172.18.0.4      hadoop2" >> /etc/hosts
echo "172.18.0.3      hadoop1" >> /etc/hosts
echo "172.18.0.5      hadoop3" >> /etc/hosts

# export env
cat /usr/local/app/bashrc_env >> ~/.bashrc
source ~/.bashrc


# hadoop config
echo "export JAVA_HOME=$JAVA_HOME" > $HADOOP_HOME/etc/hadoop/hadoop-env.sh
echo "export HDFS_NAMENODE_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
echo "export HDFS_DATANODE_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
echo "export HDFS_SECONDARYNAMENODE_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
echo "export YARN_RESOURCEMANAGER_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
echo "export YARN_NODEMANAGER_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
echo "export JSVC_HOME=$HADOOP_HOME/libexec" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
echo "export HDFS_DATANODE_SECURE_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
echo "export HADOOP_SHELL_EXECNAME=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh

echo "hadoop1" > $HADOOP_HOME/etc/hadoop/slaves
echo "hadoop2" >> $HADOOP_HOME/etc/hadoop/slaves
echo "hadoop3" >> $HADOOP_HOME/etc/hadoop/slaves

# 修改hadoop的配置文件
sed 'd' $HADOOP_CONF_DIR/core-site.xml
cp /usr/local/app/core-site.xml $HADOOP_CONF_DIR/

sed 'd' $HADOOP_CONF_DIR/hdfs-site.xml
cp /usr/local/app/hdfs-site.xml $HADOOP_CONF_DIR/

sed 'd' $HADOOP_CONF_DIR/mapred-site.xml
cp /usr/local/app/mapred-site.xml $HADOOP_CONF_DIR/

sed 'd' $HADOOP_CONF_DIR/yarn-site.xml
cp /usr/local/app/yarn-site.xml $HADOOP_CONF_DIR/

# 添加worker
sed 'd' $HADOOP_CONF_DIR/workers
cp /usr/local/app/workers $HADOOP_CONF_DIR/


echo "start sshd..."
# master should init when first time start contain
case "$1" in
"master-format")
    /usr/sbin/sshd;
    $HADOOP_HOME/bin/hadoop namenode -format -force;
    /usr/local/app/wait_for_it.sh hadoop1:22 -- echo 'started hadoop1';
    /usr/local/app/wait_for_it.sh hadoop2:22 -- echo 'started hadoop2';
    /usr/local/app/wait_for_it.sh hadoop3:22 -- echo 'started hadoop3';
    rm -rf /home/hadoop3/hadoop/tmp/hdfs/data/current;
    $HADOOP_HOME/sbin/start-all.sh;
;;
"master")
    /usr/sbin/sshd;
    /usr/local/app/wait_for_it.sh hadoop1:22 -- echo 'started hadoop1';
    /usr/local/app/wait_for_it.sh hadoop2:22 -- echo 'started hadoop2';
    /usr/local/app/wait_for_it.sh hadoop3:22 -- echo 'started hadoop3';
    $HADOOP_HOME/sbin/start-all.sh;
;;
hadoop1)
    /usr/sbin/sshd ;
;;
hadoop2)
    /usr/sbin/sshd ;
;;
hadoop3)
    /usr/sbin/sshd ;
;;
*)
   echo "error args..."
;;
esac
echo "start bash..."
bash

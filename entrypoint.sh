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

# zookeeper conf
/bin/cp /usr/local/app/zoo_sample.cfg $ZOOKEEPER_HOME/conf/zoo.cfg
# 集群启动脚本
/bin/cp /usr/local/app/zk.sh $ZOOKEEPER_HOME/bin/
chmod +x $ZOOKEEPER_HOME/bin/zk.sh

# hbase conf
sed 'd' $HBASE_HOME/conf/hbase-env.sh
/bin/cp /usr/local/app/hbase-env.sh $HBASE_HOME/conf/
sed 'd' $HBASE_HOME/conf/hbase-site.xml
/bin/cp /usr/local/app/hbase-site.xml $HBASE_HOME/conf/
sed 'd' $HBASE_HOME/conf/regionservers
/bin/cp /usr/local/app/regionservers $HBASE_HOME/conf/

echo "start sshd..."
# master should init when first time start contain
case "$1" in
"master-format")
    /usr/sbin/sshd;
    # 格式化hadoop
    $HADOOP_HOME/bin/hadoop namenode -format -force;
    /usr/local/app/wait_for_it.sh hadoop1:22 -- echo 'started hadoop1';
    /usr/local/app/wait_for_it.sh hadoop2:22 -- echo 'started hadoop2';
    /usr/local/app/wait_for_it.sh hadoop3:22 -- echo 'started hadoop3';
    rm -rf /home/hadoop3/hadoop/tmp/hdfs/data/current;
    # 启动hadoop
    echo "first start hadoop cluster...";
    $HADOOP_HOME/sbin/start-all.sh;

;;
"master")
    /usr/sbin/sshd;
    /usr/local/app/wait_for_it.sh hadoop1:22 -- echo 'started hadoop1';
    /usr/local/app/wait_for_it.sh hadoop2:22 -- echo 'started hadoop2';
    /usr/local/app/wait_for_it.sh hadoop3:22 -- echo 'started hadoop3';
    echo "start hadoop cluster..."
    $HADOOP_HOME/sbin/start-all.sh;
    echo "hadoop leave safemode...";
    hdfs dfsadmin -safemode leave;

    # zookeeper设置
    mkdir -p "$ZOOKEEPER_DATA_DIR";
    echo 1 > $ZOOKEEPER_DATA_DIR/myid;
    # 启动zookeeper集群
    sleep 5
    echo "start zookeeper cluster..."
    $ZOOKEEPER_HOME/bin/zk.sh start;
    # 启动hbase集群
    sleep 10
    echo "start hbase..."
    $HBASE_HOME/bin/start-hbase.sh;
    # 安装anaconda
    bash /usr/local/app/Anaconda3-2020.02-Linux-x86_64.sh -b ;
;;
"hadoop1")
    /usr/sbin/sshd ;
    # zookeeper dir
    mkdir -p "$ZOOKEEPER_DATA_DIR";
    echo 2 > $ZOOKEEPER_DATA_DIR/myid;
;;
"hadoop2")
    /usr/sbin/sshd ;
    mkdir -p "$ZOOKEEPER_DATA_DIR";
    echo 3 > $ZOOKEEPER_DATA_DIR/myid;
;;
"hadoop3")
    /usr/sbin/sshd ;
    mkdir -p "$ZOOKEEPER_DATA_DIR";
    echo 4 > $ZOOKEEPER_DATA_DIR/myid;
;;
*)
    echo "error args..."
;;
esac
echo "start bash..."
bash

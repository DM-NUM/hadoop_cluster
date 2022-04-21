#!/bin/bash

case $1 in
"start"){
for i in hadoop0 hadoop1 hadoop2 hadoop3
do
 echo ---------- zookeeper $i 启动 ------------
ssh $i "$ZOOKEEPER_HOME/bin/zkServer.sh start"
done
};;
"stop"){
for i in hadoop0 hadoop1 hadoop2 hadoop3
do
 echo ---------- zookeeper $i 停止 ------------
ssh $i "$ZOOKEEPER_HOME/bin/zkServer.sh stop"
done
};;
"status"){
for i in  hadoop0 hadoop1 hadoop2 hadoop3
do
 echo ---------- zookeeper $i 状态 ------------
ssh $i "$ZOOKEEPER_HOME/bin/zkServer.sh status"
done
};;
esac

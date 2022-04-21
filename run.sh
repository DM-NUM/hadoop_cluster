#!/bin/sh

case "$1" in
"stop")
  hbase-daemon.sh stop master;
  hbase-daemons.sh stop regionserver;
  bash zk.sh stop ;
  stop-all.sh;
  echo "hbase zookeeper hadoop exited..."
;;
"start")
  start-all.sh;
  sleep 5;
  bash zk.sh start;
  sleep 5;
  start-hbase.sh;
;;
esac

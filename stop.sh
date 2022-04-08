#!/bin/sh

case "$1" in
"stop")
  docker stop hadoop0 hadoop1 hadoop2 hadoop3;
;;
"del")
  docker rm hadoop0 hadoop1 hadoop2 hadoop3;
  #docker rmi test_spark ;
;;
esac

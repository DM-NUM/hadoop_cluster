#!/bin/bash

cat LICENSE.txt > file1.txt
hadoop fs -mkdir /test_input
# 将文件放到目录下
hadoop fs -put ./file1.txt /test_input
# 执行wordcount
hadoop jar hadoop-3.2.3/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.3.jar wordcount /test_input /test_output
# 查看结果
hadoop fs -ls /test_output
hadoop fs -cat /test_output/part-r-00000

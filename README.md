项目启动：
- ./start.sh build 构建镜像
- ./start.sh run 启动集群，hadoop0（master），hadoop1， hadoop2，hadoop3；【初次启动hadoop需要格式化，将docker-compose中hadoop0容器的command改成master-format】
- ./stop.sh stop 关闭容器
- ./stop.sh del 删除容器

项目脚本说明：
- 所有的脚本都放在/usr/local/app，docker-compose.yml中映射了本地目录，可自行修改
- jdk版本查看了网上的资料说要1.8，不然启动hadoop时有些任务启动不了，而官网下载jdk1.8需要登陆账号，最终放弃了使用curl直接下载的方式，而是通过浏览器下载到本地路径中，再add到镜像。所以为了使镜像生成更快，所有的软件都下到项目路径中。
- jsvc需要重新编译，所以需要安装make
- 镜像中生成ssh key是为了生成同一套密钥，启动多组容器即可相互访问
- wait_for_it.sh是为了在docker-compose启动容器时，保证slave都启动了，再启动master
- 容器启动后，执行的脚本由entrypoint.sh控制

hadoop测试
- ./test_wordcount.sh 

控制台
- localhost:8088
- localhost:9864
- localhost:9870

错误记录：
- namenode启动失败
* 对namenode格式化之后，datanode和namenode文件夹下面的current/VERSION中的clusterid不一致，导致启动失败；解决：删除datanode的current文件夹，或者将namenode文件夹的version的clusterid拷贝到datanode

- datanode启动失败
* slave挂载了master的数据目录，导致磁盘写入失败；解决方法：删除slave的数据挂载目录








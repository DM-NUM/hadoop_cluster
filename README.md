ATTENTION:
* 在build image前，一定要先手动将java1.8下载到项目目录中，因为java1.8官网需要登录并在浏览器下载；尝试过在非官网地址用curl下载，但是下载下来的java缺少了一些文件夹，所以老老实实去官网下载吧：https://www.oracle.com/java/technologies/downloads/
* 镜像中大部分是在下载软件，如果你不想你的镜像占用磁盘空间太大，建议所有软件你先下载到本地，然后将镜像中，所有curl相关的命令都注释再创建镜像。


wait_for_it.sh脚本是直接引用了大神的脚本，大神项目地址是：https://github.com/vishnubob/wait-for-it.git；自己就偷懒了，其实在这项目中也可以>不使用这个脚本，但是保险起见，还是使用了。

项目启动：
- ./start.sh build 构建镜像
- ./start.sh run 启动集群，hadoop0（master），hadoop1， hadoop2，hadoop3；【初次启动hadoop需要格式化，将docker-compose中hadoop0容器的command改成master-format】
- ./stop.sh stop 关闭容器
- ./stop.sh del 删除容器

项目脚本说明：
- 所有的脚本都放在/usr/local/app，docker-compose.yml中映射了本地目录，可自行修改
- jdk版本查看了网上的资料说要1.8，不然启动hadoop时有些任务启动不了，而官网下载jdk1.8需要登陆账号，最终放弃了使用curl直接下载的方式，而是通>过浏览器下载到本地路径中，再add到镜像。所以为了使镜像生成更快，所有的软件都下到项目路径中。
- jsvc需要重新编译，所以需要安装make
- 镜像中生成ssh key是为了生成同一套密钥，启动多组容器即可相互访问
- wait_for_it.sh是为了在docker-compose启动容器时，保证slave都启动了，再启动master
- 容器启动后，执行的脚本由entrypoint.sh控制

正常启动项目进程：
- master：
   - hadoop
   		- NameNode
   		- DataNode
   		- NodeManager
   		- ResourceManager
   		- SecondaryNameNode
   - zookeeper
   		- QuorumPeerMain
   - hbase
   		- HMaster
   		- HRegionServer
- slave：
   - hadoop
   		- DataNode
   		- NodeManager
   - zookeeper
   		- QuorumPeerMain
   - hbase
   		- HRegionServer


hadoop测试
- ./test_wordcount.sh

控制台
- localhost:8088 hadoop yarn
- localhost:9864 hadoop namenode
- localhost:9870 hadoop datanode
- localhost:16010 hbase

错误记录：

- hadoop 错误
	- 集群退出时，最好是使用hadoop的退出命令，不要强行用kill进程的方式退出。

	- 启动脚本时，./start.sh run
		* 因为我比较贪心，用了docker-compose同时启动多个容器，且entrypoint脚本启动比较多,所以导致启动docker超时。
		* 在本机添加环境变量，即设置超时时间
			* export DOCKER_CLIENT_TIMEOUT=120
			* export COMPOSE_HTTP_TIMEOUT=120
		* 重启docker服务
		* [参考文档](https://ask.csdn.net/questions/1020924)

	- namenode启动失败
	* 对namenode格式化之后，datanode和namenode文件夹下面的current/VERSION中的clusterid不一致，导致启动失败；解决：删除datanode的current文件夹，
	或者将namenode文件夹的version的clusterid拷贝到datanode

	- datanode启动失败
	* slave挂载了和master相同的数据目录，导致磁盘写入失败；解决方法：删除slave的数据挂载目录

	- 执行hadoop的wordcount，任务卡在job
		* 修改yarn-site.xml的内存配置，原因就是内存不够用，参考：https://blog.csdn.net/qq_44491709/article/details/107872137


- hbase 错误
	- hbase启动后，在设定的时间超时后，hmaster退出，然后日志有各种各样的warn，就是没有error；
		* 其实这种情况就是前期搭建好hbase后的一些不规范导致留下来的后遗症，比如：
			* 前期使用了hbase自带的zookeeper，后面又另外安装了zookeeper
			* 前期很多次直接kill掉hbase
		* 最终找到一个大神的方法，就是网上有人跟我遇到同种情况，hbase没有数据
			* 大神给的方案是直接删掉hadoop中/hbase文件夹下所有文件，再删除zookeeper客户端下，/hbase文件夹，代码如下
			* hdfs dfs -rm -r /hbase/*
			* 然后，打开zookeeper客户端，zkCli.zh ... 输入：deleteall /hbase
			* 成功解决
		* 但是这种一般是你最开始创建好hbase才这么做，不然很危险，数据啥的全都会没了
		* 所以还是要好好规范退出程序，先退出hbase，再退出zookeeper；一定要牢牢记住老铁们，花了我一周时间排查这个问题。
		* 附上大神的帖子：https://community.cloudera.com/t5/Support-Questions/HBase-Master-Failed-to-become-active-master/m-p/27240

    - 分布式集群下启动hbase，但是总是有一两个slave的hregionserver进程启动失败
    	* 之前为了方便，就直接用hbase自带的zookeeper，但产生了一系列的bug，怎么排都排不完，后来，还是决定下了独立的zookeeper，安装后就只有少量的bug，一下子就解决了；所以呀，还是别偷懒。

    - master的hmater, hregionserver, QuorumPeerMain已经启动，每个slave的hregionserver, QuorumPeerMain也正常启动，但是打开hbase shell中出现错误：
    	* 关闭hadoop的安全模式：hdfs dfsadmin -safemode leave

    - hadoop关闭安全模式，错误：Error: Could not find or load main class org.apache.hadoop.hdfs.tools.DFSAdmin
    	* 环境变量中添加export HADOOP_CLASSPATH=$(hadoop classpath):$HADOOP_CLASSPATH

   	- 当你非正常退出hbase时，可能会导致下次启动hbase时错误，有可能meta数据损坏
   		* 查看hbase文件夹下文件hadoop fs -ls /hbase
   		* 尝试使用habse hack -repairHoles 修复
   		* 一定要正常退出hbase，不要轻易使用kill -9
   			* 一般stop-hbase.sh, 但有可能没有全部退出
   			* hbase-daemon.sh stop master 退出主机master
   			* hbase-daemon.sh stop regionserver 退出主机regionserver
   			* hbase-daemons.sh stop regionserver 退出集群
   	- 运行一段时间后，regionsever退出：[regionserver/hadoop1:16020] util.Sleeper: We slept 16888ms instead of 3000ms, this is likely due to a long garbage collecting pause and it's usually bad, see http://hbase.apache.org/book.html#trouble.rs.runtime.zkexpired]
   		* 查看日志好像是说gc超时导致regionserver连接不上zk，在hbase-env.sh添加个配置就可以解决。
   		* https://blog.csdn.net/vah101/article/details/22923013

- anaconda错误
	- 打开python终端后，退格键和方向键异常
		* export TERMINFO=/usr/share/terminfo
	- 删除创建的环境失败，命令 conda remove -n test_env
		* 使用conda remove -n test_env --all, 实在不行，就使用 rm -rf
	- 其实除了上面的问题，还有各种各样很多的问题，最终删了整个anaconda文件夹，重新执行安装anaconda，这次没有指定anaconda的安装路径，全部选择默认的安装操作，安装完毕后，一切正常，所以我猜估计是手动安装时，执行了conda init，初始化脚本配置可能有问题。
	- 重新安装后就一切正常了，所以我现在暂时不考虑将anaconda的安装过程写到entrypoint.sh，进了容器后在手动执行bash Anaconda3-2020.02-Linux-x86_64.sh，然后一路选择yes就好了；默认安装anaconda在/root路径下

- hive错误
	- 启动报错：java.lang.NoSuchMethodError: com.google.common.base.Preconditions.checkArgument
		* hadoop（路径：$HADOOP_HOME/share/hadoop/common/lib）中该jar包为  guava-27.0-jre.jar；而hive(路径：$HIVE_HOME/lib)中该jar包为guava-19.0.1.jar, 将guava-27.0-jre.jar替换guava-19.0.1.jar
	- Exception in thread "main" java.lang.UnsatisfiedLinkError: /usr/local/app/jdk1.8.0_321/jre/lib/amd64/libmanagement.so: /usr/local/app/jdk1.8.0_321/jre/lib/amd64/libmanagement.so: cannot open shared object file: Input/output error
		* 这个问题很棘手，除了这个错误还有报找不到hadoop路径下的core-site.xml, hdfs-site.xml等文件的； 但是实际上这些文件我的安装路径下都有
		* 花了很长时间。网上也没有人遇到我同样的情况，而且我的hadoop和hbase都能正常启动
		* 后来想了下会不会是hadoop和hbase启动后，对hive启动进程的冲突，停掉了hbase和hadoop后，居然可以初始化hive了！！！！
		* 启动hive是需要hadoop的，所以重启启动了hadoop
		* 看来问题指向是hbase的问题，所以hive就不要安装在hadoop机器上了
	- 启动hive客户端后，输出了一大堆的info级别和warn级别的log
		* 这个问题也比较棘手，网上一些人说将log日志调整为warn级别，但有人说不行，看了个比较靠谱的，就是hadoop版本比较低，不适合hive3.1.3，所以可以试试降hive版本，或者升hadoop（但是不升hadoop，好不容易搭建好哈哈哈哈。。）

- zookeeper错误
	- 重新开机启动zookeeper错误：zookeeper ... already running as process 1203
		* 原因网上说可能是突然断电，机器异常关机或者程序异常启动，导致上次程序的pid记录在本次启动时冲突，网上最多的解决方案是删除zookeeper datadir下的zookeeper_server.pid文件，但是尴尬的是我在datadir目录下并没有这个文件，只有myid和version-2两个文件(文件夹)，那既然这样，我就删除version-2这个文件夹，it work！！！ 不过也很神奇，开zkServer.sh启动脚本，确实应该是会在datadir下生成zookeeper_server.pid，可是确没有，这点是我没搞懂的！！！
		* [参考资料](https://blog.csdn.net/daerzei/article/details/81741144)
	- 所以zookeeper还是要用正常方式退出，不要强行kill

- hadoop0连接不上mysql容器实例
	- 因为mysql实例是直接用links mysql容器的，最开始的时候在docker-compose没有指定mysql容器使用customnetwork，导致hadoop0容器一直连不上数据库，添加网络后就可以了。

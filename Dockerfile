FROM centos

ENV workdir=/usr/local/app
# 更改yum包地址
RUN cd /etc/yum.repos.d/ && \
  sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* && \
  sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

RUN yum update -y && \
  yum -y install vim net-tools wget openssh-clients openssh-server epel-release
RUN yum -y install htop make gcc

#设置时区
ENV TZ=Asia/Shanghai \
    DEBIAN_FRONTEND=noninteractive

RUN ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR $workdir
ADD . $workdir

# jdk1.8
#RUN curl -SLo jdk-8u321.tar.gz https://javadl.oracle.com/webapps/download/AutoDL\?BundleId\=245795_df5ad55fdd604472a86a45a217032c7d && \
#  tar -zxvf jdk-8u321.tar.gz && \
#  rm jdk-8u321.tar.gz

# scala download
RUN curl -SLO https://github.com/lampepfl/dotty/releases/download/3.1.1/scala3-3.1.1.tar.gz && \
  tar -zxvf scala3-3.1.1.tar.gz && \
  rm scala3-3.1.1.tar.gz

# hadoop
RUN curl -SLO https://dlcdn.apache.org/hadoop/common/hadoop-3.2.3/hadoop-3.2.3.tar.gz && \
  tar -zxvf hadoop-3.2.3.tar.gz && \
  rm hadoop-3.2.3.tar.gz

# saprk
RUN curl -SLO https://dlcdn.apache.org/spark/spark-3.0.3/spark-3.0.3-bin-hadoop3.2.tgz && \
  tar -zxvf spark-3.0.3-bin-hadoop3.2.tgz && \
  rm spark-3.0.3-bin-hadoop3.2.tgz

# jsvc
RUN curl -SLO https://archive.apache.org/dist/commons/daemon/source/commons-daemon-1.3.0-src.tar.gz && \
  tar -zxvf commons-daemon-1.3.0-src.tar.gz && \
  rm commons-daemon-1.3.0-src.tar.gz
RUN cd $workdir/commons-daemon-1.3.0-src/src/native/unix/ && \
  ./configure --with-java=$workdir/jdk1.8.0_321 && \
  make
RUN cp $workdir/commons-daemon-1.3.0-src/src/native/unix/jsvc $workdir/hadoop-3.2.3/libexec

# jsvc jar
RUN curl -SLO https://archive.apache.org/dist/commons/daemon/binaries/commons-daemon-1.3.0-bin.tar.gz && \
  tar -zxvf commons-daemon-1.3.0-bin.tar.gz && \
  rm commons-daemon-1.3.0-bin.tar.gz
RUN cp $workdir/commons-daemon-1.3.0/commons-daemon-1.3.0.jar $workdir/hadoop-3.2.3/share/hadoop/hdfs/lib

# ssh
RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N "" && \
  ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N "" && \
  ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N "" && \
  ssh-keygen -t dsa -f /etc/ssh/ssh_host_ed25519_key -N "" && \
  echo "RSAAuthentication yes" >> /etc/ssh/sshd_config && \
  echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config && \
  ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys && \
  sed -i 's/PermitEmptyPasswords yes/PermitEmptyPasswords no /' /etc/ssh/sshd_config && \
  sed -i 's/PermitRootLogin without-password/PermitRootLogin yes /' /etc/ssh/sshd_config && \
  sed -i "s/#   StrictHostKeyChecking ask/   StrictHostKeyChecking no/g" /etc/ssh/ssh_config && \
  sed -i "s/UserKnownHostsFile/UserKnownHostsFile/g" /etc/ssh/ssh_config && \
  echo "root:1234" | chpasswd

RUN chmod +x /usr/local/app/wait_for_it.sh
RUN chmod 0744 /usr/local/app/entrypoint.sh

ENTRYPOINT ["/usr/local/app/entrypoint.sh"]

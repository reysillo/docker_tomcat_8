FROM ubuntu:14.04

MAINTAINER Reinaldo Calderón

# Commands
RUN \
  apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y vim nano git wget libfreetype6 libfontconfig bzip2 supervisor zip unzip openssh-server && \
  apt-get autoremove -y && \
  apt-get clean all && \
  mkdir -p /srv/var /var/log/supervisor /opt && \
  /etc/init.d/ssh restart

ENV TOMCAT_VERSION 8.0.20
ENV TOMCAT_PORT 8080
ENV TOMCAT_PATH /opt/tomcat

# Install java 8
RUN apt-get -y install software-properties-common
RUN add-apt-repository ppa:webupd8team/java
RUN apt-get -y update
RUN echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 boolean true" | debconf-set-selections
RUN apt-get -y install oracle-java8-installer
RUN apt-get install oracle-java8-set-default

# Install tomcat
RUN \
    wget -O /tmp/tomcat.tar.gz http://apache.arvixe.com/tomcat/tomcat-8/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz && \
  #mkdir $TOMCAT_PATH && \
  cd /tmp && \
  tar zxf /tmp/tomcat.tar.gz && \
  ls /tmp && \
  mv /tmp/apache-tomcat* $TOMCAT_PATH && \
  rm -rf $TOMCAT_PATH/webapps/*.* && \
  rm -rf $TOMCAT_PATH/webapps/* && \
  rm /tmp/tomcat.tar.gz

COPY tomcat_supervisord_wrapper.sh $TOMCAT_PATH/bin/tomcat_supervisord_wrapper.sh

RUN chmod 755 $TOMCAT_PATH/bin/tomcat_supervisord_wrapper.sh

EXPOSE $TOMCAT_PORT
EXPOSE 22

# Install Apps from source folder
ADD packages $TOMCAT_PATH/webapps/

# Set ssh service passwors
RUN echo 'root:3asyso1' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# Start
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord"]
[ -f lib/ch-file.sh ] && . lib/ch-file.sh

pull_mediaserver_source() {
  ( cd /opt && git clone https://code.google.com/p/mediaserver )
}

build_mediaserver() {
  [ -d /opt/mediaserver ] || pull_mediaserver_source
  cd /opt/mediaserver
	export JAVA_HOME=$(readlink -f /usr/bin/javac | sed "s:/bin/javac::")
	export PATH=$PATH:$JAVA_HOME/bin
  mvn -DskipTests=true -Dmaven.javadoc.skip=true --batch-mode clean install
  ln -s /opt/mediaserver/bootstrap/target/mms-server-3.0.1-SNAPSHOT /opt/mediaserver/mobicents-media-server
  cd $CHARM_DIR
}

download_mediaserver() {
  cd /opt
  wget -q https://mobicents.ci.cloudbees.com/job/RestComm/lastSuccessfulBuild/artifact/restcomm-saas-tomcat-1.0.0.CR2-SNAPSHOT.zip
  unzip restcomm-saas-tomcat-1.0.0.CR2-SNAPSHOT.zip
  mv restcomm-saas-tomcat-1.0.0.CR2-SNAPSHOT mediaserver
  # or
  #wget -q http://sourceforge.net/projects/mobicents/files/RestComm/restcomm-saas-tomcat-1.0.0.FINAL.zip
  #unzip restcomm-saas-tomcat-1.0.0.FINAL.zip
  #mv restcomm-saas-tomcat-1.0.0.CR1 restcomm
}

install_mediaserver_upstart() {
  local mediaserver_root=$1
  local mediaserver_jar=$2
  local java_args="" #"-Xmx256m"
  local mediaserver_args=""
  ch_template_file 0644 \
                   root:root \
                   templates/defaults \
                   /etc/default/mediaserver \
                   "java_args mediaserver_root mediaserver_args"
  install --mode=644 --owner=root --group=root files/mediaserver.conf /etc/init/
}

install_mediaserver() {
  # /opt/mediaserver/bootstrap/target/mms-server-3.0.1-SNAPSHOT
  # sh bin/run.sh &
  # install /etc/init/mediaserver.conf
  local jar_file=/opt/mediaserver/mobicents-media-server
  #TODO clean up version dep
  install_mediaserver_upstart "/opt/mediaserver" $jar_file
}

configure_mediaserver() {
  local bind_address=$1

  # mediaserver_port=`config-get mediaserver_port`
  #TODO clean up version dep
  sed -i "s/127.0.0.1/$bind_address/" /opt/mediaserver/mobicents-media-server/deploy/server-beans.xml

  # open-port ${mediaserver_port}/TCP
  open-port 2427/TCP
}

restart_mediaserver() {
  service mediaserver status && service mediaserver restart || :
}

stop_mediaserver() {
  service mediaserver stop || :
}

uninstall_mediaserver() {
  rm -f /etc/init/mediaserver.conf
  rm -f /etc/default/mediaserver
  rm -Rf /opt/mediaserver
}



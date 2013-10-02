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
  cd $CHARM_DIR
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
  local build_dir="/opt/mediaserver/bootstrap/target/"
  #local jar_file=$(find $build_dir -name "*SNAPSHOT.jar")
  local jar_file=/opt/mediaserver/bootstrap/target/mms-server-3.0.1-SNAPSHOT
  #TODO clean up version dep
  install_mediaserver_upstart "/opt/mediaserver" $jar_file
}

configure_mediaserver() {
  local bind_address=$1

  # mediaserver_port=`config-get mediaserver_port`
  #TODO clean up version dep
  sed -i "s/127.0.0.1/$bind_address/" /opt/mediaserver/bootstrap/target/mms-server-3.0.1-SNAPSHOT/deploy/server-beans.xml

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



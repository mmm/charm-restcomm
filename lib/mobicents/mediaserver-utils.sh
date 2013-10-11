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
  local java_args="" #"-Xmx256m"
  local mediaserver_args=""
  ch_template_file 0644 \
                   root:root \
                   templates/mediacenter-defaults \
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

#configure_logging() {
#FILE=$MMS_INSTALL/conf/log4j.xml
#DIRECTORY=$MMS_INSTALL/log
#sed -e "/<param name=\"File\" value=\".*server.log\" \/>/ s|value=\".*server.log\"|value=\"$DIRECTORY/server.log\"|" $FILE > $FILE.bak
#mv $FILE.bak $FILE
#echo 'Updated log configuration'
#}

configure_mediaserver() {
  local bind_address=$1
  local bind_network=$2
  local bind_subnet=$3
  local CONFIG_FILE=/opt/mediaserver/mobicents-media-server/deploy/server-beans.xml
  local IP_ADDRESS_PATTERN="[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}"

	sed -e "s|<property name=\"bindAddress\">$IP_ADDRESS_PATTERN<\/property>|<property name=\"bindAddress\">$bind_address<\/property>|" \
	    -e "s|<property name=\"localBindAddress\">$IP_ADDRESS_PATTERN<\/property>|<property name=\"localBindAddress\">$bind_address<\/property>|" \
	    -e "s|<property name=\"localNetwork\">$IP_ADDRESS_PATTERN<\/property>|<property name=\"localNetwork\">$bind_network<\/property>|" \
	    -e "s|<property name=\"localSubnet\">$IP_ADDRESS_PATTERN<\/property>|<property name=\"localSubnet\">$bind_subnet<\/property>|" \
	    -e 's|<property name="useSbc">.*</property>|<property name="useSbc">true</property>|' \
	    -e 's|<property name="dtmfDetectorDbi">.*</property>|<property name="dtmfDetectorDbi">36</property>|' \
	    -e 's|<response-timeout>.*</response-timeout>|<response-timeout>5000</response-timeout>|' \
	    -e 's|<property name="lowestPort">.*</property>|<property name="lowestPort">64534</property>|' \
	    -e 's|<property name="highestPort">.*</property>|<property name="highestPort">65535</property>|' \
	    -i $CONFIG_FILE
	    
	grep -q -e '<property name="lowestPort">.*</property>' $FILE.bak || sed -i '/rtpTimeout/ a\
    <property name="lowestPort">64534</property>' $CONFIG_FILE
    
  grep -q -e '<property name="highestPort">.*</property>' $FILE.bak || sed -i '/rtpTimeout/ a\
    <property name="highestPort">65535</property>' $CONFIG_FILE

  #TODO
  #MMS_OPTS='$JAVA_OPTS -Xms64m -Xmx128m -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000'

  open-port 2427/TCP
  for port in {64534..65534}; do
    open-port $port/UDP
  done
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



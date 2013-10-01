
pull_restcomm_source() {
  rm -Rf /opt/restcomm
  #( cd /opt && git clone https://github.com/Mobicents/RestComm.git )
  ( cd /opt && git clone https://code.google.com/p/restcomm )
}

build_restcomm() {
  pull_restcomm_source
  cd /opt/restcomm
  sed -i '/restcomm.docs/d' pom.xml
	export JAVA_HOME=$(readlink -f /usr/bin/javac | sed "s:/bin/javac::")
	export PATH=$PATH:$JAVA_HOME/bin
  mvn -DskipTests=true -Dmaven.javadoc.skip=true --batch-mode clean install
  cd /opt/restcomm/restcomm.core
  mvn -DskipTests=true -Dmaven.javadoc.skip=true --batch-mode clean install
  cd $CHARM_DIR
  #( cd /opt/restcomm/restcomm.core && export JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64/ && mvn clean install )
}

install_restcomm() {
  # /opt/restcomm/restcomm.core/target/restcomm  /var/lib/tomcat6/webapps
  # service tomcat6 restart
  # install /etc/init/restcomm.conf
  # install_upstart
  # restart_service
  cp -R /opt/restcomm/restcomm.core/target/restcomm  /var/lib/tomcat6/webapps
}

configure_restcomm() {

  # write mediaserver_port to config file conf/restcomm.xml

  open-port 8080/TCP
}

restart_restcomm() {
  service tomcat6 status && service tomcat6 restart || :
}

stop_restcomm() {
  service tomcat6 stop || :
}

uninstall_restcomm() {
  echo "move on... nothing to see here"
}


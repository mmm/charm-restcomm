
pull_restcomm_source() {
  ( cd /opt && git clone https://code.google.com/p/restcomm )
}

build_restcomm() {
  [ -d /opt/restcomm ] || pull_restcomm_source
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
  local build_dir=/opt/restcomm/restcomm.core/target/restcomm
  [ -d "$build_dir" ] && cp -R $build_dir /var/lib/tomcat6/webapps/
}

configure_restcomm() {

  # write mediaserver_port to config file conf/restcomm.xml
  # called from relation-changed

  open-port 8080/TCP
}

restart_restcomm() {
  service tomcat6 status && service tomcat6 restart || :
}

stop_restcomm() {
  service tomcat6 stop || :
}

uninstall_restcomm() {
  rm -Rf /var/lib/tomcat6/webapps/restcomm
  rm -Rf /opt/restcomm
}


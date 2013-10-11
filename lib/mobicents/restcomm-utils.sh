
pull_restcomm_source() {
  ( cd /opt && git clone https://code.google.com/p/restcomm )
  #TODO find release tags?
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
  ln -s /opt/restcomm/restcomm.core/target /opt/restcomm/webapps
  cd $CHARM_DIR
  #( cd /opt/restcomm/restcomm.core && export JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64/ && mvn clean install )
}

download_restcomm() {

  cd /opt
  wget -q https://mobicents.ci.cloudbees.com/job/RestComm/lastSuccessfulBuild/artifact/restcomm-saas-tomcat-1.0.0.CR2-SNAPSHOT.zip
  unzip restcomm-saas-tomcat-1.0.0.CR2-SNAPSHOT.zip
  mv restcomm-saas-tomcat-1.0.0.CR2-SNAPSHOT restcomm
  # or
  #wget -q http://sourceforge.net/projects/mobicents/files/RestComm/restcomm-saas-tomcat-1.0.0.FINAL.zip
  #unzip restcomm-saas-tomcat-1.0.0.FINAL.zip
  #mv restcomm-saas-tomcat-1.0.0.CR1 restcomm

}

install_restcomm_upstart() {
  local restcomm_root=$1
  local java_args="" #"-Xmx256m"
  local restcomm_args=""
  ch_template_file 0644 \
                   root:root \
                   templates/restcomm-defaults \
                   /etc/default/restcomm \
                   "java_args restcomm_root restcomm_args"
  install --mode=644 --owner=root --group=root files/restcomm.conf /etc/init/
}

install_restcomm() {
  #local webapps_dir=/opt/restcomm/webapps/restcomm
  #[ -d "$webapps_dir" ] && cp -R $webapps_dir /var/lib/tomcat6/webapps/
  #TODO clean up version dep

  #[ -f /usr/share/java/log4j-1.2.jar ] && cp /usr/share/java/log4j-1.2.jar /var/lib/tomcat6/webapps/restcomm/WEB-INF/lib/
  #TODO clean up version dep

  install_restcomm_upstart "/opt/restcomm"

}

configure_restcomm() {
  local mediaserver_host=$1
  local mediaserver_port=$2

  local RESTCOMM_ROOT=/opt/restcomm
  # config file is installed into /var/lib/tomcat6/webapps/restcomm/conf/restcomm.xml
  #TODO clean up tomcat version dep
  [ -n "$mediaserver_host" ] && sed -i "s/127.0.0.1/$mediaserver_host/" $RESTCOMM_ROOT/webapps/restcomm/WEB-INF/conf/restcomm.xml
  [ -n "$mediaserver_port" ] && sed -i "s/2427/$mediaserver_port/" $RESTCOMM_ROOT/webapps/restcomm/WEB-INF/conf/restcomm.xml

  # config file is installed into /var/lib/tomcat6/webapps/restcomm/conf/restcomm.xml
  # I'll try to add an overriding entry as a separate file /var/lib/..../restcomm/conf/restcomm-mediaserver.xml
  #ch_template_file 0644 \
                   #root:root \
                   #templates/restcomm-mediaserver.xml \
                   #/var/lib/tomcat6/webapps/restcomm/conf/restcomm-mediaserver.xml \
                   #"mediaserver_host mediaserver_port"

  open-port 8080/TCP
  open-port 5080/TCP
}

clone_app() {
  local repo_url=$1
  local app_dir=/opt/app
  git clone $repo_url $app_dir
}

install_app() {
  #cp -R /opt/app/stuff /var/lib/tomcat6/webapps/restcomm/where-stuff-should-go
  echo "installing app"
}

remove_app() {
  rm -Rf /opt/app
}

configure_app() {
  local repo_url=$1
  

}

restart_restcomm() {
  service restcomm status && service restcomm restart || :
}

stop_restcomm() {
  service restcomm stop || :
}

uninstall_restcomm() {
  rm -Rf /var/lib/tomcat6/webapps/restcomm
  #TODO clean up version dep
  rm -Rf /opt/restcomm
}


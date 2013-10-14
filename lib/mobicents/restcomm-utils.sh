
[ -f lib/ch-file.sh ] && . lib/ch-file.sh

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
  local mediaserver_address=$1

  local RESTCOMM_ROOT=/opt/restcomm
	local FILE=$RESTCOMM_ROOT/WEB-INF/conf/restcomm.xml

	sed -e "s|<local-address>$IP_ADDRESS_PATTERN<\/local-address>|<local-address>$mediaserver_address<\/local-address>|" \
	    -e "s|<remote-address>$IP_ADDRESS_PATTERN<\/remote-address>|<remote-address>$mediaserver_address<\/remote-address>|" \
	    -i $FILE

  local private_host=`unit-get private-address`
  local private_address=`dig +short $private_host`
  local public_host=`unit-get public-address`
  local public_address=`dig +short $public_host`
	sed -e "s|<\!--.*<external-ip>.*<\/external-ip>.*-->|<external-ip>$public_address<\/external-ip>|" \
	    -e "s|<external-ip>.*<\/external-ip>|<external-ip>$public_address<\/external-ip>|" \
	    -e "s|<external-address>.*<\/external-address>|<external-address>$public_address<\/external-address>|" \
	    -e "s|<\!--.*<external-address>.*<\/external-address>.*-->|<external-address>$public_address<\/external-address>|" \
	    -e "s|<prompts-uri>.*<\/prompts-uri>|<prompts-uri>http:\/\/$public_address:8080\/restcomm\/audio<\/prompts-uri>|" \
	    -e "s|<cache-uri>.*<\/cache-uri>|<cache-uri>http:\/\/$private_address:8080\/restcomm\/cache<\/cache-uri>|" \
	    -e "s|<recordings-uri>.*<\/recordings-uri>|<recordings-uri>http:\/\/$public_address:8080\/restcomm\/recordings<\/recordings-uri>|" \
	    -e "s|<error-dictionary-uri>.*<\/error-dictionary-uri>|<error-dictionary-uri>http:\/\/$public_address:8080\/restcomm\/errors<\/error-dictionary-uri>|" \
	    -e 's|<outbound-prefix>.*</outbound-prefix>|<outbound-prefix>#</outbound-prefix>|' -i $FILE

  open-port 8080/TCP
  open-port 5080/TCP
  open-port 5080/UDP

  #for port in {64535..65535}; do
  #  open-port $port/UDP
  #done
  #TODO ec2 very unhappy with 1000 rules for one group... manually adding a single rule for this range for now.

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


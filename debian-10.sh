#!/bin/sh

echo "Updating package cache"
apt-get update
apt-get upgrade
echo
echo "Installing Tomcat 9"
echo
apt install -y tomcat9 tomcat9-admin tomcat9-common tomcat9-user
echo
echo "Installing required packages"
echo
apt install -y build-essential libcairo2-dev libjpeg62-turbo-dev ibtool-bin libossp-uuid-dev libavcodec-dev libavutil-dev libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libwebsockets-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev libsystemd-dev libsdl2-dev libgtk2.0-dev libavcodec-dev libavformat-dev libavfilter-dev liblzo2-dev libgnutls28-dev libpng-dev
echo
echo "Install cmake"
echo
apt install cmake -y
echo
echo "Installing lib vnc client"
echo
apt-get -u dist-upgrade
tar vfx libvncserver.tar.gz
cd libvncserver/
mkdir build
cd build
cmake ..
cmake --build .
make
make install
cd ..
cd ..
echo
echo "Downloading and installing Guacamole Server"
echo
# wget https://mirror.dkd.de/apache/guacamole/1.1.0/source/guacamole-server-1.1.0.tar.gz
tar vfx guacamole-server.tar.gz
cd guacamole-server/
autoreconf -fi
./configure --with-init-dir=/etc/init.d
make
make install
cd ..
echo 
echo "Activating Service and starting it:"
echo
/sbin/ldconfig
systemctl enable guacd
systemctl start guacd
echo
echo "Installing Guacamole Client"
echo
# wget http://us.mirrors.quenda.co/apache/guacamole/1.1.0/binary/guacamole-1.1.0.war
 mkdir /etc/guacamole
 cp guacamole-1.1.0.war /etc/guacamole/guacamole.war
 cp guacamole.war /etc/guacamole/guacamole.war
 ln -s /etc/guacamole/guacamole.war /var/lib/tomcat9/webapps/
 mkdir /etc/guacamole/extensions
 mkdir /etc/guacamole/lib
 echo "GUACAMOLE_HOME=/etc/guacamole" | tee -a /etc/default/tomcat9

echo
echo "Installing Database Server"
echo
apt install -y mariadb-server mariadb-client
echo
echo "Creating Database and user"
echo
mysql -u root < create_database.sql
echo
echo "Downloading jdbc-extension"
echo
wget http://apache.mirror.digionline.de/guacamole/1.1.0/binary/guacamole-auth-jdbc-1.1.0.tar.gz

tar vfx guacamole-auth-jdbc-1.1.0.tar.gz
echo
echo "Importing Database"
echo
cat guacamole-auth-jdbc-1.1.0/mysql/schema/*.sql | mysql -u root guacamole_db -o
echo
echo "Installing extension"
echo
cp guacamole-auth-jdbc-1.1.0/mysql/guacamole-auth-jdbc-mysql-1.1.0.jar /etc/guacamole/extensions/
echo
echo "JDBC driver installieren"
echo
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.13.tar.gz
tar xvzf mysql-connector-java-8.0.13.tar.gz
cp mysql-connector-java-8.0.13/mysql-connector-java-8.0.13.jar /etc/guacamole/lib/
echo
echo "Configuring DB Time zone"
echo
# echo "default_time_zone='America/Sao_Paulo'" >> /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl restart mariadb.service
echo
echo "Configurating Guacamole"
echo
echo "# Hostname and Guacamole server port
guacd-hostname: localhost
guacd-port: 4822

# MySQL properties
mysql-hostname: localhost
mysql-port: 3306
mysql-database: guacamole_db
mysql-username: guacamole_user
mysql-password: passw0rd" >> /etc/guacamole/guacamole.properties
systemctl restart tomcat9
echo
echo "Installing Apache2"
echo
apt install apache2 -y
/usr/sbin/a2enmod rewrite
/usr/sbin/a2enmod proxy_http
/usr/sbin/a2enmod proxy_wstunnel
echo
echo "Configuring Apache2"
echo
echo 'ProxyPass / http://127.0.0.1:8080/guacamole/ flushpackets=on
ProxyPassReverse / http://127.0.0.1:8080/guacamole/
ProxyPassReverseCookiePath /guacamole /
<Location /websocket-tunnel>
   Order allow,deny
   Allow from all
   ProxyPass ws://127.0.0.1:8080/guacamole/websocket-tunnel
   ProxyPassReverse ws://127.0.0.1:8080/guacamole/websocket-tunnel
</Location>
SetEnvIf Request_URI "^/tunnel" dontlog
CustomLog  /var/log/apache2/guac.log common env=!dontlog' >> /etc/apache2/sites-enabled/000-default.conf
systemctl restart apache2.service
echo
echo "Configuring logs"
echo
echo '<configuration>
 <!-- Appender for debugging -->
 <appender name="GUAC-DEBUG" class="ch.qos.logback.core.ConsoleAppender">
   <encoder>
    <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
   </encoder>
 </appender>

 <!-- Log at Debug Level -->
 <root level="debug">
    <appender-ref ref="GUAC-DEBUG"/>
 </root>
</configuration>' >> /etc/guacamole/logback.xml
systemctl restart tomcat9
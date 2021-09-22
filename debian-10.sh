#!/bin/sh

echo "Updating package cache"
apt-get update
echo
echo "Installing Tomcat 9"
echo
apt install -y tomcat9 tomcat9-admin tomcat9-common tomcat9-user
echo
echo "Installing required packages"
echo
apt install -y build-essential libcairo2-dev libjpeg62-turbo-dev libtool-bin libossp-uuid-dev libavcodec-dev libavutil-dev libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libwebsockets-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev libsystemd-dev libvncserver-dev
echo
echo "Install cmake"
echo
wget https://github-releases.githubusercontent.com/537699/dc0c831c-fcae-4f07-a437-0e77143de2ae?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20210922%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20210922T142915Z&X-Amz-Expires=300&X-Amz-Signature=9706a1f8b0b8eb3a3bb992624b4a62d1f7d8c517f7e6bd6605db92110cbce8b3&X-Amz-SignedHeaders=host&actor_id=1022634&key_id=0&repo_id=537699&response-content-disposition=attachment%3B%20filename%3Dcmake-3.21.3.tar.gz&response-content-type=application%2Foctet-stream
tar vfx cmake-3.21.3.tar.gz
cd cmake-3.21.3/
./bootstrap
make
make install
cd
# apt install cmake -y
echo
echo "Installing lib vnc client"
echo
tar vfx libvncserver.tar.gz
cd libvncserver/
mkdir build
cd build
cmake ..
cmake --build .
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
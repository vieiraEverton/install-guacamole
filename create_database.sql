CREATE DATABASE guacamole_db; 
CREATE USER 'guacamole_user'@'localhost' IDENTIFIED BY 'passw0rd';
GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'localhost';
FLUSH PRIVILEGES;
quit;
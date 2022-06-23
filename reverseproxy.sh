#!/bin/bash

sudo apt-get update -y
sudo apt update -y
sudo apt-get install nginx -y
sudo apt-get install apache2 php-fpm wget -y
sudo unlink /etc/nginx/sites-enabled/default
cd /etc/nginx/sites-available/
IP=`hostname -i`
sudo touch reverse-proxy.conf
cat <<EOF >>reverse-proxy.conf
server {
    listen 80;
    location / {
        proxy_pass http://$IP;
    }
}
EOF
sudo ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/reverse-proxy.conf
service nginx configtest
if [ $? -eq 0 ]; then
   echo OK
else
   echo Installation FAILED
   break
fi
sudo service nginx restart
cd
sudo mkdir download
cd download
sudo wget https://mirrors.edge.kernel.org/ubuntu/pool/multiverse/liba/libapache-mod-fastcgi/libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb
sudo dpkg -i libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb
sudo mv /etc/apache2/ports.conf /etc/apache2/ports.conf.default
echo "Listen 8080" | sudo tee /etc/apache2/ports.conf
sudo a2dissite 000-default
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/001-default.conf
cat <<EOF >>/etc/apache2/sites-available/001-default.conf
<VirtualHost *:8080>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
sudo a2ensite 001-default
sudo systemctl reload apache2
if [ $? -eq 0 ]; then
   echo OK
else
   echo Installation FAILED
   break
fi
sudo apt install net-tools -y
cd
touch portdetails.txt
sudo netstat -tlpn > portdetails.txt
echo "===================================="
echo "This is current active port details"
echo "===================================="
sleep 5;
cat portdetails.txt
sleep 5;
sudo a2enmod actions
sudo mv /etc/apache2/mods-enabled/fastcgi.conf /etc/apache2/mods-enabled/fastcgi.conf.default
sudo ls -la /run/php/
cd /run/php/
pwd
cd
echo "==================="
echo
read -p 'php path: ' phppath
echo
echo "==================="

cat <<EOF >>/etc/apache2/mods-enabled/fastcgi.conf
<IfModule mod_fastcgi.c>
  AddHandler fastcgi-script .fcgi
  FastCgiIpcDir /var/lib/apache2/fastcgi
  AddType application/x-httpd-fastphp .php
  Action application/x-httpd-fastphp /php-fcgi
  Alias /php-fcgi /usr/lib/cgi-bin/php-fcgi
  FastCgiExternalServer /usr/lib/cgi-bin/php-fcgi -socket $phppath -pass-header Authorization
  <Directory /usr/lib/cgi-bin>
    Require all granted
  </Directory>
</IfModule>
EOF
sleep 5;
sudo apachectl -t
sleep 5;
sudo systemctl reload apache2
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php
echo
echo
echo "======================================="
sudo mkdir -v /usr/share/nginx/jain.practiceandlearn.in /usr/share/nginx/vesion.practiceandlearn.in
echo "<h1 style='color: green;'>Example.com</h1>" | sudo tee /usr/share/nginx/jain.practiceandlearn.in/index.html
echo "<h1 style='color: red;'>Sample.org</h1>" | sudo tee /usr/share/nginx/vesion.practiceandlearn.in/index.html
echo "<?php phpinfo(); ?>" | sudo tee /usr/share/nginx/jain.practiceandlearn.in/info.php
echo "<?php phpinfo(); ?>" | sudo tee /usr/share/nginx/version.practiceandlearn.in/info.php
touch /etc/nginx/sites-available/jain.practiceandlearn.in
cat <<EOF >/etc/nginx/sites-available/jain.practiceandlearn.in
server {
    listen 80 default_server;

    root /usr/share/nginx/jain.practiceandlearn.in;
    index index.php index.html index.htm;

    server_name jain.practiceandlearn.in www.jain.practiceandlearn.in;
    location / {
        try_files $uri $uri/ /index.php;
    }

    location ~ \.php$ {
        fastcgi_pass unix:$phppath;
        include snippets/fastcgi-php.conf;
    }
}
EOF
touch /etc/nginx/sites-available/version.practiceandlearn.in
cat <<EOF >/etc/nginx/sites-available/version.practiceandlearn.in
server {
    root /usr/share/nginx/version.practiceandlearn.in;
    index index.php index.html index.htm;

    server_name version.practiceandlearn.in www.version.practiceandlearn.in;
    location / {
        try_files $uri $uri/ /index.php;
    }

    location ~ \.php$ {
        fastcgi_pass unix:$phppath;
        include snippets/fastcgi-php.conf;
    }
}
EOF
sudo ln -s /etc/nginx/sites-available/jain.practiceandlearn.in /etc/nginx/sites-enabled/jain.practiceandlearn.in
sudo ln -s /etc/nginx/sites-available/version.practiceandlearn.in /etc/nginx/sites-enabled/version.practiceandlearn.in
sudo nginx -t
if [ $? -eq 0 ]; then
   echo OK
else
   echo Installation FAILED
   break
fi
sudo systemctl reload nginx
echo
echo
cat <<EOF >/etc/nginx/sites-available/apache
server {
    listen 80;
    server_name jain.practiceandlearn.in www.jain.practiceandlearn.in version.practiceandlearn.in www.version.practiceandlearn.in;

    location / {
        proxy_pass http://$IP:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
sudo ln -s /etc/nginx/sites-available/apache /etc/nginx/sites-enabled/apache
sudo nginx -t
sudo systemctl reload nginx

FROM alpine:3.6
COPY files /tmp
RUN apk add --no-cache bash curl nginx openrc mysql mysql-client \
      php5-ctype php5-curl php5-dom php5-fpm php5-iconv php5-gd \
      php5-json php5-mysqli php5-openssl php5-pdo php5-pdo_sqlite \
      php5-sqlite3 php5-xml php5-xmlreader php5-zlib php5-phar php5-posix &&\
    # NGINX
    adduser -D -g 'www' www &&\
    mkdir /www &&\
    chown -R www:www /var/lib/nginx &&\
    chown -R www:www /www &&\
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig &&\
    mkdir /run/nginx/ &&\
    mv /tmp/nginx.conf /etc/nginx/nginx.conf &&\
    mv /tmp/index.html /www/index.html &&\
    # PHP
    mv /tmp/php.ini /etc/php5/php.ini &&\
    mv /tmp/php-fpm.conf /etc/php5/php-fpm.conf &&\
    mv /tmp/info.php /www &&\
    mv /tmp/mysql.php /www &&\
    # MYSQL
    mkdir -p /run/mysqld &&\
    chown -R mysql:mysql /run/mysqld &&\
    chown -R mysql:mysql /var/lib/mysql &&\
    mysql_install_db --user=mysql --ldata=/var/lib/mysql &&\
    # OPENRC
    sed -i 's/#rc_sys=""/rc_sys="lxc"/g' /etc/rc.conf &&\
    echo 'rc_provide="loopback net"' >> /etc/rc.conf &&\
    sed -i 's/^#\(rc_logger="YES"\)$/\1/' /etc/rc.conf &&\
    sed -i '/tty/d' /etc/inittab &&\
    sed -i 's/hostname $opts/# hostname $opts/g' /etc/init.d/hostname &&\
    sed -i 's/mount -t tmpfs/# mount -t tmpfs/g' /lib/rc/sh/init.sh &&\
    sed -i 's/cgroup_add_service /# cgroup_add_service /g' /lib/rc/sh/openrc-run.sh &&\
    echo 'rc_provide="loopback net"' >> /etc/rc.conf &&\
    /sbin/openrc &&\
    touch /run/openrc/softlevel &&\
    rc-update add nginx default &&\
    rc-update add php-fpm default &&\
    rc-update add mariadb default &&\
    # BASH
    touch /root/.bashrc &&\
    echo "export PS1='\h:\w\\\$ '" >> /root/.bashrc &&\
    echo "alias r='fc -e -'" >> /root/.bashrc &&\
    echo "set -o vi" >> /root/.bashrc &&\
    echo "cat /etc/motd" >> /root/.bashrc &&\
    mv /tmp/motd /etc/motd &&\
    # SET MYSQL ROOT PASSWORD
    service mariadb start &&\
    mysqladmin -u root password "root" &&\
    # CLEANUP
    rm -rf /var/cache/apk/* &&\
    rm -rf /tmp/*
WORKDIR /root
ENTRYPOINT ["/sbin/init"]

FROM alpine:3.6

RUN apk add --no-cache bash curl nginx openrc mysql mysql-client \
      php5-ctype php5-curl php5-dom php5-fpm php5-iconv php5-gd \
      php5-json php5-mysqli php5-openssl php5-pdo php5-pdo_sqlite \
      php5-sqlite3 php5-xml php5-xmlreader php5-zlib php5-phar php5-posix &&\
    adduser -D -g 'www' www &&\
    mkdir /www &&\
    chown -R www:www /var/lib/nginx &&\
    chown -R www:www /www &&\
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig &&\
    mkdir /run/nginx/ &&\
    echo "export PS1='\h:\w\\\$ '" > /root/.bashrc &&\
    echo "alias r='fc -e -'" >> /root/.bashrc &&\
    echo "set -o vi" >> /root/.bashrc &&\
    echo 'rc_provide="loopback net"' >> /etc/rc.conf &&\
    rc-update add nginx default &&\
    rc-update add php-fpm default &&\
    rc-update add mariadb default

ENTRYPOINT ["/sbin/init"]

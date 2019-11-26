# alpine 安装Nginx+PHP5+MySQL5

## 前言
alpine 版本3.6
PHP 版本5.6
MySQL 在alpine 中实际上用的是MariaDB，这次装的是10.1 对应MySQL 5.6。
[alpine 软件包查询](https://pkgs.alpinelinux.org/packages)  
[MariaDB 和MySQL 版本对应关系](https://mariadb.com/kb/en/library/system-variable-differences-between-mariadb-and-mysql/)  
约定：以下章节一次性的操作都写在`配置`部分。

## 手动安装
### 准备工作
```bash
# 启动容器，注意：全程用root 操作！
docker run -d -p 8080:80 --name mnp5 alpine:3.6 /sbin/init
# 简单解释：-d 容器后台运行，-p 映射宿主机端口，执行/sbin/init 才能使用openrc 及reboot 等命令，默认sh 不行

# 如果不想终止容器而退出来的话可以用Ctrl+p 再Ctrl+q，再想进入容器
docker exec -it mnp5 sh
# 简单解释：-it 获得输入输出

# 更新软件包索引
apk update
```

### 1 Nginx
#### 1.1 安装
```bash
apk add nginx
```

#### 1.2 配置
```bash
# 创建www 组和www 用户，用于运行nginx，否则用root 权限太大太危险
adduser -D -g 'www' www

# 创建用于存放网页文件的目录，且归属于www 组及www 用户
mkdir /www
chown -R www:www /var/lib/nginx
chown -R www:www /www
# alpine 的nginx 没有默认站点目录，需在配置中用root 属性指定，后面有样例

# 备份nginx 默认配置
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig

# 创建nginx 运行所需的目录
mkdir /run/nginx/
```

编辑`Nginx`配置文件`vi /etc/nginx/nginx.conf`
```nginx
user                            www;
worker_processes                auto; # it will be determinate automatically by the number of core

error_log                       /var/log/nginx/error.log warn;
#pid                             /var/run/nginx/nginx.pid; # it permit you to use /etc/init.d/nginx reload|restart|stop|start

events {
    worker_connections          1024;
}

http {
    include                     /etc/nginx/mime.types;
    default_type                application/octet-stream;
    sendfile                    on;
    access_log                  /var/log/nginx/access.log;
    keepalive_timeout           3000;
    server {
        listen                  80;
        root                    /www;
        index                   index.html index.htm;
        server_name             localhost;
        client_max_body_size    32m;
        error_page              500 502 503 504  /50x.html;
        location = /50x.html {
              root              /var/lib/nginx/html;
        }
    }
}
```
创建页面文件`vi /www/index.html`
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <title>HTML5</title>
</head>
<body>
    Server is online
</body>
</html>
```

#### 1.3 检验
```bash
# 启动nginx，启动之前先检查一下配置文件是否正确
nginx -t && nginx
```
宿主机中打开浏览器访问`localhost:8080`显示`Server is online`则表示安装配置成功。
如有问题查看日志`less /var/log/nginx/error.log`。


### 2 PHP
#### 2.1 安装
```bash
# 可根据需求apk update && apk search php5 来查找要安装的包
apk add php5 php5-ctype php5-curl php5-dom php5-fpm php5-iconv php5-gd \
      php5-json php5-mysqli php5-openssl php5-pdo php5-pdo_sqlite \
      php5-sqlite3 php5-xml php5-xmlreader php5-zlib php5-phar php5-posix
```

#### 2.2 配置
```bash
# 创建环境变量，后面生成配置文件会用到
PHP_FPM_USER="www"
PHP_FPM_GROUP="www"
PHP_FPM_LISTEN_MODE="0660"
PHP_MEMORY_LIMIT="512M"
PHP_MAX_UPLOAD="50M"
PHP_MAX_FILE_UPLOAD="200"
PHP_MAX_POST="100M"
PHP_DISPLAY_ERRORS="On"
PHP_DISPLAY_STARTUP_ERRORS="On"
PHP_ERROR_REPORTING="E_COMPILE_ERROR\|E_RECOVERABLE_ERROR\|E_ERROR\|E_CORE_ERROR"
PHP_CGI_FIX_PATHINFO=0

# 编辑/etc/php5/php-fpm.conf
sed -i "s|;listen.owner\s*=\s*nobody|listen.owner = ${PHP_FPM_USER}|g" /etc/php5/php-fpm.conf
sed -i "s|;listen.group\s*=\s*nobody|listen.group = ${PHP_FPM_GROUP}|g" /etc/php5/php-fpm.conf
sed -i "s|;listen.mode\s*=\s*0660|listen.mode = ${PHP_FPM_LISTEN_MODE}|g" /etc/php5/php-fpm.conf
sed -i "s|user\s*=\s*nobody|user = ${PHP_FPM_USER}|g" /etc/php5/php-fpm.conf
sed -i "s|group\s*=\s*nobody|group = ${PHP_FPM_GROUP}|g" /etc/php5/php-fpm.conf
sed -i "s|;log_level\s*=\s*notice|log_level = notice|g" /etc/php5/php-fpm.conf  

# 编辑/etc/php5/php.ini
sed -i "s|display_errors\s*=\s*Off|display_errors = ${PHP_DISPLAY_ERRORS}|i" /etc/php5/php.ini
sed -i "s|display_startup_errors\s*=\s*Off|display_startup_errors = ${PHP_DISPLAY_STARTUP_ERRORS}|i" /etc/php5/php.ini
sed -i "s|error_reporting\s*=\s*E_ALL & ~E_DEPRECATED & ~E_STRICT|error_reporting = ${PHP_ERROR_REPORTING}|i" /etc/php5/php.ini
sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php5/php.ini
sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${PHP_MAX_UPLOAD}|i" /etc/php5/php.ini
sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php5/php.ini
sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php5/php.ini
sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= ${PHP_CGI_FIX_PATHINFO}|i" /etc/php5/php.ini
```
修改`Nginx`配置`vi /etc/nginx/nginx.conf`，以便和`php-fpm5`连接上
```nginx
# /etc/nginx/nginx.conf
user www;
worker_processes auto;

pcre_jit on;
error_log /var/log/nginx/error.log warn;
include /etc/nginx/modules/*.conf;

events {
  worker_connections 1024;
}

http {
  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  server_tokens off;
  client_max_body_size 1m;
  keepalive_timeout 65;
  sendfile on;
  tcp_nodelay on;
  ssl_prefer_server_ciphers on;
  ssl_session_cache shared:SSL:2m;
  gzip_vary on;

  log_format main '$remote_addr - $remote_user [$time_local] "$request" '
      '$status $body_bytes_sent "$http_referer" '
      '"$http_user_agent" "$http_x_forwarded_for"';

  access_log /var/log/nginx/access.log main;

  server {
    listen                  80;
    root                    /www;
    index                   index.html index.htm index.php;
    server_name             localhost;
    client_max_body_size    32m;
    error_page              500 502 503 504  /50x.html;

    location = /50x.html {
      root              /var/lib/nginx/html;
    }

    location ~ \.php$ {
      fastcgi_pass      127.0.0.1:9000;
      fastcgi_index     index.php;
      include           fastcgi.conf;
    }
  }
}
```
基本上是`/etc/nginx/nginx.conf`原内容去掉注释和最后的`include /etc/nginx/conf.d/*.conf;`，直接将`server`配置写在这里，并设置运行用户为`www`；还有`fastcgi_pass 127.0.0.1:9000`对应`/etc/php5/php-fpm.conf`中的`listen = 127.0.0.1:9000`，为的是将`php`页面转给`php-fpm`处理。

创建`php`测试页面`vi /www/info.php`
```php
<?php	phpinfo(); ?>
```

设置时区(可选)
```bash
# 加载时区数据
apk add tzdata

# 设置时区
TIMEZONE="Asia/Shanghai"
cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
echo "${TIMEZONE}" > /etc/timezone
sed -i "s|;*date.timezone =.*|date.timezone = ${TIMEZONE}|i" /etc/php5/php.ini
```

#### 2.3 检验
```bash
# 杀掉后台nginx 和php-fpm5 进程
killall nginx php-fpm5

# 先启动php-fpm5 感觉好一点
php-fpm5

# 启动nginx，启动之前先检查一下配置文件是否正确
nginx -t && nginx
# 如果之前没有杀死nginx 进程也可以让其重新读取配置
nginx -s reload
```
宿主机中打开浏览器访问`localhost:8080/info.php`，看到当前`php`相关信息(版本号、模块等)即可。


### 3 MySQL
#### 3.1 安装
```bash
# alpine 中MySQL 用的就是MariaDB
apk add mysql mysql-client
# 或
apk add mariadb mariadb-client
```

#### 3.2 配置
```bash
# 创建运行mysqld 后台进程必须的目录并赋给mysql 组和mysql 用户
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# 加载数据库文件
chown -R mysql:mysql /var/lib/mysql
mysql_install_db --user=mysql --ldata=/var/lib/mysql
```

#### 3.3 检验
```bash
# 启动mysqld，注意加个& 后台运行，否则只能Ctrl+p，Ctrl+q 退出再docker exec 进来了
/usr/bin/mysqld_safe --datadir='/var/lib/mysql' &

# 设置root 密码
mysqladmin -u root password "root"
```

##### 3.3.1 客户端检验
```bash
# 客户端登录，注意-p 后面直接跟密码不能有空格
mysql -u root -p"root"
```
使用内置的`mysql`数据库，测试`SQL`语句
```mysql
use mysql
select count(*) from user;
exit
```
或者将测试内容写在一起
```bash
# 创建测试文件
cd /tmp
cat > test.sql << EOF
use mysql
select count(*) from user;
exit
EOF

# 使用管道符传给mysql 客户端执行
cat test.sql | mysql -u root -proot
```

为了方便脚本运行，例如定时任务自动备份，我们也可以配置`~/.my.cnf`
```bash
cat > ~/.my.cnf << EOF
[client]
host=localhost
port=3306
user='root'
password='root'

[mysql]
database='mysql'
EOF
```
以后，使用`mysql`，`mysqldump`这些命令都不需要输入用户名和密码了。

##### 3.3.2 PHP 连接检验
创建`php`测试页面`vi /www/mysql.php`
```php
<?php
$mysql_conf = array(
  'host'    => '127.0.0.1:3306', 
  'db'      => 'mysql', 
  'db_user' => 'root', 
  'db_pwd'  => 'root', 
);

$mysqli = @new mysqli($mysql_conf['host'], $mysql_conf['db_user'], $mysql_conf['db_pwd']);
if ($mysqli->connect_errno) {
  die("could not connect to the database:\n" . $mysqli->connect_error);
}

$mysqli->query("set names 'utf8';");
$select_db = $mysqli->select_db($mysql_conf['db']);
if (!$select_db) {
  die("could not connect to the db:\n" .  $mysqli->error);
}

$sql = "select count(*) from user;";
$res = $mysqli->query($sql);
if (!$res) {
  die("sql error:\n" . $mysqli->error);
}

while ($row = $res->fetch_assoc()) {
  var_dump($row);
}

$res->free();
$mysqli->close();
?>
```
宿主机中打开浏览器访问`localhost:8080/mysql.php`，显示`array(1) { ["count(*)"]=> string(1) "6" }`即可。


### 4 OpenRC
#### 4.1 安装
```bash
# 安装openrc 主要用于控制后台服务
apk add openrc
```

#### 4.2 配置
```bash
# 让openrc 加载所需的依赖，否则一直WARNING: xxxxx is already started，却没在运行 
/sbin/openrc
# rc-status -a  # 效果同上，目的就是启动openrc 让其加载运行环境

# 执行service nginx status 会提示要创建该文件
touch /run/openrc/softlevel
# 告诉openrc 它运行在虚拟容器中，'lxc' 在/etc/rc.conf 中有注释
sed -i 's/#rc_sys=""/rc_sys="lxc"/g' /etc/rc.conf
# 告诉openrc 网络已经可以工作了，因为环回口不会down，它就会觉得网络一直可用
echo 'rc_provide="loopback net"' >> /etc/rc.conf
# 不记录日志
sed -i 's/^#\(rc_logger="YES"\)$/\1/' /etc/rc.conf
# 不尝试获取tty 设备，否则运行容器时执行/sbin/init 会一直报tty 错误
sed -i '/tty/d' /etc/inittab
# 不设置主机名，注释掉对应设置
sed -i 's/hostname $opts/# hostname $opts/g' /etc/init.d/hostname
# 不加载tmpfs
sed -i 's/mount -t tmpfs/# mount -t tmpfs/g' /lib/rc/sh/init.sh
# 不运行cgroup，避免service start xxxxx 时read only 错误
sed -i 's/cgroup_add_service /# cgroup_add_service /g' /lib/rc/sh/openrc-run.sh
```

#### 4.3 检验
以`nginx`服务为例
```bash
# 查看nginx 状态
service nginx status

# 启动nginx
service nginx start

# 停止nginx
service nginx stop

# 重启nginx
service nginx restart
```
注意：如果`nginx`配置文件有问题，以上命令将不正常，例如显示`nginx`状态为`crashed`但浏览器依然可以访问。
用`nginx -s stop`来停止的话只能用`nginx`这个命令来启动，`service nginx start`无能为力，`service nginx status`也只会显示其`crashed`。

设置服务开机启动
```bash
# 设置开机启动的服务
rc-update add nginx default
rc-update add php-fpm default
rc-update add mariadb default

# 退出docker 容器
exit

# 重启docker 容器
docker restart mnp5

# 重新进入容器
docker exec -it mnp5 sh

# 查看服务状态
rc-status -a

# 查看所有进程
ps -ef
```


### 清理工作
关闭删除容器
```bash
# 清理apk 的缓存
rm -rf /var/cache/apk/*
rm -rf /tmp/*
# 删除容器这些东西也会被一并清除，可略过

# 退出容器mnp5
exit

# 停止容器
docker stop mnp5

# 删除容器
docker rm mnp5
```


## Docker 部署
制作容器镜像并运行测试
### Dockerfile
https://github.com/suzhi82/mnp5
https://github.com/suzhi82/mnp5/blob/master/Dockerfile

### 创建运行验证容器
启动 --rm



## 参考文档
[alpine Nginx with PHP](https://wiki.alpinelinux.org/wiki/Nginx_with_PHP)  
[alpine MariaDB](https://wiki.alpinelinux.org/wiki/MariaDB)  
[alpine MariaDB GitHub](https://github.com/yobasystems/alpine-mariadb/tree/master/alpine-mariadb-amd64)  
[alpine OpenRC](https://hub.docker.com/r/sneck/openrc/dockerfile)  
[How to enable and start services on Alpine Linux](https://www.cyberciti.biz/faq/how-to-enable-and-start-services-on-alpine-linux/)  



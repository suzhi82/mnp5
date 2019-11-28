# MNP5 = ALPINE3.6 + MYSQL5.6 + NGINX + PHP5

`Nginx`默认端口：`80`，网站目录：`/www`
`MySQL`的`root`密码：`root`，连接时请用`127.0.0.1`，有时`localhost`解析不了。

## 创建镜像
```bash
# 获取Dockerfile 及相关文件
git clone https://github.com/suzhi82/mnp5.git

# 创建镜像
docker build --no-cache . -t mnp5
```

## 运行镜像
```bash
# 后台启动即可，默认执行/sbin/init
docker run --name mnp5 -p 8888:80 -d mnp5

# Nginx 默认的站点路径为/www
docker run --name mnp5 -p 8888:80 -v /xxxx/web:/www -d mnp5
```

## 验证服务
```bash
# 进入容器
docker exec -it mnp5 bash
# 进入后应该可以看到来自/etc/motd 的提示
```
访问`localhost:8888`可看到演示页面。

## DockerHub
另一个获取该`Docker`镜像的途径
```bash
docker pull suzhi82/mnp5
# 或者直接运行
docker run --name mnp5 -p 8888:80 -v /xxxx/web:/www -d suzhi82/mnp5
```
# MNP5 = ALPINE3.6 + MYSQL5.6 + NGINX + PHP5
## 创建镜像
```bash
# 获取Dockerfile 及相关文件
git clone https://github.com/suzhi82/mnp5.git

# 创建镜像
docker build --no-cache . -t mnp5
```

## 运行镜像
```bash
docker run --name mnp5 -p 8888:80 -d mnp5
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
docker run --name mnp5 -p 8888:80 -d suzhi82/mnp5
```
FROM php:7.3.17-cli-alpine3.11
# 现在我们需要配置一些东西。
# 编译参数，用于指定 Swoole 版本
ARG swoole_ver
# 保存到环境变量，如果没有传递就给默认值
ENV SWOOLE_VER=${swoole_ver:-"v4.5.0"}

# apk 是 alpine 的一个包管理器
# set -ex 是为了在出错时及时停掉脚本
RUN set -ex \
    # 在临时目录进行这一切
    && cd /tmp \
    # 把 apk 的默认源改为aliyun镜像
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    # 更新包列表
    && apk update \
    # 添加这么多扩展是因为后面我们编译 swoole 和 sdebug 需要用到 
    && apk add vim git autoconf openssl-dev build-base zlib-dev re2c libpng-dev oniguruma-dev

# install composer
RUN cd /tmp \
    # 从aliyun 下载composer 
    && wget https://mirrors.aliyun.com/composer/composer.phar \
    && chmod u+x composer.phar \
    && mv composer.phar /usr/local/bin/composer \
    # 给 composer 设置aliyun镜像
    && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer \
    # 把 composer 全局命令加入 PATH ，以确保以后我们会用到
    && echo 'export PATH="$PATH:$HOME/.composer/vendor/bin"' >> ~/.bashrc

# php ext
RUN php -m \
    # docker-php-ext-install 是 php 为我们提供的指令，让我们可以安装一些 php 的预设扩展
    # 可以在这里启用必要的扩展
    && docker-php-ext-install gd pdo_mysql mysqli sockets pcntl \
    # 现在可以检查一下 php 已经安装的扩展
    && php -m


# install swoole
RUN cd /tmp \
    # from mirrors
    && git clone https://gitee.com/swoole/swoole swoole \
    && cd swoole \
    # 切换到指定版本的 tag
    && git checkout ${SWOOLE_VER} \
    && phpize \
    # 执行configure命令
    && ./configure --enable-openssl --enable-sockets --enable-http2 --enable-mysqlnd \
    && make \
    && make install \
    # 通过 docker-php-ext-enable 来启用扩展，这个命令也是 php 为我们提供的。
    && docker-php-ext-enable swoole \
    # 检查 php 已经安装的模块
    && php -m \
    # 检查 swoole 是否正确安装
    && php --ri swoole

# install sdebug
# 运行克隆前，先把目录切换到 /tmp ，避免之前的命令导致目录错误
RUN cd /tmp \
    # from mirrors
    && git clone https://gitee.com/vyi/sdebug sdebug \
    # 进入克隆的目录
    && cd sdebug \
    # 切换到 sdebug_2_7 分支，这里一定到切换分支，因为 master 分支是 Xdebug 的源码
    && git checkout sdebug_2_7 \
    && phpize \
    && ./configure --enable-xdebug \
    && make \
    && make install \
    # 这里 安装完成后执行的值 xdebug
    && docker-php-ext-enable xdebug \
    && php -m \
    # 这里检查也是哟,注意是 sdebug
    && php --ri sdebug


# config php
RUN cd /usr/local/etc/php/conf.d \
    # swoole config
    # 关闭 swoole 短名称，使用 Hyperf 这个是必须要
    && echo "swoole.use_shortname = off" >> 99-off-swoole-shortname.ini \
    # config xdebug
    && { \
        # 添加一个 Xdebug 节点
        echo "[Xdebug]"; \
        # 启用远程连接
        echo "xdebug.remote_enable = 1"; \
        # 这个是多人调试，但是现在有些困难，就暂时不启动
        echo ";xdebug.remote_connect_back = On"; \
        # 自动启动远程调试
        echo "xdebug.remote_autostart  = true"; \
        # 这里 host 可以填前面取到的 IP ，也可以填写 host.docker.internal 。
        echo "xdebug.remote_host = host.docker.internal"; \
        # 这里端口固定填写 19000 ，当然可以填写其他的，需要保证没有被占用
        echo "xdebug.remote_port = 19000"; \
        # 这里固定即可
        echo "xdebug.idekey=PHPSTORM"; \
        # 把执行结果保存到 99-xdebug-enable.ini 里面去
    } | tee 99-xdebug-enable.ini


# install phpredis
RUN cd /tmp \
    # from mirrors
    && git clone https://gitee.com/mirrors/phpredis phpredis \
    && cd phpredis \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && docker-php-ext-enable redis \
    && php -m \
    && php --ri redis


# check
# 检查一下 PHP 版本信息和 已安装的模块
RUN cd /tmp \
    # 检查 PHP 版本
    && php -v \
    # 检查已安装的模块
    && php -m \
    && echo -e "Build Completed!"

# xdebug
RUN  export PHP_IDE_CONFIG=serverName=XDEBUG_02

# 暴露 9501 端口
EXPOSE 9501
# 设置工作目录，即默认登录目录，这个目录现在并不存在，
# 我们需要在 run 时把我们外部 windows 的文件目录映射到 docker 容器中去
WORKDIR /mnt/d/htdocs

# apk add –no-cache redis
# docker run -di -p 8080:9501 -v D:/www:/mnt/d/htdocs --name php-swoole-sdebug faqqcn/php-swoole-sdebug:1.0

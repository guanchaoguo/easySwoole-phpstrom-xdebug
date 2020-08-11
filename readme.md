# phpstrom xdebug swoole
####  docker 镜像
####  https://i1el1i0w.mirror.aliyuncs.com

####  构建php镜像
####  docker build -f php.dockerfile -t faqqcn/php-swoole-sdebug:1.0 .


####  PHPStorm setting
####  Languages & Frameworks | PHP | cli interpreter| From Docker 
####  Languages & Frameworks | PHP | cli interpret| path mapping
####  Languages & Frameworks | PHP | Debug| 端口19000 和dockerfile 对应
####  Languages & Frameworks | PHP | services | 名字 ：XDEBUG_02 host ：localhost 端口： 8080 
####   主界面那个运行| run|debugger | edit| php_remote_debug|./docker-compose.yml
####  进入容器  export PHP_IDE_CONFIG=serverName=XDEBUG_02
####   Chrome 扩展 Xdebuge Helper | XDEBUG_SESSION=PHPSTORM |  debugkey=PHPSTORM

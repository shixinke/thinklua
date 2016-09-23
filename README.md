# thinklua 基于openresty的web开发框架

------

thinklua是一个非常简单的web框架，目前只有请求分发、显示模板的功能

##框架介绍

###目录结构：

* apps  ----应用目录
 + common  ----函数库
 + config  ----应用配置目录
 + controllers ----控制器目录
 + models      ----模型目录
 + views    ----模板目录
 + bootstrap.lua  ----应用启动文件
 + init.lua       ----应用初始化文件
* conf nginx ----配置目录
* lib      ----lua库目录
* public   ----用户访问目录(静态资源)
* tmp      ----临时目录

###使用

只需要在nginx添加如下配置即可：

    lua_code_cache    on;
    lua_package_path '/the/root/path/thinklua/lib/?.lua;;';
	init_by_lua_file        '/the/root/path/thinklua/apps/init.lua';

    server {
        listen 8060;
        set $root  /the/root/path/thinklua;
        set $app_root  $root/apps;
        set $template_root $app_root/views;

        location / {
            content_by_lua_file $app_root/bootstrap.lua;
        }

        location /static/ {
            root $root/public/;
        }
    }

##to do

> * 支持自定义路由
> * 性能优化
> * 添加更多session,cookie等类库的支持

##contact
author:shixinke

email:ishixinke@qq.com


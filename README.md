# thinklua 基于openresty的web开发框架

------

thinklua是一个非常简单的web框架，有基本的MVC功能，支持简单的自定义路由

主要功能：

* mysql操作封装
* redis操作封装
* 自动请求分发
* 简单的自定义路由

##快速入门

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

###简单使用

只需要在nginx添加如下配置即可：

    lua_code_cache    on;
    lua_package_path '/the/root/path/thinklua/apps/?.lua;/the/root/path/thinklua/lib/?.lua;;';
    init_by_lua_file  '/the/root/path/thinklua/apps/init.lua';

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

##使用手册
* [控制器](#controller)
 + [控制器定义](#controller_definition)
 + [基类控制器](#base_controller)
 + [访问URL](#visit_the_controller)
* [模型](#model)
 + [模型定义](#model_definition)
 + [基类模型](#base_model)
* [视图](#view)
 + [视图使用](#view_usage)
* [配置](#configuration)
 + [配置定义](#configuration_definition)
 + [默认配置项说明](#configuration_item)
* [路由](#route)
 + [路由规则](#route_rules)

<h3 id="controller">控制器</h3>
======

模型
======

视图
======

配置
======

路由
======

##to do

> * 性能优化
> * 添加更多session,cookie等类库的支持

##contact
author:shixinke

email:ishixinke@qq.com


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
* [控制器](#控制器)
 + [控制器定义](#控制器自定义)
 + [基类控制器](#基类控制器)
 + [访问URL](#访问URL)
* [模型](#模型)
 + [模型定义](#模型定义)
 + [基类模型](#基类模型)
* [视图](#视图)
 + [视图使用](#视图使用)
* [配置](#配置)
 + [配置定义](#配置定义)
 + [默认配置项说明](#配置项说明)
* [路由](#路由)
 + [路由规则](#路由规则)

控制器
======
###控制器定义

如定义一个blog控制器，在apps/controllers目录下面建立一个blog.lua的文件：

定义如下：
    local _M = {
    _VERSION = '0.01'
    }
    
    function _M.index(self)
        self.withoutLayout = true
        self:assign('title', 'blog')
        self:display()
    end

    function _M.detail(self)
        ngx.say('detail')
        ngx.say(self:get('id'))
    end
    
    return _M
    
###基类控制器
####属性
* controller : 当前控制器的名称
* action     ：当前访问URL对应的方法名称
* params     ：当前url中的参数
###方法
* [assign : 模板赋值](#assign)
* [display : 调用模板并显示](#display)
* [get : 获取get请求或url中的参数](#get)
* [post : 获取post请求参数](#post)
* [json : 返回json字符串](#json)
* [jsonp : 返回jsonp字符串](#jsonp)
 
####assign
======
+ 功能：模板赋值
+ 用法：assign(name, value)
+ 参数说明：name为模板变量的名称(可以是一个包含键值对的table)
            value为模板变量的值
+ 例如：
    function _M.read(self)
        self:assign("name", "shixinke")
        self:assign({city = "hz", province = "zj"})
        self:display()
    end


####display
======
+ 功能：显示模板
+ 用法：display(tpl, data)
+ 参数说明：tpl为模板文件(默认为nil,系统自动定位到当前控制器及当前方法，如/blog/read即为 views/blog/read.html)
            data为模板变量(默认为nil)
+ 例如：
    function _M.read(self)
        self:assign("name", "shixinke")
        self:assign({city = "hz", province = "zj"})
        self:display()
    end
  或
    function _M.read(self)
        self:assign("name", "shixinke")
        self:assign({city = "hz", province = "zj"})
        self:display('blog/post.html')
    end

#### get
======
+ 功能：获取get请求参数及url路由中的参数
+ 用法：get(name)
+ 参数说明：name为get请求或路由参数中的键名(name为空时表示所有get请求参数及路由参数)
+ 例如：
    function _M.read(self)
        local id = self:get('id')
    end

#### post
======
+ 功能：获取post请求参数
+ 用法：post(name)
+ 参数说明：name为post请求参数中的键名(name为空时表示所有post请求参数)
+ 例如：
    function _M.read(self)
        local id = self:post('id')
    end

#### json
======
+ 功能：返回json格式数据
+ 用法：json(code, message, data)
+ 参数说明：code 为返回数据状态编码(非HTTP状态码)(可以是一个table，表示整个返回数据)
+           message 为提示信息
+           data 为返回数据
+ 例如：
    function _M.read(self)
        self:json(200, 'failed', {id = 100})
    end

#### jsonp
======
+ 功能：返回jsonp格式数据
+ 用法：json(code, message, data, callback)
+ 参数说明：code 为返回数据状态编码(非HTTP状态码)(可以是一个table，表示整个返回数据)
+           message 为提示信息
+           data 为返回数据
+           callback 为回调函数
+ 例如：
    function _M.read(self)
        self:jsonp(200, 'failed', {id = 100}, 'callback')
    end

###访问URL

当访问URL：http://domain.com/blog/detail时，对应的文件为apps/controllers/blog.lua，访问的是blog控制器的detail方法

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


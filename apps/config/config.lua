local config = {
    debug = true,                               -- 是否开启debug模式
    database = {                                -- 数据库配置
        host = '127.0.0.1',
        port = 3306,
        user = 'shixinke',
        password = 'info@shixinke.com',
        database = 'thinklua_blog',
        charset = 'utf8',
        timeout = 1000,
        max_idle_timeout = 6000,
        pool_size = 100
    },
    cache = {                                   -- redis缓存设置
        host = '127.0.0.1',
        port = 6379,
        timeout = 1000,
        max_idle_timeout = 6000,
        pool_size = 1000
    },
    routes = {                                   -- 路由相关设置
        default_controller = 'index',            -- 默认控制器
        router_status = 'on',                    -- 自定义路由是否开启
        layer_status = 'on',
        layers = 'admin',                        -- 控制器使用层(目录)，所有的目录以,隔开
        url_suffix = '.html',                    -- 路径后缀，如http://thinklua.shixinke.com/blog/index.html
        view_suffix = '.html',                   -- 模板后缀(可以使用自定义后缀)
        rules = {                                -- 自定义路由规则
            {method = 'get', pattern = '/blog/:id', url = '/blog/detail'},
            {method = 'get', pattern = '/search/:key', url = '/search/index'},
            --{method = 'get', pattern = '/lists/index', url = '/index/lists?id=11'}
            --[[
               method表示请求方式，目前只支持get/post
               pattern表示匹配模式，目前只支持:和*
               url实际访问的url
            --]]
        }
    },
    security = {                                 -- 安全相关的设置
        password_salt = 'shixinke',              -- 密码加密字符串
        session = {
            secret = 'kdkdikekdldinfk23456'
        }
    },
    pages = {                                    -- 页面的相关配置
        charset = 'UTF-8',                       -- 页面编码
        not_found = '/404.html',                 -- 404页面地址
        server_error = '/server_busy.html'       -- 50x页面地址
    }

}
return config;

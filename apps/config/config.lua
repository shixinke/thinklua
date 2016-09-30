local config = {
    debug = true,
    database = {
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
    cache = {
        host = '127.0.0.1',
        port = 6379,
        timeout = 1000,
        max_idle_timeout = 6000,
        pool_size = 1000
    },
    routes = {
        default_controller = 'index',
        router_status = 'on',
        layer_status = 'on',
        layers = 'admin',
        url_suffix = '.html',
        view_suffix = '.html',
        rules = {
            {method = 'get', pattern = '/blog/:id', url = '/blog/detail'},
            {method = 'get', pattern = '/search/:key', url = '/search/index'},
            --{method = 'get', pattern = '/lists/index', url = '/index/lists?id=11'}
        }
    },
    security = {
        password_salt = 'shixinke'
    },
    pages = {
        charset = 'UTF-8',
        not_found = '/404.html',
        server_error = '/server_busy.html'
    }

}
return config;
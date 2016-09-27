local config = {
    debug = true,
    database = {
        host = '127.0.0.1',
        port = 3306,
        user = 'shixinke',
        password = 'info@shixinke.com',
        database = 'geoip',
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
        url_suffix = '.html',
        rules = {
            {method = 'get', pattern = '/blog/:id', url = '/blog/detail'},
            --{method = 'get', pattern = '/lists/index', url = '/index/lists?id=11'}
        }
    },
    pages = {
        charset = 'UTF-8',
        not_found = '',
        server_error = ''
    }

}
return config;
local _M = {
    _VERSION = '0.01'
}

local ngx_var = ngx.var
local regex = ngx.re
local log = ngx.log
local router = require 'system.router':new()
local base_controller = require 'system.controller'


function _M.parse(self)
    local url_tab = router:route()
    if url_tab == nil then
        local uri = ngx_var.uri
        if config.routes.url_suffix and config.routes.url_suffix ~= '' then
            uri = regex.sub(uri, config.routes.url_suffix, '')
        end
        url_tab = {path = uri, params = {}}
    end
    return self.dispatch(url_tab)
end

function _M.parse_url(uri, args)
    local layers
    local tab = {}
    local default_controller = config.routes.default_controller or 'index'
    local default_action = config.routes.default_action or 'index'
    if config.routes.layer_status == 'on' and config.routes.layers then
        layers = func.explode(',', config.routes.layers)
    end
    if uri == '/' then
        tab.controller = default_controller
        tab.action = default_action
    else
        local mat = func.split(uri, '/([a-zA-Z0-9-_]+)')
        local count = #mat
        if count <= 2 then
            if layers and func.in_array(mat[1], layers) then
                tab.layer = mat[1]
                tab.controller = mat[2] or default_controller
                tab.action = default_action
            else
                tab.controller = mat[1] or default_controller
                tab.action = mat[2] or default_action
            end
        else
            if layers and func.in_array(mat[1], layers) then
                tab.layer = mat[1]
                tab.controller = mat[2]
                tab.action = mat[3]
                for i = 4, count, 2 do
                    if mat[i+1] then
                        args[mat[i]] = mat[i+1]
                    end
                end
            else
                tab.controller = mat[1]
                tab.action = mat[2]
                for i = 3, count, 2 do
                    if mat[i+1] then
                        args[mat[i]] = mat[i+1]
                    end
                end
            end
        end
        tab.params = args
    end
    return tab
end

function _M.call(url_tab)
    local ok, m_controller
    if url_tab.layer then
        ok, m_controller = pcall(require, 'apps.controllers.'..url_tab.layer..'.'..url_tab.controller)
    else
        ok, m_controller = pcall(require, 'apps.controllers.'..url_tab.controller)
    end
    if not ok or type(m_controller) ~= 'table' then
        return nil, nil
    else
        if not m_controller[url_tab.action] or type(m_controller[url_tab.action]) ~= 'function' then
            return m_controller, nil
        end
        return m_controller, url_tab.action
    end

end

function _M.dispatch(url_tab)
    local uri = url_tab.path
    local tab = _M.parse_url(uri, url_tab.params)
    local m_controller, m_action = _M.call(tab)
    if not m_controller or not m_action then
        if router.remains then
            tab = _M.parse_url(router.remains.path, router.remains.params)
            m_controller, m_action = _M.call(tab)
        end
    end
    if not m_controller then
        local dir = tab.layer and tab.layer..'/'..tab.controller or tab.controller
        func.show_404('the controller file apps/controllers/'..dir..'.lua'..' does not exists or it is not a controller module')
    elseif not m_action then
        func.show_404('the action '..tab.action..' is not exists')
    else
        local mt = {__index = base_controller}
        setmetatable(m_controller, mt)
        if m_controller.init then
            m_controller.init(m_controller)
        end
        m_controller:init_view(m_controller)
        m_controller.layer = tab.layer
        m_controller.controller = tab.controller
        m_controller.action = tab.action
        m_controller.params = tab.params
        return m_controller[tab.action](m_controller)
    end
end





return _M
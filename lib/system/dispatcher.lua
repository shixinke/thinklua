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

function _M.dispatch(url_tab)
    local default_controller = config.routes.default_controller or 'index'
    local default_action = config.routes.default_action or 'index'
    local uri = url_tab.path
    local layer,controller,action
    local args = url_tab.params or {}
    local layers

    if config.routes.layer_status == 'on' and config.routes.layers then
        layers = func.explode(',', config.routes.layers)
    end
    if uri == '/' then
        controller = default_controller
        action = default_action
    else
        local iterator, err = regex.gmatch(uri, '/([a-zA-Z0-9-_]+)', 'ijo')
        local m
        if not iterator then
            log(ngx.ERR, err)
            return
        end
        local mat = {}
        local m, err = iterator()
        while m do
            mat[#mat+1] = m[1]
            m, err = iterator()
        end
        local count = #mat
        if count <= 2 then
            if layers and func.in_array(mat[1], layers) then
                layer = mat[1]
                controller = mat[2] or default_controller
                action = default_action
            else
                controller = mat[1] or default_controller
                action = mat[2] or default_action
            end
        else
            if layers and func.in_array(mat[1], layers) then
                layer = mat[1]
                controller = mat[2]
                action = mat[3]
                for i = 4, count, 2 do
                    if mat[i+1] then
                        args[mat[i]] = mat[i+1]
                    end
                end
            else
                controller = mat[1]
                action = mat[2]
                for i = 3, count, 2 do
                    if mat[i+1] then
                        args[mat[i]] = mat[i+1]
                    end
                end
            end
        end
    end

    local ok, m_controller
    if layer then
        ok, m_controller = pcall(require, 'controllers.'..layer..'.'..controller)
    else
        ok, m_controller = pcall(require, 'controllers.'..controller)
    end

    if not ok or type(m_controller) ~= 'table' then
        local dir = layer and layer..'/'..controller or controller
        func.show_404('the controller file apps/controllers/'..dir..'.lua'..' does not exists or it is not a controller module')
    else
        if not m_controller[action] or type(m_controller[action]) ~= 'function' then
            func.show_404('the action '..action..' is not exists')
        end
        local mt = {__index = base_controller}
        setmetatable(m_controller, mt)
        if m_controller.init then
            m_controller.init(m_controller)
        end
        m_controller:init_view(m_controller)
        m_controller.layer = layer
        m_controller.controller = controller
        m_controller.action = action
        m_controller.params = args
        return m_controller[action](m_controller)
    end

end





return _M
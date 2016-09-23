local _M = {
    _VERSION = '0.01'
}

local ngx_req = ngx.req
local view = require 'system.view'

function _M.init_view(self)
    self.view = view:new()
end

function _M.assign(self, name, value)
    self.view:assign(name, value)
end

function _M.get(name)
    local data = ngx.req.get_uri_args()
    if name then
        if data and data[name] then
            return data[name]
        end
    else
        return data
    end
end

function _M.post(name)
    local data = ngx_req.get_post_args
    if name then
        if data and data[name] then
            return data[name]
        end
    else
        return data
    end
end

function _M.display(self, tpl, data)
    if data then
        self:assign(data)
    end
    if not tpl then
        tpl = self.controller..'/'..self.action..'.html'
    end
    self.view:display(tpl, data)
end

return _M
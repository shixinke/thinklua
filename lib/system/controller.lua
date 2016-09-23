local _M = {
    _VERSION = '0.01'
}

local ngx_req = ngx.req
local view = require 'system.view'
local header = ngx.header

function json(code, message, data)
    local tab = {}
    if type(code) == 'table' then
        tab = code
    else
        tab.code = code
        tab.message = message
        tab.data = data
    end
    return json.encode(tab)
end

function _M.init_view(self)
    self.view = view:new()
end

function _M.assign(self, name, value)
    self.view:assign(name, value)
end

function _M.get(self, name)
    local data = func.merge(self.params, ngx_req.get_uri_args())
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

function _M.json(code, message, data)
    header.header = 'content-type:application/json;charset='..config.pages.charset
    ngx.say(json(code, message, data))
end

function _M.jsonp(code, message, data, callback)
    local callback = type(code) == 'table' and message or callback
    local msg = callback..'('..json(code, message, data)..')'
    ngx.say(msg)
end

return _M
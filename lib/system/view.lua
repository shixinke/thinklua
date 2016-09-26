local _M = {
    _VERSION = '0.01'
}

local mt = {
    __index = _M
}

local template = require 'resty.template'
local layout = 'layouts/layout.html'

function _M.new(opts)
    local opts = opts or {}
    opts.withoutLayout = opts.withoutLayout or nil
    if opts.withoutLayout then
        opts.layout = nil
    else
        opts.layout = opts.layout or layout
    end
    return setmetatable({
        template = template,
        withoutLayout = opts.withoutLayout,
        assign_data = {},
        caching = config.debug,
        layout = opts.layout
    }, mt)
end

function _M.assign(self, name, value)
    if type(name) == 'table' then
        for i, v in pairs(name) do
            self.assign_data[i] = v
        end
    else
        self.assign_data[name] = value
    end
end

function _M.display(self, tpl, data)
    if data then
        self:assign(data)
    end
    local view     = self.template.new(tpl, self.layout)

    self.template.caching(self.caching)
    if not view then
        return nil, 'initialize the template failed,plesase check the template if exists'
    end
    for k, v in pairs(self.assign_data) do
        view[k] = v
    end
    return view:render()
end

return _M
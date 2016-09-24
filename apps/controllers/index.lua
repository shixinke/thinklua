local _M = {
    _VERSION = '0.01'
}

function _M.new()

end

function _M.index(self)
    local province = require 'models.province'
    ngx.say(self:get('id'))
    local obj = province:new()
    self:assign('name', 'perfect value')
    self:display()
end

function _M.hello(self)
    self:assign('name', 'value')
    self:display()
end

function _M.lists(self)
    ngx.say('index lists')
end

return _M
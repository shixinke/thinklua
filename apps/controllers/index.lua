local _M = {
    _VERSION = '0.01'
}

function _M.new()

end

function _M.index(self)
    self.withoutLayout = true
    self:assign('name', 'value')
    self:display()
end

function _M.hello(self)
    self:assign('name', 'value')
    self:display()
end

return _M
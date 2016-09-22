local _M = {
    _VERSION = '0.01'
}

local router = require 'system.router'

function _M.run()
    router.route()
end

return _M
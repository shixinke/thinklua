local _M = {
    _VERSION = '0.01'
}

local dispatcher = require 'system.dispatcher'

function _M.run()
    dispatcher.dispatch()
end

return _M
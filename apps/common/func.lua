local _M = {
    _VERSION = '0.01'
}

local debug = config.debug

function _M.show_404(msg)
    if debug then
        ngx.say(msg)
        ngx.exit(ngx.HTTP_OK)
    else
        ngx.redirect(config.pages.not_found)
    end
end

function _M.show_error(code, err)
    if debug then
        ngx.say('code:'..code..',error:'..err)
        ngx.exit(ngx.HTTP_OK)
    else
        ngx.log(ngx.ERR, err)
        ngx.redirect(config.pages.server_error)
    end
end

return _M
local _M = {
    _VERSION = '0.01'
}



local debug = config.debug
local base_model = require 'system.model'
local regex = ngx.re
local strlen = string.len
local substr = string.sub
local session = require 'resty.session'

function _M.trim(str)
    local m, err = regex.match(str, "[^s]+.+[^s]+", 'ijso')
    if m then
        return m[0]
    else
        return str, err
    end
end

function _M.is_empty_table(tab)
    local num = 0
    for _, _ in pairs(tab) do
        num = num + 1
    end
    if num > 0 then
        return false
    else
        return true
    end
end

function _M.extends(child, parent)
    local mt = {__index = parent}
    return setmetatable(child, mt)
end

function _M.extends_model(model)
    return _M.extends(model, base_model)
end

function _M.merge(tab1, tab2)
    local obj = tab1 or {}
    for k, v in pairs(tab2) do
        if v ~= nil then
            obj[k] = v
        end
    end
    return obj
end

function _M.in_array(ele, tab)
    if ele == nil or type(ele) == 'table' or type(tab) ~= 'table' then
        return nil
    end
    local matched,i,v
    for i, v in pairs(tab) do
        if v == ele then
            matched = i
            break
        end
    end
    return matched
end

function _M.clear_table(tab)
    local obj = {}
    for k, v in pairs(tab) do
        if v then
            obj[k] = v
        end
    end
    return obj
end

function _M.table_length(tab, except)
    local len = 0
    for k, v in pairs(tab) do
        if v and except then
            len = len+1
        else
            len = len+1
        end
    end
    return len
end

function _M.split(str, pattern)
    local tab = {}
    local iterator, err = regex.gmatch(str, pattern, 'ijso')
    if not iterator then
        tab = {str}
        return tab, err
    end
    local m, err = iterator()
    if not m then
        tab = {str}
        return tab, err
    end
    while m do
        tab[#tab+1] = m[1]
        m = iterator()
    end
    return tab
end

function _M.explode(delimiter, str)
    local tab = {}
    if type(str) ~= 'string' or delimiter == nil then
        return tab
    end

    local delen = -strlen(delimiter)
    local subs = substr(str, delen)
    if subs ~= delimiter then
        str = str..delimiter
    end
    local pattern
    if _M.in_array(delimiter, {'|'}) then
        pattern = '([^'..delimiter..']+)\\'..delimiter
    else
        pattern = '([^'..delimiter..']+)'..delimiter
    end
    return _M.split(str, pattern)
end


function _M.url_parse(url)
    local url_tab = {path = nil, params = {} }
    if url == nil then
        return nil, 'the url is nil'
    end
    local m, err = regex.match(url, '([^\\?]+)\\?([^\\?]+)')
    if not m then
        url_tab.path = url
        return url_tab, err
    end
    url_tab.path = m[1]
    local iterator, err = regex.gmatch(m[2], '([a-zA-Z0-9_-]+)=([a-zA-Z0-9_-]+)', 'ijso')
    if not iterator then
        url_tab.params = {}
        return url_tab, err
    end
    local m, err = iterator()
    if not m then
        url_tab.params = {}
        return url_tab, err
    end
    while m do
        url_tab.params[m[1]] = m[2]
        m = iterator()
    end
    return url_tab
end

function _M.implode(delimiter, tab)
    local str = ''
    if type(tab) ~= 'table' or delimiter == nil then
        return str
    end
    local count = #tab
    for i, v in pairs(tab) do
        if type(v) ~= 'table' then
            str = str..v
            if i ~= count then
                str = str..delimiter
            end
        end
    end
    return str
end

-- 设置session的封闭(依赖于lua-resty-session)
function _M.set_session(key, value)
    local sess = session.start({secret = config.security.session.secret})
    if sess.data[key] then
        if type(value) == 'table' then
            for k, v in pairs(value) do
                sess.data[key][k] = v
            end
        else
            sess.data[key] = value
        end
    else
        sess.data[key] = value
    end
    return sess:save()
end

-- 获取session信息
function _M.get_session(key)
    local sess = session.open({secret = config.security.session.secret})
    local data = sess.data or {}
    if key then
        return data[key]
    end
    return data
end


function _M.show_404(msg)
    if debug then
        local html = '<meta charset="utf-8"><div style="position: relative;padding: 15px 15px 15px 55px;margin-bottom: 20px;font-size: 14px;background-color: #fafafa;border: solid 1px #d8d8d8;border-radius: 3px;">'..msg..'</div>'
        ngx.say(html)
        ngx.exit(ngx.HTTP_OK)
    else
        ngx.redirect(config.pages.not_found)
    end
end

function _M.show_error(code, err)
    if debug then
        local html = '<meta charset="utf-8"><div style="position: relative;padding: 15px 15px 15px 55px;margin-bottom: 20px;font-size: 14px;background-color: #fafafa;border: solid 1px #d8d8d8;border-radius: 3px;line-height:35px;"><p>error code:'..code..'</p><p>error msg:'..err..'</p></div>'
        ngx.say(html)
        ngx.exit(ngx.HTTP_OK)
    else
        ngx.log(ngx.ERR, err)
        ngx.redirect(config.pages.server_error)
    end
end



function _M.password(password)
    local salt = config.security.password_salt or 'shixinke'
    return ngx.md5(password..salt)
end

return _M
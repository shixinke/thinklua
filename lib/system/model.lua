local _M = {
    _VERSION = '0.01'
}
local mysql = require "resty.mysql"
local mt = { __index = _M }
local upper = string.upper
local lower = string.lower


function _M.connect(self, db)
    db:set_timeout(self.config.timeout)
    return db:connect({
        host = self.config.host or '127.0.0.1',
        port = self.config.port or 3306,
        database = self.config.database or 'test',
        user = self.config.user,
        password = self.config.password})
end

function _M.set_keepalive(self, db)
    return db:set_keepalive(self.config.max_idle_timeout, self.config.pool_size)
end

function _M.query(self, sql)
    local sql, err = sql or self:build_query_sql()
    if sql == nil then
        return nil, err
    end
    return self:exec(sql)
end

function _M.exec(self, sql)
    local db, err = mysql:new()
    self.sql = sql
    if not db then
        return nil, err
    end

    local ok, err, errcode, sqlstate = self:connect(db)
    if not ok then
        return nil, err, errcode, sqlstate
    end
    self.db = db
    local res, err, errcode, sqlstate = db:query('SET NAMES `'..self.config.charset..'`')
    if not res then
        return err, errcode, sqlstate
    end

    local res, err, errcode, sqlstate = db:query(sql)
    if not res then
        return nil, err, errcode, sqlstate
    end
    if self.remains ~= true then
        self._condition = {fields = {}, where = {}, group = {}, order = {}, limit = nil }
    end
    self:set_keepalive(db)
    return res
end

function _M.fields(self, fields)
    if fields == nil then
        return self
    end
    self._condition['fields'] = self._condition['fields'] or {}
    if type(fields) == 'table' then
        for _, v in pairs(fields) do
            self._condition.fields[v] = true
        end
    else
        local tab = func.explode(',', fields)
        for _, v in pairs(tab) do
            self._condition.fields[v] = true
        end
    end

    return self
end

function _M.table(self, tab)
    if tab then
        self.table_name = tab
    end
    return self
end

function _M.where(self, field, condition, value)
    if field == nil then
        return self
    end
    if type(field) == 'table' then
        for k, v in pairs(field) do
            self._condition.where[k] = type(self._condition.where[k]) == 'table' and self._condition.where[k] or {}
            if type(v) == 'table' then
                if v[2] then
                    self._condition.where[k][1] = v[1]
                    self._condition.where[k][2] = v[2]
                else
                    self._condition.where[k][1] = (v[1] and upper(v[1]) == 'NULL') and 'ISNULL' or '='
                    self._condition.where[k][2] =  self._condition.where[k][1] == '=' and v[1] or nil
                end
            else

                self._condition.where[k][1] = (v and upper(v) == 'NULL') and 'ISNULL' or '='
                self._condition.where[k][2] =  self._condition.where[k][1] == '=' and v or nil
            end
        end
    else
        if type(self._condition.where[field]) ~= 'table' then
            self._condition.where[field] = {}
        end
        if value then
            if condition then
                self._condition.where[field][1] = condition
                self._condition.where[field][2] = value
            else
                self._condition.where[field][1] = '='
                self._condition.where[field][2] = value
            end
        elseif condition then
            self._condition.where[field][1] = condition
            self._condition.where[field][2] = nil
        else
            self._condition.where[field][1] = 'STRING'
            self._condition.where[field][2] = field
        end
    end
    return self
end

function _M.build_query_sql(self, tab)
    local tab = tab or self.table_name
    if tab == nil then
        return nil, 'the table name is nil'
    end
    local sql = 'SELECT '
    if func.is_empty_table(self._condition.fields) ~= true then
        local field_len = func.table_length(self._condition.fields)
        local field_index = 0
        for k,_ in pairs(self._condition.fields) do
            field_index = field_index + 1
            sql = sql..'`'..k..'`'
            if field_index < field_len then
                sql = sql..','
            end
        end
    else
        sql = sql..'* '
    end
    sql = sql..' FROM '..tab..' '..self:parse_where()
    if func.is_empty_table(self._condition.group) ~= true then
        sql = sql..' GROUP BY '
        local group_len = func.table_length(self._condition.group)
        local group_index = 0
        for k,_ in pairs(self._condition.group) do
            sql = sql..'`'..k..'`'
            if group_index < group_len then
                sql = sql..','
            end
        end
    end
    if func.is_empty_table(self._condition.order) ~= true then
        sql = sql..' ORDER BY '
        local order_len = func.table_length(self._condition.order)
        local index = 0;
        for k,v in pairs(self._condition.order) do
            index = index + 1
            sql = sql..'`'..k..'` '..v
            if index < order_len then
                sql = sql..','
            end
        end
    end
    if self._condition.limit then
        sql = sql..' LIMIT '..self._condition.limit
    end
    return sql
end

function _M.parse_where(self)
    local where = {};
    local where_str = ''
    for k, v in pairs(self._condition.where) do
        v[1] = upper(v[1])
        if v[1] == '!ISNULL' then
            where[#where+1] = '!ISNULL(`'..k..'`)'
        elseif v[1] == 'ISNULL' or v[2] == nil then
            where[#where+1] = 'ISNULL(`'..k..'`)';
        elseif v[1] == 'STRING' then
            where[#where+1] = v[2]
        elseif v[1] == 'LIKE' then
            where[#where+1] = '`'..v[1]..'` LIKE "%'..v[2]..'%"'
        elseif v[1] == 'IN' or v[1] == 'NOT IN' then
            if type(v[2]) ~= 'table' then
                v[2] = func.explode(',', v[2])
            end
            local count = #v[2]
            local ranges = ''
            for i, v in pairs(v[2]) do
                ranges = '"'..ranges..'"'
                if i ~= count then
                    ranges = ranges..','
                end
            end
            where[#where+1] = '`'..k..'` '..v[1]..' ('..ranges..')'
        elseif v[1] == 'BETWEEN' then
            if type(v[2]) ~= 'table' then
                v[2] = func.explode(',', v[2])
            end
            if v[2][2] then
                where[#where+1] = '`'..k..'` BETWEEN "'..v[2][1]..'" AND "'..v[2][2]..'"'
            end
        else
            if type(v[2]) ~= 'table' then
                where[#where+1] = '`'..k..'`  '..v[1]..' "'..v[2]..'"'
            end
        end
    end
    if #where > 0 then
        where_str = ' WHERE '..func.implode(' AND ', where)
    end
    return where_str
end

function _M.group(self, field)
    if field == nil then
        return self
    end
    if type(field) ~= 'table' then
        field = func.explode(',', field)
    end
    for _, v in pairs(field) do
        self._condition.group[v] = true
    end

    return self
end

function _M.order(self, field, direction)
    if field == nil then
        return self
    end
    if type(field) == 'table' then
        self._condition.order[field[1]] = field[2] and upper(field[2]) or 'ASC'
    else
        self._condition.order[field] = direction and upper(direction) or 'ASC'
    end
    return self
end

function _M.limit(self, offset, limit)
    if offset == nil then
        return self
    end
    local limit = limit and tonumber(limit) or 0
    self._condition.limit = tonumber(limit) > 0 and (offset..','..limit) or offset
    return self
end

function _M.count(self, tab, where)
    self:where(where)
    self:table(tab)
    local sql = 'SELECT COUNT(*) AS total FROM '..self.table_name..' '..self:parse_where()..' LIMIT 1'
    local res, err, errcode, sqlstate = self:query(sql)
    if res then
        return res[1]['total']
    else
        return nil, err, errcode, sqlstate
    end
end

function _M.find(self, tab, field, where)
    self:table(tab)
    self:fields(field)
    self:limit(1)
    self:where(where)
    local res, err, errcode, sqlstate = self:query()
    if res then
        return res[1]
    else
        return nil, err, errcode, sqlstate
    end
end

function _M.findAll(self, tab, field, where)
    self:table(tab)
    self:fields(field)
    self:where(where)
    return self:query()
end

function _M.insert(self, tab, data)
    self:table(tab)
    if data == nil or self.table_name == nil then
        return false, 'the data is nil or table name is nil'
    end
    local data = func.clear_table(data)
    local sql = 'INSERT INTO '..self.table_name..'('
    local fields = ''
    local values = ''
    local len = func.table_length(data)
    local n = 0
    for k, v in pairs(data) do
        fields = fields..'`'..k..'`'
        values = values..'"'..v..'"'
        n = n+1
        if n< len then
            fields = fields..','
            values = values..','
        end
    end
    sql = sql..fields..')VALUES ('..values..')'
    local res, err, errcode, sqlstate = self:exec(sql)
    if res then
        return res.insert_id and res.insert_id or res.affected_rows
    else
        return nil, err, errcode, sqlstate
    end
end

function _M.update(self, tab, data, where)
    self:table(tab)
    self:where(where)
    if data == nil or self.table_name == nil then
        return false, 'the data is nil or table name is nil'
    end
    local data = func.clear_table(data)
    local data_len = func.table_length(data)
    local sql = 'UPDATE '..self.table_name..' SET '
    local data_index = 0
    for k, v in pairs(data) do
        data_index = data_index + 1
        sql = sql..'`'..k..'`='..'"'..v..'"'
        if data_index < data_len then
            sql = sql..','
        end
    end
    if func.is_empty_table(self._condition.where) then
        if self.pk and data[self.pk] then
            local cond = {}
            cond[self.pk] = data[self.pk]
            self:where(cond)
        end
    end
    local where = self:parse_where()
    if where == '' then
        return nil, 'the condition cannot be nil in update operation'
    end
    sql = sql..where
    local res, err, errcode, sqlstate = self:exec(sql)
    if res then
        return res.affected_rows > 0 and true or false
    else
        return nil, err, errcode, sqlstate
    end
end

function _M.delete(self, tab, where)
    self:table(tab)
    self:where(where)
    local sql = 'DELETE FROM '..self.table_name
    local where = self:parse_where()
    if where == '' then
        return nil, 'the condition cannot be nil in delete operation'
    end
    sql = sql..where
    local res, err, errcode, sqlstate = self:exec(sql)
    if res then
        return res.affected_rows > 0 and true or false
    else
        return err, errcode, sqlstate
    end
end

function _M.get_last_sql(self)
    return self.sql
end

function _M.new(self, opts)
    local opts = (opts and type(opts) == 'table') and opts or {}
    opts.host = opts.host or config.database.host
    opts.port = opts.port or config.database.port
    opts.user = opts.user or config.database.user
    opts.password = opts.password or config.database.password
    opts.database = opts.database or config.database.database
    opts.charset = (opts.charset or config.database.charset) or 'utf8'
    opts.timeout = opts.timeout or config.database.timeout
    opts.max_idle_timeout = opts.max_idle_timeout or config.database.max_idle_timeout
    opts.pool_size = opts.pool_size or config.database.pool_size
    self.config = opts
    self.table_name = self.table_name or opts.table_name
    self.db = self.db or nil
    --self.pk = self.pk or nil
    self._condition = {fields = {}, where = {}, group = {}, order = {}, limit = nil }
    self.remains = false
    self.sql = nil
    return setmetatable(self, mt)
end

function _M.close(self)
    if self.db then
        self.db:close()
    end
end

return _M

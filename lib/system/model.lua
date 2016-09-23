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
    ngx.say(sql)
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
    local res, err, errcode, sqlstate = db:query('SET NAMES `'..self.charset..'`')
    if not res then
        return err, errcode, sqlstate
    end

    local res, err, errcode, sqlstate = db:query(sql)
    if not res then
        return nil, err, errcode, sqlstate
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

function _M.table(self, table_name)
    if table_name then
        self.table = table_name
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

function _M.build_query_sql(self, table)
    local table = table or self.table
    if table == nil then
        return nil, 'the table name is nil'
    end
    local sql = 'SELECT '
    if func.is_empty_table(self._condition.fields) ~= false then
        for k,_ in pairs(self._condition.fields) do
            sql = sql..'`'..k..'`'
            if next(self._condition.fields) then
                sql = sql..','
            end
        end
    else
        sql = sql..'* '
    end
    sql = sql..' FROM '..table..' '..self:parse_where()
    if func.is_empty_table(self._condition.group) then
        sql = sql..' GROUP BY '
        for k,_ in pairs(self._condition.group) do
            sql = sql..'`'..k..'`'
            if next(self._condition.group) then
                sql = sql..','
            end
        end
    end
    if func.is_empty_table(self._condition.order) then
        sql = sql..' ORDER BY '
        for k,v in pairs(self._condition.order) do
            sql = sql..'`'..k..'` '..v
            if next(self._condition.order) then
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
            where[#where+1] = '!ISNULL('..k..')'
        elseif v[1] == 'ISNULL' or v[2] == nil then
            where[#where+1] = 'ISNULL('..k..')';
        elseif v[1] == 'STRING' then
            where[#where+1] = v[2]
        elseif v[1] == 'LIKE' then
            where[#where+1] = v[1]..' LIKE "%'..v[2]..'%"'
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
            where[#where+1] = k..' '..v[1]..' ('..ranges..')'
        elseif v[1] == 'BETWEEN' then
            if type(v[2]) ~= 'table' then
                v[2] = func.explode(',', v[2])
            end
            if v[2][2] then
                where[#where+1] = k..' BETWEEN "'..v[2][1]..'" AND "'..v[2][2]..'"'
            end
        else
            if type(v[2]) ~= 'table' then
                where[#where+1] = k..'  '..v[1]..' "'..v[2]..'"'
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
        self._condition.order[field[1]] = field[2] or 'ASC'
    else
        self._condition.order[field] = direction or 'ASC'
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

function _M.count(self, table, where)
    self:where(where)
    self:table(table)
    local sql = 'SELECT COUNT(*) AS total FROM '..self.table..' '..self:parse_where()..' LIMIT 1'
    local res, err, errcode, sqlstate = self:query()
    if res then
        return res[1]['total']
    else
        return nil, err, errcode, sqlstate
    end
end

function _M.find(self, table, field, where)
    self:table(table)
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

function _M.findAll(self, table, field, where)
    self:table(table)
    self:fields(field)
    self:limit(1)
    self:where(where)
    return self:query()
end

function _M.insert(self, table, data)
    self:table(table)
    if data == nil or self.table == nil then
        return false, 'the data is nil or table name is nil'
    end
    local sql = 'INSERT INTO '..self.table..'('
    local fields = ''
    local values = ''
    for k, v in pairs(data) do
        fields = fields..'`'..k..'`'
        values = values..'"'..v..'"'
        if next(data) then
            fields = fields..','
            values = values..','
        end
    end
    sql = fields..')VALUES ('..sql..')'
    local res, err, errcode, sqlstate = self:exec(sql)
    if res then
        return res.insert_id and res.insert_id or res.affected_rows
    else
        return nil, err, errcode, sqlstate
    end
end

function _M.update(self, table, data, where)
    self:table(table)
    self:where(where)
    if data == nil or self.table == nil then
        return false, 'the data is nil or table name is nil'
    end
    local sql = 'UPDATE '..self.table..' SET '
    for k, v in pairs(data) do
        sql = sql..'`'..k..'`='..'"'..v..'"'
        if next(data) then
            sql = sql..','
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

function _M.delete(self, table, where)
    self:table(table)
    self:where(where)
    local sql = 'DELETE FROM '..table
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

function _M.new(opts)
    local opts = (opts and type(opts) == 'table') and opts or {}
    opts.host = opts.host or config.database.host
    opts.port = opts.port or config.database.port
    opts.user = opts.user or config.database.user
    opts.password = opts.password or config.database.password
    opts.database = opts.database or config.database.database
    opts.charset = opts.charset or config.database.charset
    opts.timeout = opts.timeout or config.database.timeout
    opts.max_idle_timeout = opts.max_idle_timeout or config.database.max_idle_timeout
    opts.pool_size = opts.pool_size or config.database.pool_size
    return setmetatable({
        config = opts,
        table = opts.table or nil,
        db = nil,
        _condition = {fields = {}, where = {}, group = {}, order = {}, limit = nil},
        sql = sql }, mt)
end

function _M.close(self)
    if self.db then
        self.db:close()
    end
end

return _M
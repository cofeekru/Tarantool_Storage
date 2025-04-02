local httpd = require('http.server')
local json = require('json')
local log = require('log')

box.cfg{
    listen = '3031',
    log = 'text.log'
}
box.schema.create_space('kv', {if_not_exists = true})
box.space.kv:create_index('primary', {parts = {1, 'string'}, if_not_exists = true})
box.schema.user.enable('guest', {if_not_exists = true})


local function getValue(key)
    local result = box.space.kv:select(key)
    if #result == 0 then
        return nil
    else
        return result[1][2] 
    end
end

local function insertValue(key, value)
    local result = box.space.kv:insert({key, value})
    return result
end

local function updateValue(key, value)
    local result = box.space.kv:replace({key, value})
    return result
end

local function deleteValue(key)
    local result = box.space.kv:delete({key})
    return result
end

local function postHandler(req)
    local body = req:read()
    local data = json.decode(body)

    local key = data['key']
    local value = data['value']

    if not key or not value then
        log.warn('POST /kv: Invalid JSON body')
        return { status = 400, body = 'Bad Request: Invalid JSON'}
    end

    if getValue(key) then
        log.warn('POST /kv: Key \'%s\' already exists', key)
        return { status = 409, body = 'Key already exists'}
    end

    insertValue(key, value)
    log.info('POST /kv: Inserted new key-value')

    return { status = 201, body = 'Created'}
end

local function putHandler(req)
    local body, err = req:read()
    if not err then
	    return {status = 400, body = 'Bad request: Invalid body'}
    end
    
    local data = json.decode(body)
    if not data then
        log.warn('PUT /kv: Invalid JSON body')
        return { status = 400, body = 'Bad Request: Invalid JSON'}
    end

    local path = req.path
    local reg = '/%w+'
    local key = path:match(reg, 2):sub(2)
    local value = data['value']

    local err = getValue(key)
    if not err then
        log.warn('PUT /kv: Key does not exists')
        return { status = 404, body = "Bad Request: Key does not exists" }
    else
        updateValue(key, value)
        log.info('PUT /kv, %s is updated', key)
        return {status = 201, body = "Updated"}
    end
end

local function getHandler(req)
    local path = req.path
    local reg = '/%w+'
    local key = path:match(reg, 2):sub(2)
    local value = getValue(key)
    
    if not value then
        log.warn('GET /kv/%s: Missing key', key)
        return {status = 404, body = "Bad Request: Key does not exists"}
    end

    log.info('GET /kv: Value received')
    return {status = 201, body = json.encode(value)}

end

local function deleteHandler(req)
    local path = req.path
    local reg = '/%w+'
    local key = path:match(reg, 2):sub(2)
    local value = getValue(key)

    if not value then
        log.warn('GET /kv: Missing key')
        return {status = 404, body = "Bad Request: Key does not exists" }
    end

    deleteValue(key)
    log.info('GET /kv: Key deleted', key)

    return { status = 201, body = 'Deleted'}
end

local function errorHandler(req)
    return { status = 404, body = 'Error path'}
end

local server = httpd.new('0.0.0.0', 8080, {
    log_requests = true,
    log_errors = true
})

server:route({path = '/kv', method = 'POST'}, postHandler)
server:route({path = '/kv/%w+', method = 'PUT'}, putHandler)
server:route({path = '/kv/%w+', method = 'GET'}, getHandler)
server:route({path = '/kv/%w+', method = 'DELETE'}, deleteHandler)
server:route({path = '/%w+'}, errorHandler)

server:start()

local redis = {
_VERSION = 'redis-lua 2.0.4',
_DESCRIPTION = 'A Lua client library for the redis key value storage system.',
_COPYRIGHT   = 'Copyright (C) 2009-2012 Daniele Alessandri',
}
Redis = redis
local unpack = _G.unpack or table.unpack
local network, request, response = {}, {}, {}
local defaults = {
host= '127.0.0.1',
port= 6379,
tcp_nodelay = true,
path= nil
}
local function merge_defaults(parameters)
if parameters == nil then
parameters = {}
end
for k, v in pairs(defaults) do
if parameters[k] == nil then
parameters[k] = defaults[k]
end
end
return parameters
end
local function parse_boolean(v)
if v == '1' or v == 'true' or v == 'TRUE' then
return true
elseif v == '0' or v == 'false' or v == 'FALSE' then
return false
else
return nil
end
end
local function toboolean(value) return value == 1 end
local function sort_request(client, command, key, params)
local query = { key }
if params then
if params.by then
table.insert(query, 'BY')
table.insert(query, params.by)
end
if type(params.limit) == 'table' then
table.insert(query, 'LIMIT')
table.insert(query, params.limit[1])
table.insert(query, params.limit[2])
end
if params.get then
if (type(params.get) == 'table') then
for _, getarg in pairs(params.get) do
table.insert(query, 'GET')
table.insert(query, getarg)
end
else
table.insert(query, 'GET')
table.insert(query, params.get)
end
end
if params.sort then
table.insert(query, params.sort)
end
if params.alpha == true then
table.insert(query, 'ALPHA')
end
if params.store then
table.insert(query, 'STORE')
table.insert(query, params.store)
end
end
request.multibulk(client, command, query)
end
local function zset_range_request(client, command, ...)
local args, opts = {...}, { }
if #args >= 1 and type(args[#args]) == 'table' then
local options = table.remove(args, #args)
if options.withscores then
table.insert(opts, 'WITHSCORES')
end
end
for _, v in pairs(opts) do table.insert(args, v) end
request.multibulk(client, command, args)
end
local function zset_range_byscore_request(client, command, ...)
local args, opts = {...}, { }
if #args >= 1 and type(args[#args]) == 'table' then
local options = table.remove(args, #args)
if options.limit then
table.insert(opts, 'LIMIT')
table.insert(opts, options.limit.offset or options.limit[1])
table.insert(opts, options.limit.count or options.limit[2])
end
if options.withscores then
table.insert(opts, 'WITHSCORES')
end
end
for _, v in pairs(opts) do table.insert(args, v) end
request.multibulk(client, command, args)
end
local function zset_range_reply(reply, command, ...)
local args = {...}
local opts = args[4]
if opts and (opts.withscores or string.lower(tostring(opts)) == 'withscores') then
local new_reply = { }
for i = 1, #reply, 2 do
table.insert(new_reply, { reply[i], reply[i + 1] })
end
return new_reply
else
return reply
end
end
local function zset_store_request(client, command, ...)
local args, opts = {...}, { }
if #args >= 1 and type(args[#args]) == 'table' then
local options = table.remove(args, #args)
if options.weights and type(options.weights) == 'table' then
table.insert(opts, 'WEIGHTS')
for _, weight in ipairs(options.weights) do
table.insert(opts, weight)
end
end
if options.aggregate then
table.insert(opts, 'AGGREGATE')
table.insert(opts, options.aggregate)
end
end
for _, v in pairs(opts) do table.insert(args, v) end
request.multibulk(client, command, args)
end
local function mset_filter_args(client, command, ...)
local args, arguments = {...}, {}
if (#args == 1 and type(args[1]) == 'table') then
for k,v in pairs(args[1]) do
table.insert(arguments, k)
table.insert(arguments, v)
end
else
arguments = args
end
request.multibulk(client, command, arguments)
end
local function hash_multi_request_builder(builder_callback)
return function(client, command, ...)
local args, arguments = {...}, { }
if #args == 2 then
table.insert(arguments, args[1])
for k, v in pairs(args[2]) do
builder_callback(arguments, k, v)
end
else
arguments = args
end
request.multibulk(client, command, arguments)
end
end
local function parse_info(response)
local info = {}
local current = info
response:gsub('([^\r\n]*)\r\n', function(kv)
if kv == '' then return end
local section = kv:match('^# (%w+)$')
if section then
current = {}
info[section:lower()] = current
return
end
local k,v = kv:match(('([^:]*):([^:]*)'):rep(1))
if k:match('db%d+') then
current[k] = {}
v:gsub(',', function(dbkv)
local dbk,dbv = kv:match('([^:]*)=([^:]*)')
current[k][dbk] = dbv
end)
else
current[k] = v
end
end)
return info
end
local function load_methods(proto, commands)
local client = setmetatable ({}, getmetatable(proto))
for cmd, fn in pairs(commands) do
if type(fn) ~= 'function' then
redis.error('invalid type for command ' .. cmd .. '(must be a function)')
end
client[cmd] = fn
end
for i, v in pairs(proto) do
client[i] = v
end
return client
end
local function create_client(proto, client_socket, commands)
local client = load_methods(proto, commands)
client.error = redis.error
client.network = {
socket = client_socket,
read   = network.read,
write  = network.write,
}
client.requests = {
multibulk = request.multibulk,
}
return client
end
function network.write(client, buffer)
local _, err = client.network.socket:send(buffer)
if err then client.error(err) end
end
function network.read(client, len)
if len == nil then len = '*l' end
local line, err = client.network.socket:receive(len)
if not err then return line else
print("\27[36m"..[[                                           
 _____ _____ ___   _ ____  
|_   _| ____| |  / \  | \ | |  _ \ 
  | | |  _| | | / _ \ |  \| | | | |
  | | | |___| |___ / ___ \| |\  | |_| |
  |_| |_____|_____/_/   \_\_| \_|____/
> CH › @IIIS1
> CH › @TELANDTEAM
~> DEVELOPER › @VVVZVV
]]..'\27[m')
Info = dofile("Info.lua")
User = Info.User
token = Info.token
if User then
https = require("ssl.https")
URL = require("./library/url.lua")  
https.request('https://api.telegram.org/bot'..token..'/sendMessage?chat_id='..User..'&text='..URL.escape("⌯︙لقد توقف البوت بسبب انهاير الريدز في السيرفر افتح الترمنال وارسل ↫ ⤈\n`service redis start` ")..'&parse_mode=Markdown')
end
os.exit()
end
end
function response.read(client)
local payload = client.network.read(client)
local prefix, data = payload:sub(1, -#payload), payload:sub(2)
if prefix == '+' then
if data == 'OK' then
return true
elseif data == 'QUEUED' then
return { queued = true }
else
return data
end
elseif prefix == '-' then
return client.error('redis error: ' .. data)
elseif prefix == ':' then
local number = tonumber(data)
if not number then
if res == 'nil' then
return nil
end
client.error('cannot parse '..res..' as a numeric response.')
end
return number
elseif prefix == '$' then
local length = tonumber(data)
if not length then
client.error('cannot parse ' .. length .. ' as data length')
end
if length == -1 then
return nil
end
local nextchunk = client.network.read(client, length + 2)
return nextchunk:sub(1, -3)
elseif prefix == '*' then
local count = tonumber(data)
if count == -1 then
return nil
end
local list = {}
if count > 0 then
local reader = response.read
for i = 1, count do
list[i] = reader(client)
end
end
return list
else
return client.error('unknown response prefix: ' .. prefix)
end
end
function request.raw(client, buffer)
local bufferType = type(buffer)
if bufferType == 'table' then
client.network.write(client, table.concat(buffer))
elseif bufferType == 'string' then
client.network.write(client, buffer)
else
client.error('argument error: ' .. bufferType)
end
end
function request.multibulk(client, command, ...)
local args = {...}
local argsn = #args
local buffer = { true, true }
if argsn == 1 and type(args[1]) == 'table' then
argsn, args = #args[1], args[1]
end
buffer[1] = '*' .. tostring(argsn + 1) .. "\r\n"
buffer[2] = '$' .. #command .. "\r\n" .. command .. "\r\n"
local table_insert = table.insert
for _, argument in pairs(args) do
local s_argument = tostring(argument)
table_insert(buffer, '$' .. #s_argument .. "\r\n" .. s_argument .. "\r\n")
end
client.network.write(client, table.concat(buffer))
end
local function custom(command, send, parse)
command = string.upper(command)
return function(client, ...)
send(client, command, ...)
local reply = response.read(client)
if type(reply) == 'table' and reply.queued then
reply.parser = parse
return reply
else
if parse then
return parse(reply, command, ...)
end
return reply
end
end
end
local function command(command, opts)
if opts == nil or type(opts) == 'function' then
return custom(command, request.multibulk, opts)
else
return custom(command, opts.request or request.multibulk, opts.response)
end
end
local define_command_impl = function(target, name, opts)
local opts = opts or {}
target[string.lower(name)] = custom(
opts.command or string.upper(name),
opts.request or request.multibulk,
opts.response or nil
)
end
local undefine_command_impl = function(target, name)
target[string.lower(name)] = nil
end
local client_prototype = {}
client_prototype.raw_cmd = function(client, buffer)
request.raw(client, buffer .. "\r\n")
return response.read(client)
end
client_prototype.define_command = function(client, name, opts)
define_command_impl(client, name, opts)
end
client_prototype.undefine_command = function(client, name)
undefine_command_impl(client, name)
end
client_prototype.quit = function(client)
request.multibulk(client, 'QUIT')
client.network.socket:shutdown()
return true
end
client_prototype.shutdown = function(client)
request.multibulk(client, 'SHUTDOWN')
client.network.socket:shutdown()
end
client_prototype.pipeline = function(client, block)
local requests, replies, parsers = {}, {}, {}
local table_insert = table.insert
local socket_write, socket_read = client.network.write, client.network.read
client.network.write = function(_, buffer)
table_insert(requests, buffer)
end
client.network.read = function() return '+QUEUED' end
local pipeline = setmetatable({}, {
__index = function(env, name)
local cmd = client[name]
if not cmd then
client.error('unknown redis command: ' .. name, 2)
end
return function(self, ...)
local reply = cmd(client, ...)
table_insert(parsers, #requests, reply.parser)
return reply
end
end
})
local success, retval = pcall(block, pipeline)
client.network.write, client.network.read = socket_write, socket_read
if not success then client.error(retval, 0) end
client.network.write(client, table.concat(requests, ''))
for i = 1, #requests do
local reply, parser = response.read(client), parsers[i]
if parser then
reply = parser(reply)
end
table_insert(replies, i, reply)
end
return replies, #requests
end
do
local channels = function(channels)
if type(channels) == 'string' then
channels = { channels }
end
return channels
end
local subscribe = function(client, ...)
request.multibulk(client, 'subscribe', ...)
end
local psubscribe = function(client, ...)
request.multibulk(client, 'psubscribe', ...)
end
local unsubscribe = function(client, ...)
request.multibulk(client, 'unsubscribe')
end
local punsubscribe = function(client, ...)
request.multibulk(client, 'punsubscribe')
end
local consumer_loop = function(client)
local aborting, subscriptions = false, 0
local abort = function()
if not aborting then
unsubscribe(client)
punsubscribe(client)
aborting = true
end
end
return coroutine.wrap(function()
while true do
local message
local response = response.read(client)
if response[1] == 'pmessage' then
message = {
kind= response[1],
pattern = response[2],
channel = response[3],
payload = response[4],
}
else
message = {
kind= response[1],
channel = response[2],
payload = response[3],
}
end
if string.match(message.kind, '^p?subscribe$') then
subscriptions = subscriptions + 1
end
if string.match(message.kind, '^p?unsubscribe$') then
subscriptions = subscriptions - 1
end
if aborting and subscriptions == 0 then
break
end
coroutine.yield(message, abort)
end
end)
end
client_prototype.pubsub = function(client, subscriptions)
if type(subscriptions) == 'table' then
if subscriptions.subscribe then
subscribe(client, channels(subscriptions.subscribe))
end
if subscriptions.psubscribe then
psubscribe(client, channels(subscriptions.psubscribe))
end
end
return consumer_loop(client)
end
end
do
local function identity(...) return ... end
local emptytable = {}
local function initialize_transaction(client, options, block, queued_parsers)
local table_insert = table.insert
local coro = coroutine.create(block)
if options.watch then
local watch_keys = {}
for _, key in pairs(options.watch) do
table_insert(watch_keys, key)
end
if #watch_keys > 0 then
client:watch(unpack(watch_keys))
end
end
local transaction_client = setmetatable({}, {__index=client})
transaction_client.exec  = function(...)
client.error('cannot use EXEC inside a transaction block')
end
transaction_client.multi = function(...)
coroutine.yield()
end
transaction_client.commands_queued = function()
return #queued_parsers
end
assert(coroutine.resume(coro, transaction_client))
transaction_client.multi = nil
transaction_client.discard = function(...)
local reply = client:discard()
for i, v in pairs(queued_parsers) do
queued_parsers[i]=nil
end
coro = initialize_transaction(client, options, block, queued_parsers)
return reply
end
transaction_client.watch = function(...)
client.error('WATCH inside MULTI is not allowed')
end
setmetatable(transaction_client, { __index = function(t, k)
local cmd = client[k]
if type(cmd) == "function" then
local function queuey(self, ...)
local reply = cmd(client, ...)
assert((reply or emptytable).queued == true, 'a QUEUED reply was expected')
table_insert(queued_parsers, reply.parser or identity)
return reply
end
t[k]=queuey
return queuey
else
return cmd
end
end
})
client:multi()
return coro
end
local function transaction(client, options, coroutine_block, attempts)
local queued_parsers, replies = {}, {}
local retry = tonumber(attempts) or tonumber(options.retry) or 2
local coro = initialize_transaction(client, options, coroutine_block, queued_parsers)
local success, retval
if coroutine.status(coro) == 'suspended' then
success, retval = coroutine.resume(coro)
else
success, retval = true, 'empty transaction'
end
if #queued_parsers == 0 or not success then
client:discard()
assert(success, retval)
return replies, 0
end
local raw_replies = client:exec()
if not raw_replies then
if (retry or 0) <= 0 then
client.error("MULTI/EXEC transaction aborted by the server")
else
return transaction(client, options, coroutine_block, retry - 1)
end
end
local table_insert = table.insert
for i, parser in pairs(queued_parsers) do
table_insert(replies, i, parser(raw_replies[i]))
end
return replies, #queued_parsers
end
client_prototype.transaction = function(client, arg1, arg2)
local options, block
if not arg2 then
options, block = {}, arg1
elseif arg1 then 
options, block = type(arg1)=="table" and arg1 or { arg1 }, arg2
else
client.error("Invalid parameters for redis transaction.")
end
if not options.watch then
watch_keys = { }
for i, v in pairs(options) do
if tonumber(i) then
table.insert(watch_keys, v)
options[i] = nil
end
end
options.watch = watch_keys
elseif not (type(options.watch) == 'table') then
options.watch = { options.watch }
end
if not options.cas then
local tx_block = block
block = function(client, ...)
client:multi()
return tx_block(client, ...)
end
end
return transaction(client, options, block)
end
end
do
local monitor_loop = function(client)
local monitoring = true
local pattern = '^(%d+%.%d+)( ?.- ?) ?"(%a+)" ?(.-)$'
local abort = function()
monitoring = false
end
return coroutine.wrap(function()
client:monitor()
while monitoring do
local message, matched
local response = response.read(client)

local ok = response:gsub(pattern, function(time, info, cmd, args)
message = {
timestamp = tonumber(time),
client= info:match('%d+.%d+.%d+.%d+:%d+'),
database  = tonumber(info:match('%d+')) or 0,
command   = cmd,
arguments = args:match('.+'),
}
matched = true
end)
if not matched then
client.error('Unable to match MONITOR payload: '..response)
end
coroutine.yield(message, abort)
end
end)
end
client_prototype.monitor_messages = function(client)
return monitor_loop(client)
end
end
local function connect_tcp(socket, parameters)
local host, port = parameters.host, tonumber(parameters.port)
local ok, err = socket:connect(host, port)
if not ok then
print("\27[34m"..[[BY : @VVVZVV:]].."\27[m")
os.exit()
end 
socket:setoption('tcp-nodelay', parameters.tcp_nodelay)
return socket
end
local function connect_unix(socket, parameters)
local ok, err = socket:connect(parameters.path)
if not ok then
redis.error('could not connect to '..parameters.path..' ['..err..']')
end
return socket
end
local function create_connection(parameters)
if parameters.socket then
return parameters.socket
end
local perform_connection, socket
if parameters.scheme == 'unix' then
perform_connection, socket = connect_unix, require('socket.unix')
assert(socket, 'your build of LuaSocket does not support UNIX domain sockets')
else
if parameters.scheme then
local scheme = parameters.scheme
assert(scheme == 'redis' or scheme == 'tcp', 'invalid scheme: '..scheme)
end
perform_connection, socket = connect_tcp, require('socket').tcp
end
return perform_connection(socket(), parameters)
end
function redis.error(message, level)
error(message, (level or 1) + 1)
end
function redis.connect(...)
local args, parameters = {...}, nil
if #args == 1 then
if type(args[1]) == 'table' then
parameters = args[1]
else
local uri = require('socket.url')
parameters = uri.parse(select(1, ...))
if parameters.scheme then
if parameters.query then
for k, v in parameters.query:gmatch('([-_%w]+)=([-_%w]+)') do
if k == 'tcp_nodelay' or k == 'tcp-nodelay' then
parameters.tcp_nodelay = parse_boolean(v)
end
end
end
else
parameters.host = parameters.path
end
end
elseif #args > 1 then
local host, port = unpack(args)
parameters = { host = host, port = port }
end
local commands = redis.commands or {}
if type(commands) ~= 'table' then
redis.error('invalid type for the commands table')
end
local socket = create_connection(merge_defaults(parameters))
local client = create_client(client_prototype, socket, commands)
return client
end
function redis.command(cmd, opts)
return command(cmd, opts)
end
function redis.define_command(name, opts)
define_command_impl(redis.commands, name, opts)
end
function redis.undefine_command(name)
undefine_command_impl(redis.commands, name)
end
redis.commands = {
exists   = command('EXISTS', {
response = toboolean
}),
del  = command('DEL'),
type = command('TYPE'),
rename   = command('RENAME'),
renamenx = command('RENAMENX', {
response = toboolean
}),
expire   = command('EXPIRE', {
response = toboolean
}),
pexpire  = command('PEXPIRE', { 
response = toboolean
}),
expireat = command('EXPIREAT', {
response = toboolean
}),
pexpireat= command('PEXPIREAT', {   
response = toboolean
}),
ttl  = command('TTL'),
pttl = command('PTTL'), 
move = command('MOVE', {
response = toboolean
}),
dbsize   = command('DBSIZE'),
persist  = command('PERSIST', { 
response = toboolean
}),
keys = command('KEYS', {
response = function(response)
if type(response) == 'string' then
local keys = {}
response:gsub('[^%s]+', function(key)
table.insert(keys, key)
end)
response = keys
end
return response
end
}),
randomkey= command('RANDOMKEY', {
response = function(response)
if response == '' then
return nil
else
return response
end
end
}),
sort = command('SORT', {
request = sort_request,
}),
set  = command('SET'),
setnx= command('SETNX', {
response = toboolean
}),
setex= command('SETEX'),
psetex   = command('PSETEX'),   
mset = command('MSET', {
request = mset_filter_args
}),
msetnx   = command('MSETNX', {
request  = mset_filter_args,
response = toboolean
}),
get  = command('GET'),
mget = command('MGET'),
getset   = command('GETSET'),
incr = command('INCR'),
incrby   = command('INCRBY'),
incrbyfloat  = command('INCRBYFLOAT', { 
response = function(reply, command, ...)
return tonumber(reply)
end,
}),
decr = command('DECR'),
decrby   = command('DECRBY'),
append   = command('APPEND'),   
substr   = command('SUBSTR'),   
strlen   = command('STRLEN'),   
setrange = command('SETRANGE'), 
getrange = command('GETRANGE'), 
setbit   = command('SETBIT'),   
getbit   = command('GETBIT'),   
rpush= command('RPUSH'),
lpush= command('LPUSH'),
llen = command('LLEN'),
lrange   = command('LRANGE'),
ltrim= command('LTRIM'),
lindex   = command('LINDEX'),
lset = command('LSET'),
lrem = command('LREM'),
lpop = command('LPOP'),
rpop = command('RPOP'),
rpoplpush= command('RPOPLPUSH'),
blpop= command('BLPOP'),
brpop= command('BRPOP'),
rpushx   = command('RPUSHX'),   
lpushx   = command('LPUSHX'),   
linsert  = command('LINSERT'),  
brpoplpush   = command('BRPOPLPUSH'),   
sadd = command('SADD'),
srem = command('SREM'),
spop = command('SPOP'),
smove= command('SMOVE', {
response = toboolean
}),
scard= command('SCARD'),
sismember= command('SISMEMBER', {
response = toboolean
}),
sinter   = command('SINTER'),
sinterstore  = command('SINTERSTORE'),
sunion   = command('SUNION'),
sunionstore  = command('SUNIONSTORE'),
sdiff= command('SDIFF'),
sdiffstore   = command('SDIFFSTORE'),
smembers = command('SMEMBERS'),
srandmember  = command('SRANDMEMBER'),
zadd = command('ZADD'),
zincrby  = command('ZINCRBY'),
zrem = command('ZREM'),
zrange   = command('ZRANGE', {
request  = zset_range_request,
response = zset_range_reply,
}),
zrevrange= command('ZREVRANGE', {
request  = zset_range_request,
response = zset_range_reply,
}),
zrangebyscore= command('ZRANGEBYSCORE', {
request  = zset_range_byscore_request,
response = zset_range_reply,
}),
zrevrangebyscore = command('ZREVRANGEBYSCORE', {
request  = zset_range_byscore_request,
response = zset_range_reply,
}),
zunionstore  = command('ZUNIONSTORE', { 
request = zset_store_request
}),
zinterstore  = command('ZINTERSTORE', { 
request = zset_store_request
}),
zcount   = command('ZCOUNT'),
zcard= command('ZCARD'),
zscore   = command('ZSCORE'),
zremrangebyscore = command('ZREMRANGEBYSCORE'),
zrank= command('ZRANK'),
zrevrank = command('ZREVRANK'), 
zremrangebyrank  = command('ZREMRANGEBYRANK'),  
hset = command('HSET', {
response = toboolean
}),
hsetnx   = command('HSETNX', {  
response = toboolean
}),
hmset= command('HMSET', {   
request  = hash_multi_request_builder(function(args, k, v)
table.insert(args, k)
table.insert(args, v)
end),
}),
hincrby  = command('HINCRBY'),  
hincrbyfloat = command('HINCRBYFLOAT', {
response = function(reply, command, ...)
return tonumber(reply)
end,
}),
hget = command('HGET'), 
hmget= command('HMGET', {   
request  = hash_multi_request_builder(function(args, k, v)
table.insert(args, v)
end),
}),
hdel = command('HDEL'),
hexists  = command('HEXISTS', { 
response = toboolean
}),
hlen = command('HLEN'), 
hkeys= command('HKEYS'),
hvals= command('HVALS'),
hgetall  = command('HGETALL', { 
response = function(reply, command, ...)
local new_reply = { }
for i = 1, #reply, 2 do new_reply[reply[i]] = reply[i + 1] end
return new_reply
end
}),
ping = command('PING', {
response = function(response) return response == 'PONG' end
}),
echo = command('ECHO'),
auth = command('AUTH'),
select   = command('SELECT'),
multi= command('MULTI'),
exec = command('EXEC'), 
discard  = command('DISCARD'),  
watch= command('WATCH'),
unwatch  = command('UNWATCH'),  
subscribe= command('SUBSCRIBE'),
unsubscribe  = command('UNSUBSCRIBE'),  
psubscribe   = command('PSUBSCRIBE'),   
punsubscribe = command('PUNSUBSCRIBE'), 
publish  = command('PUBLISH'),
eval = command('EVAL'),
evalsha  = command('EVALSHA'), 
script   = command('SCRIPT'), 
bgrewriteaof = command('BGREWRITEAOF'),
config   = command('CONFIG', {
response = function(reply, command, ...)
if (type(reply) == 'table') then
local new_reply = { }
for i = 1, #reply, 2 do new_reply[reply[i]] = reply[i + 1] end
return new_reply
end
return reply
end
}),
client   = command('CLIENT'),   
slaveof  = command('SLAVEOF'),
save = command('SAVE'),
bgsave   = command('BGSAVE'),
lastsave = command('LASTSAVE'),
flushdb  = command('FLUSHDB'),
flushall = command('FLUSHALL'),
monitor  = command('MONITOR'),
time = command('TIME'),
slowlog  = command('SLOWLOG', {
response = function(reply, command, ...)
if (type(reply) == 'table') then
local structured = { }
for index, entry in ipairs(reply) do
structured[index] = {
id = tonumber(entry[1]),
timestamp = tonumber(entry[2]),
duration = tonumber(entry[3]),
command = entry[4],
}
end
return structured
end
return reply
end
}),
info = command('INFO', {
response = parse_info,
}),
}
return redis
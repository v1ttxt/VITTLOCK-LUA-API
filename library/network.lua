---@meta
-- Network: protobuf, net_channel.send_net_message, gc (Game Coordinator), http and HttpRequestBuilder.

---A serialized protobuf message returned by `protobuf.encode` / `protobuf.encodeFromJSON`.
---The buffer stays allocated until you pass `binary` to `protobuf.free`.
---@class protobuf_binary
---@field size integer Number of bytes.
---@field binary lightuserdata Pointer to the bytes.

---Encode and decode the game's protobuf messages by message name.
---@class protobuf
protobuf = {}

---Builds a message from a Lua table (keys = proto field names) and serializes it.
---Raises "message type not found" for an unknown name, and "bad argument (field '<name>') to protobuf.encode" for a value of the wrong type.
---@param name string Message type name, for example "CMsgClientHello".
---@param tbl table Field values. Enums as name strings, repeated fields as arrays, sub-messages as tables.
---@return protobuf_binary result Free `result.binary` with `protobuf.free` when done.
function protobuf.encode(name, tbl) end

---Builds a message from a JSON string and serializes it. Invalid JSON is not reported (the message may be empty or partial).
---@param name string Message type name.
---@param json string JSON object (proto field names or lowerCamelCase names).
---@return protobuf_binary result Free `result.binary` with `protobuf.free` when done.
function protobuf.encodeFromJSON(name, json) end

---Parses serialized bytes as message `name` and returns it as JSON.
---Raises an error when `binary` is not a lightuserdata or `size` is not positive, or for an unknown name.
---@param name string Message type name.
---@param binary lightuserdata Pointer to the bytes (from `protobuf.encode` or a callback).
---@param size integer Number of bytes (> 0).
---@return string json
function protobuf.decodeToJSON(name, binary, size) end

---Parses base64-encoded bytes as message `name` and returns it as JSON.
---@param name string Message type name.
---@param base64 string Standard base64; decoding stops at '=' or the first invalid character.
---@return string json
function protobuf.decodeToJSONfromString(name, base64) end

---Returns a message object (the `msg` argument of the net message callbacks) as JSON.
---@param msg lightuserdata Message object.
---@return string json "<invalid protobuf object>" when `msg` is not a message object.
function protobuf.decodeToJSONfromObject(msg) end

---Frees a buffer returned in `protobuf_binary.binary`. Other values and pointers are ignored.
---@param binary lightuserdata
---@return boolean ok Always true.
function protobuf.free(binary) end

---Net channel helpers.
---@class net_channel
net_channel = {}

---Sends a network message to the game server. This is a real message: the server acts on it.
---Logs a warning and returns false when the name is unknown, the JSON does not parse or there is no connection.
---Called off the game thread, the message is queued for the next frame and true is returned.
---@param name string Network message type name, for example "CCitadelClientMsg_ExecuteMapPositionAbility".
---@param json string Message fields as a JSON object.
---@return boolean sent
function net_channel.send_net_message(name, json) end

---Game Coordinator messages.
---@class gc
gc = {}

---Returns the local Steam ID as a decimal string ("0" when Steam is not available).
---@return string steam_id
function gc.get_steam_id() end

---Returns the message type name registered for a GC message id with `gc.register_message`.
---@param id integer GC message id (the protobuf flag bit 0x80000000 is ignored).
---@return string name "" when the id is not registered.
function gc.get_message_name(id) end

---Registers the message type name for a GC message id (used by `get_message_name`, `decode` and `send_message`).
---@param name string Message type name.
---@param id integer GC message id (> 0).
---@return boolean ok False for an empty name or an id <= 0.
function gc.register_message(name, id) end

---Parses a GC message body as message `name` and returns it as JSON.
---Raises an error when `body` is not a lightuserdata or `size` is not positive, or for an unknown name.
---@param name string Message type name.
---@param body lightuserdata Pointer to the body bytes.
---@param size integer Number of bytes (> 0).
---@return string json
function gc.decode_message(name, body, size) end

---Parses a GC message body as the type registered for `id` and returns it as JSON.
---Raises an error when the id is not registered.
---@param id integer GC message id.
---@param body lightuserdata Pointer to the body bytes.
---@param size integer Number of bytes.
---@return string json
---@overload fun(id: integer, raw: string): string
---@overload fun(id: integer): string
function gc.decode(id, body, size) end

---Sets a singular field on a message object (for example the `msg` of `on_send_net_message`).
---@param msg lightuserdata Message object. Raw byte buffers are not message objects.
---@param field string Proto field name.
---@param value boolean|number|string Value of the field's type; enums as name strings.
---@return boolean ok False for a non-lightuserdata, unknown, repeated or sub-message field, or a value of the wrong type.
function gc.set_field(msg, field, value) end

---Sends a message to the Game Coordinator. This is a real message: the GC acts on it.
---@param id integer GC message id.
---@param body string|table Serialized body bytes, or a table of fields (needs `gc.register_message` for `id`).
---@return boolean ok True when the GC accepted the message.
function gc.send_message(id, body) end

---HTTP requests.
---@class http
http = {}

---Starts a request. Configure it with the builder's methods, then call `send` or `send_and_forget`.
---@param url string URL; "http://" is assumed when it has no scheme.
---@return HttpRequestBuilder builder
function http.request(url) end

---An HTTP request being built. Every setter returns the builder, so calls chain.
---@class HttpRequestBuilder
HttpRequestBuilder = {}

---Use the GET method (the default).
---@return HttpRequestBuilder self
function HttpRequestBuilder:get() end

---Use the POST method.
---@return HttpRequestBuilder self
function HttpRequestBuilder:post() end

---Sets a header. Names are case-insensitive; setting one again replaces its value.
---@param key string
---@param value string
---@return HttpRequestBuilder self
function HttpRequestBuilder:header(key, value) end

---Sets several headers from a table of string keys and string values (other entries are skipped).
---@param tbl table<string, string>
---@return HttpRequestBuilder self
function HttpRequestBuilder:headers(tbl) end

---Sets the `Authorization: Bearer <token>` header.
---@param token string
---@return HttpRequestBuilder self
function HttpRequestBuilder:bearer(token) end

---Sets the User-Agent header (a generic default is sent otherwise).
---@param ua string
---@return HttpRequestBuilder self
function HttpRequestBuilder:user_agent(ua) end

---Uses HTTP Basic authentication, unless an Authorization header is set.
---@param user string
---@param pass string
---@return HttpRequestBuilder self
function HttpRequestBuilder:basic_auth(user, pass) end

---Sets `Accept: application/json` (default Accept is `*/*`).
---@return HttpRequestBuilder self
function HttpRequestBuilder:accept_json() end

---Sets the body to the JSON encoding of `tbl` and `Content-Type: application/json`. Does not change the method.
---@param tbl table
---@return HttpRequestBuilder self
function HttpRequestBuilder:json(tbl) end

---Sets a URL-encoded form body from string keys and string values (other entries are skipped).
---@param tbl table<string, string>
---@return HttpRequestBuilder self
function HttpRequestBuilder:form(tbl) end

---Sets a raw body (binary-safe).
---@param raw string
---@return HttpRequestBuilder self
function HttpRequestBuilder:body(raw) end

---Sets query parameters (replacing an earlier `query` call). Values are strings or integers.
---@param tbl table<string, string|integer>
---@return HttpRequestBuilder self
function HttpRequestBuilder:query(tbl) end

---Limits the whole request to `seconds` (integer; default 10, 0 = no limit).
---@param seconds integer
---@return HttpRequestBuilder self
function HttpRequestBuilder:timeout(seconds) end

---Limits connecting to `seconds` (integer; default = the `timeout` value, 0 = no limit).
---@param seconds integer
---@return HttpRequestBuilder self
function HttpRequestBuilder:connect_timeout(seconds) end

---Pins the server's public key: "sha256//<base64>" entries separated by ';'. The request fails when none matches.
---@param pins string
---@return HttpRequestBuilder self
function HttpRequestBuilder:tls_pin(pins) end

---Turns the HTTPS certificate revocation check off (`true`) or on (`false`, the default).
---@param no_revoke boolean
---@return HttpRequestBuilder self
function HttpRequestBuilder:no_revoke(no_revoke) end

---Sets a value passed back as the callback's 4th argument.
---@param value any
---@return HttpRequestBuilder self
function HttpRequestBuilder:param(value) end

---Sends the request in the background. `callback` runs on a later frame with the reply.
---@param callback fun(status: integer, body: string, success: boolean, param: any)
function HttpRequestBuilder:send(callback) end

---Sends the request in the background and ignores the reply.
function HttpRequestBuilder:send_and_forget() end

---Handler for `callback.on_send_net_message`: return false to block the message.
---@alias on_send_net_message_fn fun(id: integer, msg: lightuserdata): boolean?

---Handler for `callback.on_received_net_message` (delivered on the next frame; the return value is ignored).
---@alias on_received_net_message_fn fun(id: integer, msg: lightuserdata)

---Handler for `callback.on_send_gc_message`: return false to block the message.
---@alias on_send_gc_message_fn fun(id: integer, body: lightuserdata, size: integer): boolean?

---Handler for `callback.on_receive_gc_message` (the return value is ignored).
---@alias on_receive_gc_message_fn fun(id: integer, body: lightuserdata, size: integer)

# Network

This page covers four tables and four callbacks for game network traffic and the web:

- `protobuf`: encode and decode the game's protobuf messages by name, as Lua tables or JSON.
- `net_channel.send_net_message` and the `on_send_net_message` / `on_received_net_message` callbacks: watch, block and send network messages between the client and the game server.
- `gc` and the `on_send_gc_message` / `on_receive_gc_message` callbacks: watch, decode, block and send Game Coordinator (GC) messages.
- `http`: background HTTP(S) requests with a chainable `HttpRequestBuilder`.

> **Warning.** `net_channel.send_net_message` and `gc.send_message` send **real** messages to the game server and the Game Coordinator, which act on them as if the game had sent them. Blocking messages in the send callbacks also changes what the server sees. A malformed or unexpected message can break your match or get you disconnected.

## Message names and JSON

Each function takes a protobuf **message type name** exactly as the game declares it (case-sensitive), for example `CCitadelUserMsg_AbilitiesChanged` or `CMsgClientHello`. If the type is declared in a package, include the package. Any message type the game client defines can be used. An unknown name raises `message type not found`.

All decode functions return the same JSON format:

- compact (no whitespace);
- field names as written in the `.proto` (snake_case, for example `ability_id`);
- singular fields that are not set are printed with their default value; repeated fields that are not set print as `[]`; sub-messages that are not set are left out;
- enums print as their value names (`"EPurchased"`);
- 64-bit integers print as quoted strings; `bytes` fields print as base64.

Decode the result with `utils.json_decode` (see [core](core.md)) when you need a Lua table.

## protobuf

### `protobuf.encode(name, tbl)`
Builds message `name` from a Lua table and serializes it.

| Name | Type | Description |
|---|---|---|
| `name` | `string` | Message type name. |
| `tbl` | `table` | Field values, keyed by proto field name. |

Table values:

| Field type | Lua value |
|---|---|
| integer types | number (pass integers: a non-integral float becomes 0) |
| `float`, `double` | number |
| `bool` | boolean |
| `string`, `bytes` | string (raw bytes for `bytes`) |
| enum | the value **name** as a string; numbers are rejected |
| sub-message | table, filled the same way |
| repeated | array table `{ v1, v2, ... }` of the element type |

Keys that are not fields of the message are ignored. A value of the wrong type raises `bad argument (field '<field>') to protobuf.encode`.

Returns a table `{ size = integer, binary = lightuserdata }`. `binary` points at the serialized bytes and stays allocated until you call `protobuf.free(result.binary)`. An empty message gives `size == 0`.

```lua
local r = protobuf.encode("CMsgClientHello", { version = 1234 })
print(r.size, protobuf.decodeToJSON("CMsgClientHello", r.binary, r.size))
protobuf.free(r.binary)
```

### `protobuf.encodeFromJSON(name, json)`
Same as `encode`, but the fields come from a JSON object string. Proto field names and lowerCamelCase names are both accepted. Invalid JSON or unknown fields are **not** reported: the result may be empty or partial. Returns `{ size, binary }`. Free it with `protobuf.free`.

### `protobuf.decodeToJSON(name, binary, size)`
Parses `size` bytes at `binary` as message `name` and returns the JSON.

| Name | Type | Description |
|---|---|---|
| `name` | `string` | Message type name. |
| `binary` | `lightuserdata` | Pointer to the bytes, for example `encode(...).binary` or a GC callback's `body`. |
| `size` | `integer` | Byte count; must be greater than 0. |

Raises `decodeToJSON: lightuserdata + positive size required` for any other `binary` or for `size <= 0`. If the bytes do not parse, no error is raised: you get the JSON of whatever was read.

### `protobuf.decodeToJSONfromString(name, base64)`
Base64-decodes `base64` (standard alphabet; decoding stops at the first `=` or invalid character), parses the bytes as `name` and returns the JSON.

### `protobuf.decodeToJSONfromObject(msg)`
Returns a message **object** as JSON. Use it on the `msg` argument of `on_send_net_message` / `on_received_net_message`. Anything that is not a message object returns the string `"<invalid protobuf object>"` (not `nil`, no error). GC callback bodies are raw bytes, not objects: decode those with `gc.decode_message` or `protobuf.decodeToJSON`.

### `protobuf.free(binary)`
Frees a buffer returned by `encode` / `encodeFromJSON`. Other values, unknown pointers and already-freed buffers are ignored. Always returns `true`.

## net_channel.send_net_message

### `net_channel.send_net_message(name, json)`
Builds the network message `name` from `json` and sends it to the game server. See [core](core.md) for the rest of `net_channel`.

| Name | Type | Description |
|---|---|---|
| `name` | `string` | Network message type name, for example `"CCitadelClientMsg_ExecuteMapPositionAbility"`. Matched case-insensitively, and a part of a name matches too, so use the full name. |
| `json` | `string` | The message fields as a JSON object. Unknown fields make the parse fail. |

Returns `true` when the message was sent. On failure it writes a warning to the script log and returns `false`: unknown name, JSON that does not parse, or no connection to a server.

Notes:
- Messages you send this way do **not** pass through `on_send_net_message`.
- Called off the game thread (for example from `on_draw`), the message is queued and sent on the next frame, and the function returns `true` without knowing the result.
- Build the JSON with `utils.json_encode` so numbers and strings are encoded correctly. Integer fields need integral numbers.

```lua
-- Real message: the server will act on it.
-- idx = the ability's entity index, pos = a Vector on the map.
local function cast_at(idx, pos)
    return net_channel.send_net_message("CCitadelClientMsg_ExecuteMapPositionAbility",
        utils.json_encode({ ability_entity_index = idx, pos_x = pos.x, pos_y = pos.y, pos_z = pos.z }))
end
```

## Net message callbacks

Register them like every callback: `callback.on_send_net_message:set(fn)` (see [callbacks](callbacks.md)).

`id` is the game's network message id (for example `309` for `CCitadelUserMsg_AbilitiesChanged`). `msg` is a lightuserdata **message object**. Read it with `protobuf.decodeToJSONfromObject(msg)`. It is valid only during the call, so don't keep it.

### `on_send_net_message(id, msg)`
Runs for each network message the client sends on the game thread, before it goes out. That includes the movement message sent every command, so keep the handler cheap and check `id` first.

- Return `false` to **block** the message: it is not sent. If any handler returns `false`, the message is blocked. Returning `nil` or `true` lets it through.
- `gc.set_field(msg, field, value)` can change a singular field of the message before it is sent.
- Messages sent from other threads, and messages sent with `net_channel.send_net_message`, are not reported.

### `on_received_net_message(id, msg)`
Runs for each network message the client receives. Messages are copied and delivered at the start of the **next frame** (before `on_frame`), in arrival order. They cannot be blocked: the return value is ignored, and the original message has already been passed on to the game.

- Not delivered: `net_Tick` (4), `clc_Move` (21), `svc_PacketEntities` (55).
- If more than 4096 messages are waiting, the oldest are dropped.

```lua
callback.on_received_net_message:set(function(id, msg)
    if id ~= 309 then return end          -- CCitadelUserMsg_AbilitiesChanged
    local t = utils.json_decode(protobuf.decodeToJSONfromObject(msg))
    if t and t.change == "EPurchased" then
        print(("slot %d bought ability %d"):format(t.purchaser_player_slot, t.ability_id))
    end
end)
```

## gc

GC messages are identified by a numeric message id. The id-to-name table starts **empty**: register the ids you use with `gc.register_message` before calling `get_message_name`, `decode`, or `send_message` with a table.

### `gc.get_steam_id()`
Returns the local Steam ID as a 64-bit decimal string, for example `"7656119..."`, or `"0"` when Steam is not available.

### `gc.register_message(name, id)`
Registers message type `name` for GC message id `id`. Registering the same id again replaces the name. Returns `false` (and registers nothing) for an empty name or an `id <= 0`.

### `gc.get_message_name(id)`
Returns the name registered for `id`, or `""`. The protobuf flag bit `0x80000000` in `id` is ignored.

### `gc.decode_message(name, body, size)`
Parses `size` bytes at `body` as message `name` and returns the JSON. Same as `protobuf.decodeToJSON`. Raises an error when `body` is not a lightuserdata or `size <= 0`, or for an unknown name.

### `gc.decode(id, body, size)` / `gc.decode(id, raw)` / `gc.decode(id)`
Decodes using the name registered for `id`. Accepts a pointer and size (as from a GC callback), a Lua string of raw bytes, or nothing, which gives the JSON of an empty message with every default value. Raises `message id not registered (gc.register_message)` when `id` is unknown.

### `gc.set_field(msg, field, value)`
Sets one singular field on a message **object**, for example the `msg` of `on_send_net_message`.

| Name | Type | Description |
|---|---|---|
| `msg` | `lightuserdata` | Message object. Don't pass raw byte buffers (GC callback bodies, `encode` results). |
| `field` | `string` | Proto field name. |
| `value` | `boolean\|number\|string` | A value of the field's type; enums by value name. |

Returns `true` when the field was set. Returns `false` when `msg` is not a lightuserdata, the field does not exist, the field is repeated or a sub-message, or `value` has the wrong type.

### `gc.send_message(id, body)`
Sends a message to the Game Coordinator.

| Name | Type | Description |
|---|---|---|
| `id` | `integer` | GC message id. |
| `body` | `string\|table` | The serialized message body as a string, or a table of fields. A table needs `gc.register_message` for `id`; it is converted through JSON, so use proto field names and enum value names. |

Returns `true` when the GC accepted the message. Returns `false` when Steam's GC interface is not available, the id is not registered (table body), the fields don't fit the message, or `body` is any other type. Most failures write a warning to the script log.

Messages sent this way also pass through `on_send_gc_message`.

## GC callbacks

Both receive `(id, body, size)`. `id` is the GC message id without the protobuf flag. `body` is a lightuserdata pointing at the message body (headers removed). `size` is its byte count, which can be 0. The pointer is valid only during the call. Decode it with `gc.decode_message(name, body, size)` or `gc.decode(id, body, size)`, and check `size > 0` first. Only messages handled on the game thread are reported.

### `on_send_gc_message(id, body, size)`
Runs before the client sends a GC message. Return `false` to **block** it (any handler returning `false` blocks it).

### `on_receive_gc_message(id, body, size)`
Runs when the client takes a GC message from Steam. The return value is ignored.

```lua
gc.register_message("CMsgClientWelcome", 4004)

callback.on_receive_gc_message:set(function(id, body, size)
    local name = gc.get_message_name(id)
    if name ~= "" and size > 0 then
        print(name .. ": " .. gc.decode_message(name, body, size):sub(1, 200))
    end
end)
```

## http

### `http.request(url)`
Returns a new `HttpRequestBuilder` for `url`. A URL without a scheme gets `http://`. A `#fragment` is not sent. Configure the request with the methods below, then call `send` or `send_and_forget`.

```lua
http.request("https://example.com/api/stats")
    :query({ hero = "haze", limit = 10 })
    :accept_json()
    :timeout(5)
    :send(function(status, body, success)
        if not success then
            print("request failed: " .. status)
            return
        end
        local data = utils.json_decode(body)
        print(data and data.name)
    end)
```

## HttpRequestBuilder

Every setter returns the builder, so calls chain. Call them with `:` (a `.` call raises `HttpRequestBuilder expected`). The builder is not used up by `send`: you can send it again.

### Method

| Method | Description |
|---|---|
| `b:get()` | Use GET (the default). |
| `b:post()` | Use POST. |

Only GET and POST are available.

### Headers

| Method | Description |
|---|---|
| `b:header(key, value)` | Sets a header. Names are case-insensitive; setting a name again replaces its value. |
| `b:headers(tbl)` | Sets every string-key / string-value pair of `tbl` (other entries are skipped). |
| `b:bearer(token)` | Sets `Authorization: Bearer <token>`. |
| `b:basic_auth(user, pass)` | Sends HTTP Basic credentials, unless an `Authorization` header is set (for example by `bearer`). |
| `b:user_agent(ua)` | Sets the User-Agent header. A generic default is sent when you don't set one. |
| `b:accept_json()` | Sets `Accept: application/json`. The default is `Accept: */*`. |

### Body
`json`, `form` and `body` each replace the body set before.

| Method | Description |
|---|---|
| `b:json(tbl)` | Body = `tbl` encoded like `utils.json_encode` (compact, keys sorted). Also sets `Content-Type: application/json`. It does **not** switch to POST: call `:post()` too. |
| `b:form(tbl)` | Body = URL-encoded form of the string-key / string-value pairs of `tbl` (keys and values escaped; other entries, numbers included, are skipped). |
| `b:body(raw)` | Body = `raw` as is (binary-safe). |

A body sent without a `Content-Type` header gets `application/x-www-form-urlencoded`. The `Content-Type` that `json` sets stays when you replace the body with `form` or `body` later, so set the header yourself in that case.

### `b:query(tbl)`
Sets the query parameters, replacing an earlier `query` call. They are added to the URL with `?`, or with `&` when the URL already has a query. Keys must be strings. Values can be strings or **integers**: a non-integral number raises an error. Any other value, or an empty string, sends the key alone (`?flag`). Keys and values are escaped. The parameter order is not defined.

### Timeouts

| Method | Description |
|---|---|
| `b:timeout(seconds)` | Limit for the whole request, in whole seconds. Default 10. `0` = no limit. |
| `b:connect_timeout(seconds)` | Limit for connecting, in whole seconds. Default = the `timeout` value. `0` = no limit. |

Both take **integers only**: `timeout(1.5)` and even `timeout(2.0)` raise an error. Write `timeout(2)`. When the limit is hit, the request fails (see `send`).

### TLS

#### `b:tls_pin(pins)`
Pins the server's public key. `pins` is one or more `sha256//<base64>` entries separated by `;`, where `<base64>` is the base64 SHA-256 hash of the server certificate's public key (its DER-encoded SubjectPublicKeyInfo). The key is checked after the TLS handshake and before any request data is sent. If no pin matches, the request fails with `(0, "", false)`. Pins in any other format make the request fail, and a warning is written to the script log once.

#### `b:no_revoke(no_revoke)`
`true` turns the HTTPS certificate revocation check off. It is on by default.

### Redirects
Redirects are followed automatically, up to 50, including from HTTPS to HTTP. The callback gets the final response.

### `b:param(value)`
Stores any Lua value. It is passed back as the 4th argument of the `send` callback. Useful when one function handles several requests.

### `b:send(callback)`
Sends the request in the background and returns at once. On a later frame, `callback(status, body, success, param)` runs on the game thread, before `on_frame`:

| Argument | Type | Description |
|---|---|---|
| `status` | `integer` | HTTP status code; `0` when no response arrived (connection error, timeout, pin mismatch). |
| `body` | `string` | Response body (`""` when no response arrived). |
| `success` | `boolean` | `true` only when the request completed **and** the status is 2xx. |
| `param` | `any` | The value set with `param`, or `nil`. |

Notes:
- A 404 or 500 is not a transport failure: you get the real `status` and `body` with `success == false`.
- Response headers are not available.
- If the script that sent the request is reloaded or disabled before the reply arrives, the callback is not called. All pending callbacks are dropped when scripts reload.
- Errors inside the callback go to the script's log.
- Passing something that is not a function works like `send_and_forget`.

```lua
local token = "my-api-token"
http.request("https://example.com/api/report")
    :post()
    :json({ steam_id = gc.get_steam_id(), kills = 3 })
    :bearer(token)
    :param("report")
    :send(function(status, body, success, tag)
        print(tag, status, success)
    end)
```

### `b:send_and_forget()`
Sends the request in the background and ignores the reply.

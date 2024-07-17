%dw 2.0
output application/json
input payload application/json

import * from dw::core::Types

fun flattenObject(obj: Object, prefix) = (
    obj mapObject ((value, key, index) -> (
        if (isObjectType(typeOf(value))) flattenObject(value, prefix ++ "." ++ key)
        else (prefix ++ "." ++ key): value
    ))
)

---

payload map ((item, index) -> (
    item mapObject ((value, key, index) -> (
    if (isObjectType(typeOf(value))) flattenObject(value, key)
    else (key): value
))))
%dw 2.0
input mapping application/json
input payload application/json
output application/json

---
payload map (record) -> (
    record mapObject (value, key, index) -> (
        if (mapping[key] != null) ((mapping[key]): value)
        else ((key): value)
    )
)
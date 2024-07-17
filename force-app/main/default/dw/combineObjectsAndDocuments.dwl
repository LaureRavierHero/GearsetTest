%dw 2.0
input documents application/json
input objects application/json
output application/json

---

objects map ((item, index) -> (
    if ((documents[item.Id]) != null) 
    item ++ (documents[item.Id])
    else item
))
%dw 2.0
input payload applicaton/json
input mapping application/json
output application/json

import * from dw::util::Values

fun upsert(object: {}, path:Array<String>, value: Any): Object = do {
    path match {
        case [] -> object
        case [x ~ xs] -> 
                if(isEmpty(xs))
                    object update  {
                        case ."$(x)"! -> value                                
                    }
                else
                    object update  {
                        case selected at ."$(x)"! -> 
                            //selected is going to be null when the value is not present  
                            upsert(selected default {}, mapping[xs], value)
                    }  
    }
}

fun upsertObject(object: {}): Object = do {
    object
    pluck ((value, key, index) -> {key: key, value: value})
        reduce ((item, resultObject = {} ) -> do {
            upsert(resultObject, (item.key as String splitBy '.') , item.value)
    })
}
---

payload reduce ((item, accumulator = []) -> (
    accumulator + upsertObject(item)
))
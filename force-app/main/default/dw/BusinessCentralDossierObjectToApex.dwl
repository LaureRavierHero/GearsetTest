%dw 2.0
input fileUrl text/plain
input userName text/plain
output application/json

var status = 'Review'
---
{
    TaskStatus: status,
    ResultFileUrl: fileUrl,
    Comment: 'Submitted by ' ++ userName as String,
}
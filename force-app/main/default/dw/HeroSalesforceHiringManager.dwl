%dw 2.0
output application/json
input placement application/json
input additionalInfo application/json
---
{
    FirstName: placement.Application__r.Position__r.Hiring_manager__r.FirstName,
    LastName: placement.Application__r.Position__r.Hiring_manager__r.LastName,
    AccountId: additionalInfo.accountId,
    recordTypeId: additionalInfo.recordTypeId
}
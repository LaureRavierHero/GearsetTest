%dw 2.0
output application/json
input placement application/json

var professional = placement.Professional__r
---
{
  cxsrec__First_name__c: professional.FirstName,
  cxsrec__Last_name__c: professional.LastName,
  cxsrec__E_mail_address__c: professional.Email,
  cxsrec__mobilePhone__c: professional.Phone
}

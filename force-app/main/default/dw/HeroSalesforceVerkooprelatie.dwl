%dw 2.0
output application/json
input placement application/json

var account = placement.Account__r
---

{
  Name: account.Name,
  Naam_Entiteit__c: account.Entity_name__c,
  KVK_nummer__c: account.Chamber_of_commerce_number__c,
  BTW_nummer__c: account.VAT_number__c
}

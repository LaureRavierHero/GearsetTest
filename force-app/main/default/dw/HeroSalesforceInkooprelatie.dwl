%dw 2.0
output application/json
input placement application/json

var leverancierstype = 'Onderneming'
---
{ 
    Name: placement.Vendor__r.Name,
    BTW_nummer__c: placement.Vendor__r.VAT_number__c,
    KvK_nummer__c: placement.Vendor__r.Chamber_of_commerce_number__c,
    Adres__Street__s: placement.Vendor__r.Address__Street__s,
    Adres__PostalCode__s: placement.Vendor__r.Address__PostalCode__s,
    Adres__City__s: placement.Vendor__r.Address__City__s,
    Adres__CountryCode__s: placement.Vendor__r.Address__CountryCode__s,
    Naam_Entiteit__c: placement.Vendor__r.Entity_name__c,
    Leverancierstype__c: leverancierstype
}

%dw 2.0
output application/json
input placement application/json
input contacts application/json
input relationIdByType application/json

var vestiging = "Alkmaar"
var urenVia = "Hero Urenstaat"
var travelExpenses = if (placement.Travel_expenses__c) "Ja" else "Nee"
---
{
  cxsrec__Start_date__c: placement.Start_date__c,
  Initiele_einddatum__c: placement.Initial_end_date__c,
  Verwachte_einddatum__c: placement.Expected_end_date__c,
  cxsrec__Current_rate__c: placement.Current_rate__c,
  HERO_Hours_per_week_placement__c: placement.Hours_per_week__c,
  Werkzaamheden_deskundige__c: placement.Professional_responsibilities__c,
  Vestiging__c: vestiging,
  Urenregistratie_via__c: urenVia,
  Reiskosten__c: travelExpenses,
  Reiskosten_bedrag__c: placement.Travel_expenses_amount__c,
  Kostenplaats__c: placement.Cost_center__c,
  Grootboekrekening__c: placement.General_ledger_account__c,
  VMS_Placement_Id__c: placement.Id,
  cxsrec__Candidate__c: relationIdByType.Professional__c,
  Verkooprelatie__c: relationIdByType.Verkoop_relatie__c,
  Inkooprelatie__c: relationIdByType.Vendor__c,
  Inhurende_manager__c: contacts.hiringManager
}

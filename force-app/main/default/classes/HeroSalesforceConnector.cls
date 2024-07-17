public without sharing class HeroSalesforceConnector{
	public static Placement__c placement = new Placement__c();
	public static Map<String, String> contactMap = new Map<String, String>();
	public static List<SObject> objectsToUpdate = new List<SObject>();
	public static Map<String, String> relationIdByType;
	
	@AuraEnabled
	public static void executeCreate(String recordId){

		// try {
			placement = getPlacement(recordId);
			
			// Get/Post relationships
			relationIdByType = getRelations(placement);

			// Get/Post contacts
			contactMap = getContacts();

			// Placement updaten
			if(!String.isBlank(relationIdByType.get('Account__c'))
			&& !String.isBlank(relationIdByType.get('Professional__c'))
			&& !String.isBlank(relationIdByType.get('Verkoop_relatie__c'))
			&& !String.isBlank(relationIdByType.get('Vendor__c'))
			&& contactMap.get('hiringManager') != null
			){
				postPlacement();
			}

			update objectsToUpdate;
		// }
		// catch (Exception e) {
			update objectsToUpdate;

		// 	throw new AuraHandledException(e.getMessage());
		// }
	}

	// Relations
	public static Map<String, String> getRelations(Placement__c p){
		Map<String, String> rm = new Map<String, String>();
		rm.put('Account__c', placement?.Account__r?.Contracts_Id__c);
		rm.put('Verkoop_relatie__c', placement?.Account__r?.Contracts_Id_verkoop_relatie__c ?? postVerkooprelatieFromAccount());
		rm.put('Vendor__c', placement?.Vendor__r?.Contracts_Id__c ?? postInkooprelatieFromVendor());
		rm.put('Professional__c', placement?.Professional__r?.Contracts_Id__c ?? postProfessional());

		return rm;
	}

	// Account/verkooprelatie
	public static String postVerkooprelatieFromAccount(){
		// Map<String, Object> am = new Map<String, Object>();
		// am.put('Name', placement?.Account__r?.Name);
		// am.put('Naam_Entiteit__c', placement?.Account__r?.Entity_name__c);
		// am.put('KVK_nummer__c', placement?.Account__r?.Chamber_of_commerce_number__c);
		// am.put('BTW_nummer__c', placement?.Account__r?.VAT_number__c);
		DataWeave.Script script = new DataWeaveScriptResource.HeroSalesforceVerkooprelatie();
        DataWeave.Result result = script.execute(new Map<String, Object>{'placement' => JSON.serialize(placement)});

		return post('Verkooprelatie__c', result.getValueAsString(), 'Account', placement.Account__c);
	}

	// Vendor/inkooprelatie
	public static String postInkooprelatieFromVendor(){
		// Map<String, Object> vm = new Map<String, Object>();
		// vm.put('Name', placement?.Vendor__r?.Name);
		// vm.put('BTW_nummer__c', placement?.Vendor__r?.VAT_number__c);
		// vm.put('KvK_nummer__c', placement?.Vendor__r?.Chamber_of_commerce_number__c);
		// vm.put('Adres__Street__s', placement?.Vendor__r?.Address__Street__s);
		// vm.put('Adres__PostalCode__s', placement?.Vendor__r?.Address__PostalCode__s);
		// vm.put('Adres__City__s', placement?.Vendor__r?.Address__City__s);
		// vm.put('Adres__CountryCode__s', placement?.Vendor__r?.Address__CountryCode__s);
		// vm.put('Naam_Entiteit__c', placement?.Vendor__r?.Entity_name__c);
		// vm.put('Leverancierstype__c', 'Onderneming'); // For now, we only have this type and no field on vendors specifying types
		DataWeave.Script script = new DataWeaveScriptResource.HeroSalesforceInkooprelatie();
        DataWeave.Result result = script.execute(new Map<String, Object>{'placement' => JSON.serialize(placement)});

		return post('Inkooprelatie__c', result.getValueAsString(), 'Account', placement?.Vendor__c);
	}

	// Professional/Candidate
	public static String postProfessional(){
		Map<String, Object> pm = new Map<String, Object>();
		// pm.put('cxsrec__First_name__c', placement?.Professional__r?.FirstName);
		// pm.put('cxsrec__Last_name__c', placement?.Professional__r?.LastName);
		// pm.put('cxsrec__E_mail_address__c', placement?.Professional__r?.Email);
		// pm.put('cxsrec__mobilePhone__c', placement?.Professional__r?.Phone);

		DataWeave.Script script = new DataWeaveScriptResource.HeroSalesforceProfessional();
        DataWeave.Result result = script.execute(new Map<String, Object>{'placement' => JSON.serialize(placement)});

		return post('cxsrec__cxsCandidate__c', result.getValueAsString(), 'Contact', placement?.Professional__c);
	}

	// Contacts
	public static Map<String, String> getContacts(){
		// Fill accountIds with vendor id from metadata
		// And account id with the id from the relationshipMap
		// accountIds = getAccountIds();

		Map<String, String> cm = new Map<String, String>();
		if (String.isNotBlank(placement?.Application__r?.Position__r?.Hiring_manager__r?.Contracts_Id__c)) {
			cm.put('hiringManager', placement?.Application__r?.Position__r?.Hiring_manager__r?.Contracts_Id__c);
		}
		else {
			cm.put('hiringManager', postHiringManager());
		}
		// cm.put('hiringManager', placement?.Application__r?.Position__r?.Hiring_manager__r?.Contracts_Id__c ?? 
		// 	postHiringManager(
		// 		placement?.Application__r?.Position__r?.Hiring_manager__c,
		// 		placement?.Application__r?.Position__r?.Hiring_manager__r?.FirstName, 
		// 		placement?.Application__r?.Position__r?.Hiring_manager__r?.LastName, 
		// 		relationIdByType.get('Account__c')));


		// TODO Elk contact aan de inkoop kant valt onder het account Contracts bij Hero Salesforce
		// TODO En dan bij het contact het veld Inkooprelatie__c vullen met het id van de inkooprelatie
		// Goedkeurder contract inhuur (Voornaam, tussenvoegsel, achternaam, initialen, Emailadress, telefoonnummer)
		// Tekenbevoegde inhuur (Voornaam, tussenvoegsel, achternaam, initialen, Emailadress, telefoonnummer)

		return cm;
	}

	// Dwight Schrute. Is. MANAGEEEEEEEEER!
	public static String postHiringManager(){
		// Map<String, Object> cm = new Map<String, Object>();
		// cm.put('FirstName', firstName);
		// cm.put('LastName', lastName);
		// cm.put('AccountId', accId);
		// cm.put('recordTypeId', getRecordTypeId('Contact', 'Recruitment'));

		Map<String, Object> additionalInfo = new Map<String, Object>();

		additionalInfo.put('accountId', relationIdByType.get('Account__c'));
		additionalInfo.put('recordTypeId', getRecordTypeId('Contact', 'Recruitment'));

		DataWeave.Script script = new DataWeaveScriptResource.HeroSalesforceHiringManager();
        DataWeave.Result result = script.execute(new Map<String, Object>
		{'placement' => JSON.serialize(placement), 'additionalInfo' => JSON.serialize(additionalInfo)});

		System.debug('PR');
		return post('Contact', result.getValueAsString(), 'Contact', placement.Application__r.Position__r.Hiring_manager__c);
	}

	// Placement
	public static String postPlacement(){
		// Map<String, Object> pm = new Map<String, Object>();
		// pm.put('cxsrec__Start_date__c', placement.Start_date__c);
		// pm.put('Initiele_einddatum__c', placement.Initial_end_date__c);
		// pm.put('Verwachte_einddatum__c', placement.Expected_end_date__c);
		// pm.put('cxsrec__Current_rate__c', placement.Current_rate__c);
		// pm.put('HERO_Hours_per_week_placement__c', placement.Hours_per_week__c);
		// pm.put('Werkzaamheden_deskundige__c', placement.Professional_responsibilities__c ?? '');
		// pm.put('Vestiging__c', 'Alkmaar');
		// pm.put('Urenregistratie_via__c', 'Hero Urenstaat');
		// pm.put('Reiskosten__c', placement.Travel_expenses__c == true ? 'Ja' : 'Nee');
		// pm.put('Reiskosten_bedrag__c', placement.Travel_expenses_amount__c);
		// pm.put('Kostenplaats__c', placement.Cost_center__c);
		// pm.put('Grootboekrekening__c', placement.General_ledger_account__c);
		// pm.put('VMS_Placement_Id__c', placement.Id);
		// pm.put('cxsrec__Candidate__c', relationIdByType.get('Professional__c'));
		// pm.put('Verkooprelatie__c', relationIdByType.get('Verkoop_relatie__c'));
		// pm.put('Inkooprelatie__c', relationIdByType.get('Vendor__c'));

		// pm.put('Inhurende_manager__c', contactMap.get('hiringManager'));

		DataWeave.Script script = new DataWeaveScriptResource.HeroSalesforcePlacement();
        DataWeave.Result result = script.execute(new Map<String, Object>{'placement' => JSON.serialize(placement), 
		'contacts' => JSON.serialize(contactMap), 'relationIdByType' => JSON.serialize(relationIdByType) });

		return post('cxsrec__Placement__c', result.getValueAsString(), 'Placement__c', placement.Id);
	}

	public static String getRecordTypeId(String objectName, String developerTypeName) {
		String endpoint = objectName + '/describe';

		Http http = new Http();
		HttpRequest request = new HttpRequest();
		HttpResponse response = new HttpResponse();

		request.setEndpoint('callout:ContractsSalesforce/' + 'services/data/v60.0/sobjects/' + endpoint);
        request.setMethod('GET');
		request.setHeader('Accept', 'application/json');

		response = http.send(request);

		Map<String, Object> res = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
		List<Object> recordTypeInfos = (List<Object>)res.get('recordTypeInfos');

		if (recordTypeInfos != null) {
			for (Object o: recordTypeInfos) {
				Map<String, Object> recordTypeInfo = (Map<String, Object>)o;
				if ((String)recordTypeInfo.get('developerName') == developerTypeName) {
					return (String)recordTypeInfo.get('recordTypeId');
				}
			}
		}
		return '';
	}

	public static String post(
		String endpoint, 	// Endpoint to post to
		String body, 		// JSON Body to send with
		String objectType, 	// Object in VMS to update once succes has been returned
		Id objectId 		// Id of object in VMS to put in objectType so that the system knows which object to update
	){
		Http http = new Http();
		HttpRequest request = new HttpRequest();
		HttpResponse response = new HttpResponse();
	
		request.setEndpoint('callout:ContractsSalesforce/' + 'services/data/v60.0/sobjects/' + endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
		request.setHeader('Accept', 'application/json');
		request.setBody(body);

		System.debug('POST type: ' + objectType);
		System.debug(body);
		try {
			response = http.send(request);

			if(response.getStatusCode() == 201 && response.getStatus() == 'Created') {
				PostResponse postResponseBody = (PostResponse) JSON.deserialize(String.valueOf(response.getBody()), PostResponse.class);

				SObject obj = Schema.getGlobalDescribe().get(objectType).newSObject();

				obj.put('Id', objectId);

				if (objectType == 'Verkoop_relatie__c') {
					// Verkooprelatie is in het VMS Vendor account
					Account a = new Account();
					a.Id = placement.Vendor__c;
					a.Contracts_Id_verkoop_relatie__c = postResponseBody.id;
					obj = (SObject)a;
				}
				else {
					obj.put('Contracts_Id__c', postResponseBody.id);
				}
				objectsToUpdate.add(obj);

				return postResponseBody.id;
			} else {
				System.debug(response.getBody());
				throw new HeroSalesforceConnectorException(response.getBody());
			}
		} catch (Exception e) {
			throw e;
		}
	}

	public static Placement__c getPlacement(String recordId){
		String queryString = 'SELECT '
				+ 'Professional__c, Professional__r.Contracts_Id__c, Professional__r.FirstName, Professional__r.LastName, Professional__r.Email, Professional__r.Phone,'
				+ 'Vendor__c, Vendor__r.Name, Vendor__r.Chamber_of_commerce_number__c, Application__r.Position__r.Hiring_manager__r.Contracts_Id__c, Application__r.Position__r.Hiring_manager__r.LastName,'
				+ 'Application__r.Position__r.Hiring_manager__r.FirstName, Vendor__r.Address__Street__s, Vendor__r.Address__PostalCode__s, Vendor__r.Address__City__s, Vendor__r.Address__CountryCode__s, '
				+ 'Vendor__r.Entity_name__c, Vendor__r.Contracts_Id__c, Vendor__r.VAT_number__c, Application__r.Position__r.Hiring_manager__c, '
				+ 'Account__c, Account__r.Name, Account__r.Entity_name__c, Account__r.Chamber_of_commerce_number__c, Account__r.VAT_number__c, Account__r.Contracts_Id__c,'
				+ 'Application__r.Position__r.Name, Application__r.Position__r.Additional_benefits__c, Account__r.Contracts_Id_verkoop_relatie__c,'
				+ 'Start_date__c, Initial_end_date__c, Expected_end_date__c, Current_rate__c, Hours_per_week__c, Professional_responsibilities__c, Travel_expenses__c, Travel_expenses_amount__c,'
				+ 'Cost_center__c, General_ledger_account__c, Contracts_Id__c'
			+ ' FROM '
				+ 'Placement__c'
			+ ' WHERE '
				+ 'Id = :recordId'
			+ ' LIMIT 1';

		Placement__c placement;

		placement = Database.query(queryString);

		return placement;
	}

	public class PostResponse{
		public String id;
		public String success;
		public List<String> errors;
	}

	public class HeroSalesforceConnectorException extends Exception {}
}
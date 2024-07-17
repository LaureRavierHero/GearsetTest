@istest
global class HeroSalesforceConnectionMock implements HttpCalloutMock {
	global HTTPResponse respond(HTTPRequest req) {
		HttpResponse res = new HttpResponse();
		res.setBody('');

		String endpoint = req.getEndpoint();

        System.debug('endpoint');
        System.debug(endpoint);

		res.setStatusCode(201);
		res.setStatus('Success');

		System.debug('ENDPOINT: ' + endpoint);

        if(endpoint.contains('services/data/v60.0/sobjects/')){
			System.debug('AM HERE');
            String contractsId = DeveloperUtils.getRandomString(16);
			res.setBody('{"id":"' + contractsId + '","success":true,"errors":[]}');
			res.setStatus('Created');
        }
		
		return res;
	}
}
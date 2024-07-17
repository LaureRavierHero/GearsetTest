public with sharing class TranslateJsonToObjects {
    // payload can be any json string
    private String payload;
    // keyMap is a JSON formatted key:value map where the left side is the name of the
    // key in the payload object, and the right side is the name of the key in
    // the returning json.
    private String keyMap;

    public TranslateJsonToObjects(String payload, String keyMap) {
        this.payload = payload;
        this.keyMap = keyMap;
    }

    public TranslateJsonToObjects(
        String payload,
        Dataweave_Mapping__mdt dataweaveMappingMDTRecord
    ) {
        this(
            payload,
            fetchMappingFromCustomMetadata(dataweaveMappingMDTRecord)
        );
    }

    public String translate() {
        Map<String, Object> parameters = new Map<String, Object>();
        parameters.put('mapping', keyMap);
        parameters.put('payload', payload);
        DataWeave.Script script = new DataWeaveScriptResource.translateJson();
        DataWeave.Result result = script.execute(parameters);
        return result.getValueAsString();
    }

    public List<sObject> translateToSObjects(String sObjectType) {
        Type dynamicListType = Type.forName('List<' + sObjectType + '>');
        return (List<sObject>) JSON.deserialize(translate(), dynamicListType);
    }

    public static String fetchMappingFromCustomMetadata(
        Dataweave_Mapping__mdt dataweaveMappingMDT,
        Boolean reverse
    ) {
        List<Dataweave_Key_Mapping__mdt> mappings = [
            SELECT incoming_key__c, outgoing_key__c
            FROM Dataweave_key_mapping__mdt
            WHERE Dataweave_mapping__c = :dataweaveMappingMDT.id
        ];
        Map<String, String> results = new Map<String, String>();

        // TODO: unhack this crap

        for (Dataweave_key_mapping__mdt mapping : mappings) {
            if (reverse) {
                results.put(mapping.outgoing_key__c, mapping.incoming_key__c);

            }
            else {
                results.put(mapping.incoming_key__c, mapping.outgoing_key__c);
            }
        }
        // Should mock a response

        return JSON.serialize(results);
    }

    public static String fetchMappingFromCustomMetadata(
        Dataweave_Mapping__mdt dataweaveMappingMDT) {
        return fetchMappingFromCustomMetadata(dataweaveMappingMDT, false);
    }
}
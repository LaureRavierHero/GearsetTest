public class DeveloperUtils {
    public static void                  printMap(Map<String, Object> mp) {
        for (String key: mp.keySet()) {
            System.debug('key: ' + key);
            System.debug('value: ' + mp.get(key));
        }
    }

    public static void                  printList(List<Object> lst) {
        for (Integer i = 0; i < lst.size(); ++i) {
            System.debug(String.valueOf(lst[i]));
        }
    }

    public static void                  printSet(Set<Object> s) {
        for (Object item: s) {
            System.debug(String.valueOf(item));
        }
    }

    public static void                  printSet(Set<String> s) {
        for (String item: s) {
            System.debug(item);
        }
    }

    public static Map<String, Id>       mapIdToStringField(List<SObject> objects, String keyField,
    String valField) {
        Map<String, Id> result = new Map<String, Id>();
        if (objects != null) {
            for (SObject obj: objects) {
                result.put((String)obj.get(keyField), (Id)obj.get(valField));
            }
        }
        return result;
    }

    public static Map<Id, Id>       mapIdToIdField(List<SObject> objects, String keyField,
    String valField) {
        Map<Id, Id> result = new Map<Id, Id>();
        if (objects != null) {
            for (SObject obj: objects) {
                result.put((Id)obj.get(keyField), (Id)obj.get(valField));
            }
        }
        return result;
    }

    public static Map<String, Id>       mapIdToName(List<SObject> objects) {
        Map<String, Id> result = new Map<String, Id>();

        return mapIdToStringField(objects, 'Name', 'Id');
    }

    public static Map<String, String>       mapStringFieldToStringField(List<SObject> objects, String keyField,
    String valField) {
        Map<String, String> result = new Map<String, String>();
        if (objects != null) {
            for (SObject obj: objects) {
                result.put((String)obj.get(keyField), (String)obj.get(valField));
            }
        }
        return result;
    }

    public static Set<String>           getStringFieldSet(List<SObject> objects, String fieldName) {
        Set<String> fieldNameSet = new Set<String>();

        for (SObject obj: objects) {
            fieldNameSet.add((String)obj.get(fieldName));
        }
        fieldNameSet.remove(null);
        return fieldNameSet;
    }

    public static Set<Id>           getIdFieldSet(List<SObject> objects, String fieldName) {
        Set<Id> fieldIdSet = new Set<Id>();

        for (SObject obj: objects) {
            fieldIdSet.add((Id)obj.get(fieldName));
        }
        fieldIdSet.remove(null);
        return fieldIdSet;
    }

    public static Set<Id>           getIdFieldSet(Map<String, Object> objects, String fieldName) {
        Set<Id> fieldIdSet = new Set<Id>();

        for (String key: objects.keySet()) {
            fieldIdSet.add((Id)objects.get(fieldName));
        }
        fieldIdSet.remove(null);
        return fieldIdSet;
    }

    public static SObject              getObjectFromFieldName(SObject obj, String key) {
        List<String>    split = key.split('\\.');
        List<String>    fieldNames = (List<String>)DeveloperUtils.slice(split, 0, split.size() - 1);
        SObject         curr = obj;

        for (String pt: fieldNames) {
            curr = curr.getSObject(pt);
        }

        return curr;
    }

    public static String getFieldValueAsString(SObject obj, String fieldName) {
        SObject curr = getObjectFromFieldName(obj, fieldName);
        List<String> split = fieldName.split('\\.');
        String field = (String)DeveloperUtils.getLastElement(split);
        
        return String.valueOf(curr.get(field));
    }

    public static Object       getLastElement(List<Object> elements) {
        return elements[elements.size() - 1];
    }

    /* Returns copy of list within specified indexes (includes startindex, excludes end index) */
    public static Object       slice(List<Object> input, Integer startIndex, Integer lastIndex) {
        List<Object> output = input.clone();

        for (Integer i = 0; i < startIndex; ++i) {
            output.remove(0);
        }

        Integer outputLen = lastIndex - startIndex;

        while(output.size() > outputLen) {
            output.remove(outputLen);
        }

        return output;
    }

    public static Object       slice(List<Object> input, Integer startIndex) {
        List<Object> output = input.clone();

        if (startIndex < 0) {
            startIndex = input.size() + startIndex;
        }
        
        for (Integer i = 0; i < startIndex; ++i) {
            output.remove(0);
        }
        return output;
    }

    public static Set<String>             convertToStringSet(Set<Id> ids) {
        return new Set<String>((List<String>)new List<Id>(ids));
    }
    
    public static void                    mapValuesFromObjectToObject(Map<String, String> keyMap,
    SObject oldObj, SObject newObj) {
        for (String key: keyMap.keySet()) {
            newObj.put(key, oldObj.get(keyMap.get(key)));
        }
    }

    public static void                    mapValuesFromObjectToMap(Map<String, String> keyMap,
    SObject oldObj, Map<String, Object> newObj) {

        for (String key: keyMap.keySet()) {
            newObj.put(key, oldObj.get(keyMap.get(key)));
        }
    }

    public static Map<String, String>     reverseMap(Map<String, String> oldMap) {
        Map<String, String> newMap = new Map<String, String>();

        for (String key: oldMap.keySet()) {
            newMap.put(oldMap.get(key), key);
        }

        return newMap;
    }

    public static Map<Id, SObject>  mapObjectToIdField(List<SObject> objects, 
    String fieldName) {
        String typeString = String.valueOf(objects[0].getSObjectType());
		Type t = Type.forName('Map<Id,' + typeString + '>');  
        Map<Id, SObject> res = (Map<Id, SObject>)t.newInstance();

        for (SObject obj: objects) {
            res.put((Id)obj.get(fieldName), obj);
        }

        return res;
    }

    public static Map<String, SObject>  mapObjectToStringField(List<SObject> objects, 
    String fieldName) {
        String typeString = String.valueOf(objects[0].getSObjectType());
		Type t = Type.forName('Map<String,' + typeString + '>');
        Map<String, SObject> res = (Map<String, SObject>)t.newInstance();

        for (SObject obj: objects) {
            res.put((String)obj.get(fieldName), obj);
        }

        return res;
    }

    public static Map<Id, Set<Id>>  groupIdsByIdField(List<SObject> objects, String keyFieldName, 
    String valueFieldName) {
        Map<Id, Set<Id>> res = new Map<Id, Set<Id>>();

        for (SObject obj: objects) {
            Id key = (Id)obj.get(keyFieldName);
            Id value = (Id)obj.get(valueFieldName);

            if (res.get(key) == null) {
                res.put(key, new Set<Id>());
            }

            if (String.isNotBlank(value)) {
                if (res.get(key) == null) {
                    res.put(key, new Set<Id>());
                }
    
                System.debug(obj.get(valueFieldName));
                res.get(key).add((Id)obj.get(valueFieldName));
            }
        }

        return res;
    }

    public static String getRandomString(Integer len) {
        Blob blobKey = crypto.generateAesKey(192);
        String key = EncodingUtil.base64encode(blobKey);
        return key.substring(0, len);
    }

    public static List<SObject> filterByStringFieldValue(List<SObject> objects, String fieldName, String fieldValue) {
        List<SObject> res = new List<SObject>();

        for (SObject obj: objects) {
            if (obj.get(fieldName) == fieldValue) {
                res.add(obj);
            }
        }

        return res;
    }

    public static String currencyToString(String dblString){
		if(dblString.contains(',')){
			String beforeDot = dblString.SubstringBefore(',');
			String afterDot = dblString.SubstringAfter(',');
			String returnString = beforeDot + '.' + afterDot;
			return returnString;
		}else{
			return dblString;
		}
	}

	public static String formatDateToStringDDMMMYYYY(Date inputDate){
		if(inputDate == null){
			return '';
		}
		String returnString = '';
		if(Integer.valueOf(inputDate.day()) < 10){
			returnstring += inputDate.day(); 
		}else{
			returnstring += inputDate.day();
		}
		returnString += ' ' + getMonthNameByNumber(inputDate.month());
		returnString += ' ' + inputDate.year();
		return returnString;
	}

	public static String getMonthNameByNumber(Integer monthNumber){
		switch on monthNumber {
			when 1 { return 'januari';      }	
			when 2 { return 'februari';     }
			when 3 { return 'maart';        }
			when 4 { return 'april';        }	
			when 5 { return 'mei';          }
			when 6 { return 'juni';         }
			when 7 { return 'juli';         }	
			when 8 { return 'augustus';     }
			when 9 { return 'september';    }
			when 10 { return 'oktober';     }	
			when 11 { return 'november';    }
			when 12 { return 'december';    }
			when else { return '';          }
		}
	}
	
	public static Map<Integer, List<Id>> getIdsByKey(Set<Id> idsToCreate, Integer batchSize){
		Integer key = 0;
		Integer num = 0;
		List<Id> tempList = new List<Id>();
		Map<Integer, List<Id>> idsByKey = new Map<Integer, List<Id>>();
		
		for(Id recordId : idsToCreate){
			if(num < batchSize){
				templist.add(recordId);
				num++;
			}else{
				idsByKey.put(key, templist);
				key++;

				templist = new List<id>();
				num = 0;
			}
		}

		if(templist.size() > 0){
			idsByKey.put(key, templist);
		}

		return idsByKey;
	}

	public static String formatDateTimeToStringDDMMYYYY(DateTime inputDateTime){
		if(inputDateTime == null){
			return '';
		}
		String returnString = '';
	   
		if(Integer.valueOf(inputDateTime.day()) < 10){
			returnstring += '0' + inputDateTime.day(); 
		}else{
			returnstring += inputDateTime.day();
		}
		if(Integer.valueOf(inputDateTime.month()) < 10){
			returnstring += '-0' + inputDateTime.month(); 
		}else{
			returnstring += '-' + inputDateTime.month();
		}
		returnString += '-' + inputDateTime.year();

		return returnString;
	}

	public static String formatDateToStringYYYYMMDD(Date inputDate){
		if(inputDate == null){
			return '';
		}
		String returnString = '';
		returnString += inputDate.year();
		if(Integer.valueOf(inputDate.month()) < 10){
			returnstring += '-0' + inputDate.month(); 
		}else{
			returnstring += '-' + inputDate.month();
		}
		if(Integer.valueOf(inputDate.day()) < 10){
			returnstring += '-0' + inputDate.day(); 
		}else{
			returnstring += '-' + inputDate.day();
		}

		return returnString;
	}
}
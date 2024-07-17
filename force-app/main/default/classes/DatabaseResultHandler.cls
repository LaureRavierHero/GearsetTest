public with sharing class DatabaseResultHandler {
    public static void handlerDatabaseResults(Database.SaveResult[] results) {
        for (Database.SaveResult res: results) {
            
            if (res.isSuccess()) {
                Id recordId = res.getId();

                System.debug(LoggingLevel.INFO, 'Successfully inserted/updated ' + recordId.getSobjectType() + ' with id ' + recordId);
            }
            else {
                System.debug('Errors have occured for update or insert operation');
                for (Database.Error err : res.getErrors()) {
                    System.debug(LoggingLevel.ERROR, err.getStatusCode() + ': ' + err.getMessage());
                    System.debug(LoggingLevel.ERROR, 'Fields that affected this error: ' + err.getFields());
                }
            }
        }
    }
}
public with sharing class QueueableHandler {
  // Dispatch actual methods
  public String action;
  public Map<String, Object> arguments;

  public QueueableHandler(String actionType, Map<String, Object> args) {
    this.action = actionType;
    this.arguments = args;
  }
   
  public Object call() {
    switch on action {
        when 'createUser' {
            return UserFunctions.createProfessionalPortalUserFromContact((Contact)this.arguments.get('contact'));
            // return this.concatStrings((String)args.get('stringValue'));
        }
        when else {
                throw new ExtensionMalformedCallException('Method not implemented: ' + this.action);
            }
        }
    }

    public AsyncOptions getDuplicateSignature() {
        AsyncOptions options = new AsyncOptions();
        Id uniqueId;
        switch on this.action {
            when 'createUser' {
                uniqueId = ((Contact)this.arguments.get('contact')).Id;
                options.DuplicateSignature = QueueableDuplicateSignature.Builder()
                                    .addId(uniqueId)
                                    .addString(this.action)
                                    .build();
            }
            when else {
                
            }
        }

        return options;
    }

    public class ExtensionMalformedCallException extends Exception {}
}
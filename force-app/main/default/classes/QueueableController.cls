public virtual with sharing class QueueableController implements Queueable, Finalizer {
    // Queueable implementation
    // A queueable job that uses QueueableController to buffer the log
    // and commit upon exit, even if the queueable execution fails
    QueueableHandler qh;

    public class QueueableException extends Exception {}

    public QueueableController(String actionType, Map<String, Object> args) {
        this.qh = new QueueableHandler(actionType, args);
    }

    public QueueableController(QueueableHandler qh) {
        this.qh = qh;
    }

    public void execute(QueueableContext ctx) {
        String jobId = '' + ctx.getJobId();
        System.debug('Begin: executing queueable job: ' + jobId);
        try {
            // Create an instance of QueueableController and attach it
            // Alternatively, System.attachFinalizer(this) can be used instead of instantiating QueueableController
            // QueueableController f = new QueueableController();
            System.attachFinalizer(this);

            // While executing the job, log using QueueableController.addLog()
            // Note that addlog() modifies the Finalizer's state after it is attached 
            DateTime start = DateTime.now();
            addLog('Starting action ' + this.qh.action + ' with arguments ' + this.qh.arguments, jobId);

            this.qh.call();
            addLog('Parent queueable job [' + jobId + '] completed successfully.', jobId);
        } catch (Exception e) {
            System.debug('Error executing the job [' + jobId + ']: ' + e.getMessage());
            addLog('Parent queueable job [' + jobId + '] failed due to unhandled exception: ' + e.getMessage(), jobId);
            throw e;
        } finally {
            System.debug('Completed: execution of queueable job: ' + jobId);
        }
    }

// Finalizer implementation
// Logging finalizer provides a public method addLog(message,source) that allows buffering log lines from the Queueable job.
// When the Queueable job completes, regardless of success or failure, the QueueableController instance commits this buffered log.
// Custom object LogMessage__c has four custom fields-see addLog() method.

    // internal log buffer
    private List<LogMessage__c> logRecords = new List<LogMessage__c>();

    public void execute(FinalizerContext ctx) {
        String parentJobId = ctx.getAsyncApexJobId();
        System.debug('Begin: executing finalizer attached to queueable job: ' + parentJobId);

        // Update the log records with the parent queueable job id
        System.Debug('Updating job id on ' + logRecords.size() + ' log records');
        for (LogMessage__c log : logRecords) {
            log.Request__c = parentJobId; // or could be ctx.getRequestId()
        }
        // Commit the buffer
        System.Debug('committing log records to database');
        Database.insert(logRecords, false);

        if (ctx.getResult() == System.ParentJobResult.SUCCESS) {
            System.debug('Parent queueable job [' + parentJobId + '] completed successfully.');
        } else {
            System.debug('Parent queueable job [' + parentJobId + '] failed due to unhandled exception: ' + ctx.getException().getMessage());
            String newJobId = '' + System.enqueueJob(new QueueableController(this.qh));

            System.debug('Enqueueing another instance of the queueable with id ' + newJobId);
        }
        System.debug('Completed: execution of finalizer attached to queueable job: ' + parentJobId);
    }

    public void addLog(String message, String source) {
        // append the log message to the buffer
        logRecords.add(new LogMessage__c(
            DateTime__c = DateTime.now(),
            Message__c = message,
            Request__c = 'setbeforecommit',
            Source__c = source
        ));
    }

    public void enqueue() {
        AsyncOptions options = this.qh.getDuplicateSignature();
        try {
            System.enqueueJob(this, options);
        } catch (DuplicateMessageException e) {
            //Exception is thrown if there is already an enqueued job with the same 
            //signature
            System.debug('Attempt to enqueue job with duplicate queueable signature' + e.getMessage());
            throw new QueueableException(e.getMessage());
        }
    }
}
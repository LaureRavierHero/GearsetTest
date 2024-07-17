public class TaskHandler {
    class TaskHandlerException extends Exception{}

    @InvocableMethod(label = 'Create task from flow')
    public static void createTaskFlow(List<TaskWrapperFlow> taskWrapperFlows) {
        TaskWrapper mw = new TaskWrapper(taskWrapperFlows[0]);

        createTask(mw);
    }

    public static void createTasks(List<TaskWrapper> wrappers){
        List<Task> tasksToInsert = new List<Task>();
        for(TaskWrapper wrapper : wrappers){
            Task task = getTask(wrapper);
            tasksToInsert.add(task);
        }

        insert tasksToInsert;
    }

    public static void createTask(TaskWrapper wrapper){
        Task task = getTask(wrapper);
        insert task;
    }

    public static Task getTask(Taskwrapper wrapper){
        Task task = new Task();
        String recordName = wrapper.recordName != null ? wrapper.recordName : getRecordName(wrapper.whatId);
        task.Subject = System.Label.get('', 'lbl_' + wrapper.type + '_Subject') + ' ' + recordName;
        task.WhatId = wrapper.whatId;
        task.OwnerId = wrapper.ownerId;
        task.ActivityDate = wrapper.activityDate;
        task.Type = wrapper.type;
        task.Description = wrapper.description;
        return task;
    }
    
    public static String getRecordName(Id whatId){
        String queryString = 'SELECT Name FROM ' + whatId.getSObjectType() + ' WHERE Id = \'' + whatId + '\'';
        sObject s = Database.query(queryString);

        if(s.get('Name') != null){
            return String.valueOf(s.get('Name'));
        }else{
            return '';
        }
    }

    public class TaskWrapper{
        public String type {get;set;}
        public String whatId {get;set;}
        public String ownerId {get;set;}
        public String recordName {get;set;}
        public Date activityDate {get;set;}
        public String description {get;set;}

        public TaskWrapper(){}

        public TaskWrapper(String type, String whatId, String ownerId, Date activityDate){
            this.type = type;
            this.whatId = whatId;
            this.ownerId = ownerId;
            this.activityDate = activityDate;
        }

        public TaskWrapper(String type, String whatId, String ownerId, Date activityDate, String recordName){
            this.type = type;
            this.whatId = whatId;
            this.ownerId = ownerId;
            this.activityDate = activityDate;
            this.recordName = recordName;
        }

        public TaskWrapper(String type, String whatId, String ownerId, Date activityDate, String recordName, String description){
            this.type = type;
            this.whatId = whatId;
            this.ownerId = ownerId;
            this.activityDate = activityDate;
            this.recordName = recordName;
            this.description = description;
        }

        public TaskWrapper(TaskWrapperFlow flow){
            type = flow.type;
            whatId = flow.whatId;
            ownerId = flow.ownerId;
            recordName = flow.recordName;
            activityDate = flow.activityDate;
            description = flow.description;
        }
    }

    public class TaskWrapperFlow{
        @InvocableVariable(required=true) public Id ownerId;
        @InvocableVariable(required=true) public Id whatId;
        @InvocableVariable(required=true) public String type;
        @InvocableVariable(required=true) public Date activityDate;
        @InvocableVariable public String recordName;
        @InvocableVariable public String description;
    }
}
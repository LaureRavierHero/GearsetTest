@istest
public class TaskHandlerTest {
    @istest
    public static void testCreateTask() {
        Position__c pos = TestDataFactory.getPosition(true);
        insert pos;

        TaskHandler.TaskWrapper wrapper = new TaskHandler.TaskWrapper();
        wrapper.type = 'new_position'; //Important that a label exists for this type
        wrapper.whatId = pos.Id;
        wrapper.ownerId = UserInfo.getUserId();
        wrapper.activityDate = system.today();

        Test.startTest();
        TaskHandler.createTask(wrapper);
        Test.stopTest();

        List<Task> createdTask = [SELECT Id FROM Task];
        Assert.areEqual(2, createdTask.size());
    }

    @istest
    public static void testCreateTaskOtherConstructor() {
        Position__c pos = TestDataFactory.getPosition(true);
        insert pos;

        TaskHandler.TaskWrapper wrapper = new TaskHandler.TaskWrapper('new_position', pos.id, UserInfo.getUserId(), system.today());

        Test.startTest();
        TaskHandler.createTask(wrapper);
        Test.stopTest();

        List<Task> createdTask = [SELECT Id FROM Task];
        Assert.areEqual(2, createdTask.size());
    }

    @istest
    public static void testCreateTaskCustomRecordName() {
        Position__c pos = TestDataFactory.getPosition(true);
        insert pos;

        TaskHandler.TaskWrapper wrapper = new TaskHandler.TaskWrapper('new_position', pos.id, UserInfo.getUserId(), system.today(), 'testName');

        Test.startTest();
        TaskHandler.createTask(wrapper);
        Test.stopTest();

        List<Task> createdTask = [SELECT Id, Subject FROM Task ORDER BY CreatedDate DESC];
        System.debug('Created Tasks');
        DeveloperUtils.printList(createdTask);
        Assert.areEqual(2, createdTask.size());
        Assert.isTrue(createdTask[1].Subject.contains('testName'));
    }

    @istest
    public static void testCreateTaskFlow() {
        Position__c pos = TestDataFactory.getPosition(true);
        insert pos;

        TaskHandler.TaskWrapperFlow wrapper = new TaskHandler.TaskWrapperFlow();
        wrapper.type = 'new_position'; //Important that a label exists for this type
        wrapper.whatId = pos.Id;
        wrapper.ownerId = UserInfo.getUserId();
        wrapper.activityDate = system.today();

        Test.startTest();
        TaskHandler.createTaskFlow(new List<TaskHandler.TaskWrapperFlow>{wrapper});
        Test.stopTest();

        List<Task> createdTask = [SELECT Id FROM Task];
        Assert.areEqual(2, createdTask.size());
    }
}
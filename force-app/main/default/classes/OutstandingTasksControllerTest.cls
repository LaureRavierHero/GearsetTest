@istest
public class OutstandingTasksControllerTest {
	@istest
	public static void getTasksTest(){
		User u = TestDataFactory.getUser();
		insert u;

		Account a = TestDataFactory.getAccount('Test account');
		insert a;

		List<Task> taskList = new List<Task>();

		// TODO  add testdatafactory method for a task
		taskList.add(new Task(
			Subject = 'Task with a deadline of 2 weeks',
			Description = 'Read the subject',
			WhatId = a.Id,
			OwnerId = u.Id,
			Status = 'Open',
			ActivityDate = System.today().addDays(14)
		));

		taskList.add(new Task(
			Subject = 'Task with a deadline of 1 week',
			Description = 'Read the subject',
			WhatId = a.Id,
			OwnerId = u.Id,
			Status = 'Open',
			ActivityDate = System.today().addDays(7)
		));

		taskList.add(new Task(
			Subject = 'Task with a deadline of 1 day',
			Description = 'Read the subject',
			WhatId = a.Id,
			OwnerId = u.Id,
			Status = 'Open',
			ActivityDate = System.today().addDays(1)
		));
		
		taskList.add(new Task(
			Subject = 'Task with a passed deadline',
			Description = 'Read the subject',
			WhatId = a.Id,
			OwnerId = u.Id,
			Status = 'Open',
			ActivityDate = System.today().addDays(-2)
		));

		insert taskList;

		Test.startTest();
		List<OutstandingTasksController.TaskC> tasksC = OutstandingTasksController.getTasks(u.Id, null);
		Test.stopTest();

		Assert.areEqual(a.Id, tasksC[0].WhatId.replace('/',''));
	}
	
	@istest
	public static void completeTaskTest(){
		User u = TestDataFactory.getUser();
		insert u;

		Account a = TestDataFactory.getAccount('Test account');
		insert a;

		Task t = new Task(
			Subject = 'Task with a deadline of 2 weeks',
			Description = 'Read the subject',
			WhatId = a.Id,
			OwnerId = u.Id,
			Status = 'Open',
			ActivityDate = System.today().addDays(14)
		);

		insert t;

		Test.startTest();
		Boolean updateResult = OutstandingTasksController.updateTask(t.Id, true); // true is equal to a checked checkbox
		Test.stopTest();

		Task updatedTask = [SELECT CompletedDateTime FROM Task WHERE Id = :t.Id LIMIT 1];
		
		Assert.isTrue(updatedTask.CompletedDateTime != null);
	}
	
	@istest
	public static void uncompleteTaskTest(){
		User u = TestDataFactory.getUser();
		insert u;

		Account a = TestDataFactory.getAccount('Test account');
		insert a;

		Task t = new Task(
			Subject = 'Task with a deadline of 2 weeks',
			Description = 'Read the subject',
			WhatId = a.Id,
			OwnerId = u.Id,
			Status = 'Completed',
			ActivityDate = System.today().addDays(14)
		);

		insert t;

		OutstandingTasksController.updateTask(t.Id, true); // true is equal to a checked checkbox

		Test.startTest();
		Boolean updateResult = OutstandingTasksController.updateTask(t.Id, false); // false is equal to an unchecked checkbox
		Test.stopTest();

		Task updatedTask = [SELECT CompletedDateTime FROM Task WHERE Id = :t.Id LIMIT 1];
		Assert.isTrue(updatedTask.CompletedDateTime == null);
	}
}
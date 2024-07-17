global with sharing class TimesheetRegistrationController {
	@AuraEnabled(cacheable = true)
	public static TimesheetWrapper getData(String recordId) {
		// User u = [SELECT Id, ContactId FROM User WHERE id = :userId];

		TimesheetWrapper tsWrapper = new TimesheetWrapper();
		tsWrapper.entries = new List<TimesheetEntries>();
		
		Map<Id, Timesheet_entry__c> entriesById = new Map<Id, Timesheet_entry__c>([
			SELECT
				Id, Date__c, Hours__c, Minutes__c, Rate_Percentage__c, Rate_Percentage__r.Name, Rate_percentage__r.Percentage__c, Comment__c, Timesheet__c, Amount__c, Travel_expenses__c, Expense_type__c,
				Attachment_name__c, Attachment_content_version_ID__c, Attachment_document_ID__c,
				RecordType.Name, Is_record_type_default__c, Is_record_type_expense__c, Timesheet__r.Placement__c, Timesheet__r.Placement__r.Travel_expenses__c, Timesheet__r.Approval_status__c,
				Timesheet__r.Placement__r.Name, Timesheet__r.Professional__r.Name, Timesheet__r.Placement__r.Account__r.Name
			FROM
				Timesheet_entry__c
			WHERE
				Timesheet__c = :recordId
			ORDER BY
				Date__c ASC, Rate_percentage__r.Percentage__c ASC, Amount__c ASC
		]);

		Timesheet_entry__c firstEntry = entriesById.values()[0];

		tsWrapper.ratePercentages = [SELECT Id, Name, Rate_Percentage__c FROM Placement_rate_percentage__c WHERE Placement__c = :firstEntry.Timesheet__r.Placement__c];
		tsWrapper.travelCostEnabled = firstEntry.Timesheet__r.Placement__r.Travel_expenses__c;
		tsWrapper.locked = Approval.isLocked(recordId);
		tsWrapper.reopenPossible = firstEntry.Timesheet__r.Approval_status__c == 'Submitted' ? true : false;
		tsWrapper.exportPossible = entriesById.size() > 0 ? true : false;
		
		// This variable is for correct HTML layout
		// expensesDisabled is linked to the HTML attribute 'read-only'
		// If read-only and disabled are both true, the input looks weird
		// Therefore if the form is locked, make read-only false so that it looks like a regular input (read-only not needed because it's disabled anyway)
		// And if form is not locked, make read-only true so that it will look like an expense field
		tsWrapper.expensesDisabled = tsWrapper.locked == true ? false : true;

		// After fetching all data, loop through it and organize it in a map with as key Date and as values a list of timesheet entries with that same date
		Map<Date, List<Timesheet_entry__c>> recordsPerDay = new Map<Date, List<Timesheet_entry__c>>();

		System.debug('Rate percentages');
		for(Timesheet_entry__c entry : entriesById.values()) {
			System.debug(entry.Rate_percentage__r.Percentage__c);

			if(entry.Date__c != null){
				if(recordsPerDay.get(entry.Date__c) == null) {
					recordsPerDay.put(entry.Date__c, new List<Timesheet_entry__c>());
				}

				recordsPerDay.get(entry.Date__c).add(entry);
			}
		}

		// Loop through recordsPerDay map and make a TimesheetEntries object with as day the date, and values the entries
		// So that its formatted correctly to use in LWC
		for(Date dateKey : recordsPerDay.keySet()) {
			Boolean travelExpenseCheck = false;
			
			List<Timesheet_entry__c> timelogs = new List<Timesheet_entry__c>();
			List<Timesheet_entry__c> expenses = new List<Timesheet_entry__c>();

			for(Timesheet_entry__c entry : recordsPerDay.get(dateKey)) {
				if(entry.Travel_expenses__c == true) {
					travelExpenseCheck = true;
				}

				if(entry.Is_record_type_expense__c) {
					expenses.add(entry);
				} else {
					timelogs.add(entry);
				}
			}
			
			TimesheetEntries entries = new TimesheetEntries();
			// entries.day = DateTime.newInstance(dateKey.year(),dateKey.month(),dateKey.day()).format('EEEE dd MMM yyyy');
			Integer daysBetween = dateKey.toStartofWeek().daysBetween(dateKey);

			String typeOfDay = 'workday';

			if(daysBetween == 5) {
				typeOfDay = 'saturday';
			} else if(daysBetween == 6) {
				typeOfDay = 'sunday';
			}

			entries.day = dateKey;
			entries.dayFormatted = dateKey.format();
			entries.typeOfDay = typeOfDay;
			entries.travelExpenses = travelExpenseCheck;
			entries.expensesMade = expenses.size() > 0 ? true : false;
			entries.timelogs = timelogs;
			entries.expenses = expenses;
			tsWrapper.entries.add(entries);

			if(tsWrapper.anyExpensesMade != true && entries.expensesMade == true){
				tsWrapper.anyExpensesMade = true;
			}
		}

		//List<Id> placementIds = new List<Id>{'a0dVe000000R7mzIAC'};
		//List<Placement_rate_percentage__c> ratePercentages = [SELECT Id, Name, Rate_Percentage__c FROM Placement_rate_percentage__c WHERE Placement__c IN :placementIds];

		tsWrapper.timesheetId = entriesById.values()[0].Timesheet__c;

		return tsWrapper;
	}

	@AuraEnabled
	public static DMLResult saveTimesheetEntries(List<TimesheetEntries> entries, List<String> idsToUpdate, List<String> idsToDelete) {
		Map<Id, Timesheet_entry__c> entriesMap = new Map<Id, Timesheet_entry__c>();
		List<Timesheet_entry__c> entriesToInsert = new List<Timesheet_entry__c>();
		List<Timesheet_entry__c> entriesToUpdate = new List<Timesheet_entry__c>();
		Map<Date, Boolean> travelExpensePerDayMap = new Map<Date, Boolean>();
		
		try {
			for(TimesheetEntries timesheetEntries : entries) {
				travelExpensePerDayMap.put(timesheetEntries.day, timesheetEntries.travelExpenses);
				entriesMap.putAll(timesheetEntries.timelogs);
			}

			for(Timesheet_entry__c entry : entriesMap.values()) {
				// If entry has no id and minimum all of the field must be filled
				// insert it. Else update it

				// If entry is a default record, it must mean that travel expenses per day can be toggled on/off on the entry
				if(entry.Is_record_type_default__c == true) {
					// Set travel expenses true/false depending on the boolean in the travelExpensePerDayMap
					if(entry.Travel_expenses__c != null && entry.Travel_expenses__c != travelExpensePerDayMap.get(entry.Date__c)) {
						entry.Travel_expenses__c = travelExpensePerDayMap.get(entry.Date__c);
						
						if(!idsToUpdate.contains(entry.Id)) idsToUpdate.add(entry.Id);
					}
				}

				if(entry.Id == null
				&& (entry.Hours__c != null
					|| entry.Minutes__c != null
					|| entry.Comment__c != null
				)) {
					entriesToInsert.add(entry);
				} else{
					if(idsToUpdate.contains(entry.Id)) {
						entriesToUpdate.add(entry);
					}
				}
			}

			DMLResult dmlResult = new DMLResult();

			dmlResult.insertEntries = false;
			dmlResult.updateEntries = false;
			dmlResult.deleteEntries = false;

			if(!entriesToInsert.isEmpty()) {
				Database.SaveResult[] entriesInsert = Database.insert(entriesToInsert, false);

				// Iterate through each returned result
				for (Database.SaveResult sr : entriesInsert) {
					if (sr.isSuccess()) {
						dmlResult.insertEntries = true;
						// Operation was successful, so get the ID of the record that was processed
						System.debug('Successfully inserted record. Record ID: ' + sr.getId());
					} else {
						// Operation failed, so get all errors                
						for(Database.Error err : sr.getErrors()) {
							System.debug('The following error has occurred.');                    
							System.debug(err.getStatusCode() + ': ' + err.getMessage());
							System.debug('Record fields that affected this error: ' + err.getFields());
						}
					}
				}
			}

			if(!entriesToUpdate.isEmpty()) {
				Database.SaveResult[] entriesUpdate = Database.update(entriesToUpdate, false);

				// Iterate through each returned result
				for (Database.SaveResult sr : entriesUpdate) {
					if (sr.isSuccess()) {
						dmlResult.updateEntries = true;
						// Operation was successful, so get the ID of the record that was processed
						System.debug('Successfully updates record. Record ID: ' + sr.getId());
					} else {
						// Operation failed, so get all errors                
						for(Database.Error err : sr.getErrors()) {
							System.debug('The following error has occurred.');                    
							System.debug(err.getStatusCode() + ': ' + err.getMessage());
							System.debug('Record fields that affected this error: ' + err.getFields());
						}
					}
				}
			}

			if(!idsToDelete.isEmpty()) {
				delete [SELECT Id FROM Timesheet_entry__c WHERE Id IN :idsToDelete];
				dmlResult.deleteEntries = true;
			}

			return dmlResult;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	// @AuraEnabled
	// public static void submitForApproval(String recordId) {
	// 	Timesheet__c t = [SELECT Placement__c, Timesheet_approver__c FROM Timesheet__c WHERE Id = :recordId LIMIT 1];
	// 	// Placement__c p = [SELECT Id, Timesheet_approver__c FROM Placement__c WHERE Id = :recordId LIMIT 1];

	// 	ApprovalController.submitApprovalRequestByName(t.Id, 'Approve_timesheet');
    //     TaskHandler.createTask(new TaskHandler.TaskWrapper('approve_timesheet', t.Id, t.Timesheet_approver__c, Date.today().addDays(14)));
	// }

	// @AuraEnabled
	// public static void reopen(String recordId) {
	// 	ProcessInstanceWorkitem piwi = [SELECT Id, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :recordId LIMIT 1];

	// 	List<ApprovalController.ApprovalHandlerWrapper> wrappers = new List<ApprovalController.ApprovalHandlerWrapper>();

	// 	wrappers.add(new ApprovalController.ApprovalHandlerWrapper(
    //         piwi.Id,
    //         'Removed',
    //         ''
    //     ));

	// 	ApprovalController.processApprovalRequests(wrappers);
	// }

	// public static Map<Id, Rate_Percentage__c> ratepercentagesById(List<Timesheet_entry__c> entries) {
	// 	Set<Id> ratepercentageIds = new Set<Id>();
	// 	for(Timesheet_entry__c tse : entries) {
	// 		ratepercentageIds.add(tse.Rate_Percentage__c);
	// 	}

	// 	return new Map<Id, Rate_Percentage__c>([SELECT Id, Name FROM Rate_percentage__c WHERE Id IN :ratepercentageIds]);
	// }

	// public static Decimal getMinutes(Decimal hours, Decimal minutes) {
	// 	hours = hours ?? 0;
	// 	minutes = minutes ?? 0;
	// 	return (hours * 60) + minutes;
	// }

	// public static Decimal getHours(Decimal minutes) {
	// 	minutes = minutes ?? 0;
	// 	return minutes/60;
	// }

	global class TimesheetWrapper{
		@AuraEnabled public List<TimesheetEntries> entries;
		@AuraEnabled public List<Placement_rate_percentage__c> ratePercentages;
		@AuraEnabled public User u;
		@AuraEnabled public String timesheetId;
		@AuraEnabled public Boolean travelCostEnabled;
		@AuraEnabled public Boolean locked;
		@AuraEnabled public Boolean expensesDisabled;
		@AuraEnabled public Boolean reopenPossible;
		@AuraEnabled public Boolean exportPossible;
		@AuraEnabled public Boolean anyExpensesMade;
	}

	global class TimesheetEntries {
		@AuraEnabled public Date day {get;set;}
		@AuraEnabled public String dayFormatted {get;set;}
		@AuraEnabled public String typeOfDay {get;set;}
		@AuraEnabled public Boolean travelExpenses {get;set;}
		@AuraEnabled public Boolean expensesMade {get;set;}
		@AuraEnabled public List<Timesheet_entry__c> timelogs {get;set;}
		@AuraEnabled public List<Timesheet_entry__c> expenses {get;set;}
	}

	global class DMLResult {
		@AuraEnabled public Boolean insertEntries {get;set;}
		@AuraEnabled public Boolean updateEntries {get;set;}
		@AuraEnabled public Boolean deleteEntries {get;set;}
	}
}
public without sharing class TimesheetCreator {
	private Map<Id, Date> lastEntryByTimesheet = new Map<Id, Date>();

	private Map<Id, Id> getUserInfoByProfessional(List<Placement__c> placements) {
		Set<Id> professionalContactIds = DeveloperUtils.getIdFieldSet(placements, 'Professional__c');
		List<User> professionalUsers = [SELECT Id, ContactId FROM User WHERE ContactId IN :professionalContactIds];
		Map<Id, Id> userIdByContact = DeveloperUtils.mapIdToIdField(professionalUsers, 'ContactId', 'Id');
		return userIdByContact;		
	}

	public void createTimesheets(Map<Id, Placement__c> placementsById){
		Map<Id, Timesheet__c> lastTimesheetByPlacementId = new Map<Id, Timesheet__c>();
		Map<Id, Id> userInfoByProfessional = getUserInfoByProfessional(placementsById.values());

		for (Timesheet__c timesheet : [SELECT Id, Placement__c, Start_Date__c, End_Date__c FROM Timesheet__c WHERE Placement__c IN :placementsById.keySet() ORDER BY Placement__c, End_Date__c DESC]) {
			if (!lastTimesheetByPlacementId.containsKey(timesheet.Placement__c) || lastTimesheetByPlacementId.get(timesheet.Placement__c).End_Date__c < timesheet.End_Date__c) {
				lastTimesheetByPlacementId.put(timesheet.Placement__c, timesheet);
			}
		}

		List<Timesheet__c> timesheetToCreateEntriesFor = insertAndUpdateTimesheets(placementsById, lastTimesheetByPlacementId, userInfoByProfessional);    
		
		insertEntries(placementsById, timesheetToCreateEntriesFor);
	}

	public void insertEntries(Map<Id, Placement__c> placementsById, List<Timesheet__c> timesheetToCreateEntriesFor){
		List<Timesheet_entry__c> entriesToInsert = new List<Timesheet_entry__c>();
		Id defaultRecordTypeId = Schema.SObjectType.Timesheet_entry__c.getRecordTypeInfosByDeveloperName().get('Default').getRecordTypeId();
		for(Timesheet__c timesheet : timesheetToCreateEntriesFor){
			Date currentDate = timesheet.Start_date__c;
			if(lastEntryByTimesheet.containsKey(timesheet.Id)){
				currentDate = lastEntryByTimesheet.get(timesheet.Id).addDays(1);
			}
			while(currentDate <= timesheet.End_date__c){
				Timesheet_entry__c entry = new Timesheet_entry__c();
				entry.Timesheet__c = timesheet.Id;
				entry.Name = DeveloperUtils.formatDateToStringYYYYMMDD(currentDate);
				entry.Date__c = currentDate;
				entry.Rate_Percentage__c = placementsById.get(timesheet.Placement__c).Account__r.Standard_rate_percentage__c;
				entry.RecordTypeId = defaultRecordTypeId;
				entriesToInsert.add(entry);
				currentDate = currentDate.addDays(1);
			}
		}

		insert entriesToInsert;
	}

	public List<Timesheet__c> insertAndUpdateTimesheets(Map<Id, Placement__c> placementsById,  Map<Id, Timesheet__c> lastTimesheetByPlacementId, Map<Id, Id> userInfoByProfessional){
		List<Timesheet__c> timesheetsToInsert = new List<Timesheet__c>();
		List<Timesheet__c> timesheetsToUpdate = new List<Timesheet__c>();
		List<Placement__c> placementsToUpdate = new List<Placement__c>();

		System.debug('placementsById');
		System.debug(placementsById);

		for(Id placementId : placementsById.keySet()){
			Placement__c placement = placementsById.get(placementId);

			if(lastTimesheetByPlacementId.containsKey(placementId)){
				Timesheet__c timesheet = lastTimesheetByPlacementId.get(placementId);
				if(timesheet.End_date__c == placement.Timesheets_created_till__c){
					lastEntryByTimesheet.put(timesheet.Id, timesheet.End_Date__c);

					timesheet.End_date__c = calculateTimesheetEndDate(timesheet, placement);
					timesheet.Name = generateTimesheetName(placement, timesheet);
					timesheet.OwnerId = userInfoByProfessional.get(placement.Professional__c);
					timesheet.Approver__c = placement.Approver_timesheets__c;
					timesheetsToUpdate.add(timesheet);
					placement.Timesheets_created_till__c = timesheet.End_date__c;
				}
			}
			
			while(placement.Timesheets_created_till__c == null || placement.Timesheets_created_till__c < placement.Expected_end_date__c){
				Timesheet__c timesheet = new Timesheet__c();
				timesheet.Placement__c = placementId;
				timesheet.Professional__c = placement.Professional__c;
				timesheet.Start_date__c = placement.Timesheets_created_till__c != null ? placement.Timesheets_created_till__c.addDays(1) : placement.Start_date__c;
				timesheet.End_date__c = calculateTimesheetEndDate(timesheet, placement);
				timesheet.Approver__c = placement.Approver_timesheets__c;
				timesheet.Name = generateTimesheetName(placement, timesheet);
				timesheet.OwnerId = userInfoByProfessional.get(placement.Professional__c);
				timesheetsToInsert.add(timesheet);

				placement.Timesheets_created_till__c = timesheet.End_date__c;
			}

			placementsToUpdate.add(placement);
		}

		update timesheetsToUpdate;
		update placementsToUpdate;
		insert timesheetsToInsert;

		List<TaskHandler.TaskWrapper> insertTimesheetTaskWrappers = new List<TaskHandler.TaskWrapper>();

		for(Timesheet__c t : timesheetsToInsert){
			TaskHandler.TaskWrapper wrapper = new TaskHandler.TaskWrapper('timesheet_deadline', t.Id, userInfoByProfessional.get(t.Professional__c), t.End_date__c.addMonths(1));
        	TaskHandler.createTask(wrapper);
		}

		if(insertTimesheetTaskWrappers.size() > 0){
			TaskHandler.createTasks(insertTimesheetTaskWrappers);
		}

		List<Timesheet__c> timesheetToCreateEntriesFor = new List<Timesheet__c>();
		timesheetToCreateEntriesFor.addAll(timesheetsToUpdate);
		timesheetToCreateEntriesFor.addAll(timesheetsToInsert);
		return timesheetToCreateEntriesFor;
	}

	public Date calculateTimesheetEndDate(Timesheet__c timesheet, Placement__c placement){
		Date returnDate = null;

		if (placement.Timesheet_date_notation__c == 'Months') {
			Integer lastDayOfMonth = Date.daysInMonth(timesheet.Start_date__c.Year(), timesheet.Start_date__c.Month());
			returnDate = Date.newInstance(timesheet.Start_date__c.Year(), timesheet.Start_date__c.Month(), lastDayOfMonth);
		} else if (placement.Timesheet_date_notation__c == 'Days') {
			Integer daysToAdd = 0;
			if (placement.Timesheets_created_till__c == null) {
				Date firstDayOfFirstWeek = Date.newInstance(timesheet.Start_date__c.Year(), 1, 1).toStartOfWeek();
                Integer difference = firstDayOfFirstWeek.daysBetween(timesheet.Start_date__c) + 1;
                Integer rest = Math.mod(difference, Integer.valueOf(placement.Timesheet_size__c));
				rest = rest == 0 ? Integer.valueOf(placement.Timesheet_size__c) : rest;
                daysToAdd = Integer.valueOf(placement.Timesheet_size__c - rest);
			} else {
				daysToAdd = Integer.valueOf(placement.Timesheet_size__c - 1);
			}
	
			returnDate = timesheet.Start_date__c.addDays(daysToAdd);
		}
	
		return (returnDate != null && returnDate > placement.Expected_end_date__c) ? placement.Expected_end_date__c : returnDate;
	}

	public String generateTimesheetName(Placement__c placement, Timesheet__c timesheet){
		if(placement?.Cost_center__c == null){
			return placement?.Account__r?.Name + ' - ' + timesheet?.Start_date__c?.Day() + '-' + timesheet?.Start_date__c?.Month() + '/' + timesheet?.End_date__c?.Day() + '-' + timesheet?.End_date__c?.Month();
		}

		return placement?.Account__r?.Name + '(' + placement?.Cost_center__c + ')' + ' - ' + timesheet?.Start_date__c?.Day() + '-' + timesheet?.Start_date__c?.Month() + '/' + timesheet?.End_date__c?.Day() + '-' + timesheet?.End_date__c?.Month();

	}
}
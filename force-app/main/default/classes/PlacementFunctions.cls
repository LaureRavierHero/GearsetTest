public without sharing class PlacementFunctions {
    public class PlacementException extends Exception {}
    
    private static void approveInitialApprovalRequest(Id recordId) {
        List<ProcessInstanceWorkItem> piwis = ApprovalController.getPendingApprovalRequestsWithTargetId(recordId);

        if (piwis == null || piwis.size() == 0) {
            throw new PlacementException('Could not find pending approval request for application with id ' + recordId);
        }
        if (piwis.size() > 1) {
            throw new PlacementException('Found multiple pending approval requests for application with id ' + recordId);
        }

        ApprovalController.approveApprovalRequest(piwis[0].Id);
    }

    private static Id getDefaultVendorContact(Id recordId) {
        List<Default_vendor_contact__c> dvcs = [
            SELECT Contact__c 
            FROM Default_vendor_contact__c 
            WHERE Vendor__c 
            IN (SELECT Vendor__c FROM Application__c WHERE Id = :recordId)];

        if (dvcs == null || dvcs.size() == 0) {
            throw new PlacementException('Could not find default vendor contact associated with application ' + recordId);
        }
        if (dvcs.size() > 1) {
            throw new PlacementException('Found multiple default vendor contacts for placement with application ' + recordId);
        }
        return dvcs[0].Contact__c;
    }

    private static void createTaskVendor(Id recordId, Id userId) {
        TaskHandler.TaskWrapper tw = new TaskHandler.TaskWrapper(
            'vendor_provide_professional_information',
            recordId,
            userId,
            Date.today() + 3
        );

        TaskHandler.createTask(tw);
    }

    /* This function advanced the new_placement approval process by one step, 
    from the hiring desk to the vendor for additional information. */
    @AuraEnabled
    public static void handlePlacementRequestInformation(Id recordId) {
        if (String.isBlank(recordId)) {
            return ;
        }

        try {
            // Get default vendor contact
            Id contactId = getDefaultVendorContact(recordId);
            
            approveInitialApprovalRequest(recordId);
            createTaskVendor(recordId, SchemaUtils.getUserFromContactId(contactId));
        }
        catch (Exception e) {
            AuraHandledException err = new AuraHandledException(e.getMessage());
            throw err;
        }
    }

    // private static void approveApprovalRequestHiringDesk(Id recordId) {
    //     List<ProcessInstanceWorkItem> piwis = ApprovalController.getPendingApprovalRequestsWithTargetId(recordId);

    //     if (piwis == null || piwis.size() == 0) {
    //         throw new PlacementException('Could not find pending approval request for placement with id ' + recordId);
    //     }
    //     if (piwis.size() > 1) {
    //         throw new PlacementException('Found multiple pending approval requests for placement with id ' + recordId);
    //     }

    //     ApprovalController.approveApprovalRequest(piwis[0].Id);
    // }

    private static Account getAccount(Id accountId) {
        return [SELECT Id, Standard_timesheet_date_notation__c, Standard_timesheet_size__c FROM Account WHERE Id = :accountId LIMIT 1];
    }

    private static Position__c getPosition(Id positionId) {

        return [
            SELECT Id, Name, Hiring_manager__c, End_date__c
            FROM Position__c
            WHERE Id = :positionId
            LIMIT 1
        ];
    }

    private static Application__c getApplication(Id applicationId) {
        return [
            SELECT Id, Name, Account__c, Position__c, Vendor__c, Professional__c, Candidate__c, Desired_rate__c, Available_from__c, Hours_available__c
            FROM Application__c 
            WHERE Id = :applicationId 
            LIMIT 1
        ];
    }

    @AuraEnabled
    public static Id createPlacement(Id applicationId) {
        try {
            Application__c app = getApplication(applicationId);

            // If there is no professional, we're dealing with a preferential candidate with no intervention from a vendor, 
            // therefor we have to create a professional from the contact info provided by the hiring manager
            if (String.isBlank(app.Professional__c)) {
                Candidate__c cand = [SELECT Email__c, Phone__c FROM Candidate__c WHERE Id = :app.Candidate__c];
                if (String.isBlank(cand.Email__c) || String.isBlank(cand.Phone__c)) {
                    throw new PlacementException(System.Label.lbl_contact_info_needed);
                }
                app.Professional__c = ApplicationFunctions.createProfessional(applicationId, cand.Email__c, cand.Phone__c);
                update app;
            }

            Account acc = getAccount(app.Account__c);
            Position__c pos = getPosition(app.Position__c);

            Placement__c placement = new Placement__c();

            placement.Account__c = acc.Id;
            placement.Application__c = applicationId;
            placement.Approver_timesheets__c = pos.Hiring_manager__c;
            placement.Current_rate__c = app.Desired_rate__c;
            placement.Expected_end_date__c = pos.End_date__c;
            placement.End_date__c = pos.End_date__c;
            placement.Hiring_manager__c = pos.Hiring_manager__c;
            placement.Hours_per_week__c = app.Hours_available__c;
            placement.Initial_end_date__c = placement.Expected_end_date__c;
            placement.Name = pos.Name + ' - ' + app.Name;
            placement.Position__c = pos.Id;
            placement.Processing_status__c = 'New';
            placement.Status__c = 'New';
            placement.Professional__c = app.Professional__c;
            placement.Start_date__c = app.Available_from__c;
            placement.Timesheet_date_notation__c = acc.Standard_timesheet_date_notation__c;
            placement.Timesheet_size__c = acc.Standard_timesheet_size__c;
            placement.Vendor__c = app.Vendor__c;

            insert placement;

            app.Placement__c = placement.Id;
            return placement.Id;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static Contact getProfessional(Id placementId) {
        return [
            SELECT Id, FirstName, LastName, Phone, Email 
            FROM Contact 
            WHERE Id IN (
                SELECT Professional__c 
                FROM Placement__c 
                WHERE Id = :placementId) 
            LIMIT 1];
    }

    @AuraEnabled
    public static void sendPlacementForContracting(Id recordId) {
        HeroSalesforceConnector.executeCreate(recordId);

        // Create user associated with contact
        Contact prof = getProfessional(recordId);
        System.enqueueJob(new QueueableController('createUser', new Map<String, Object>{
            'contact' => prof
        }));

        // approveApprovalRequestHiringDesk(recordId);
    }
}
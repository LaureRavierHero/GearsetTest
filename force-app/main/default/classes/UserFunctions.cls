public with sharing class UserFunctions {
    public static Id createProfessionalPortalUserFromContact(Contact contact) {
        System.debug('HERE');
        User u = new User();

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Professional' LIMIT 1];
        String alias = (contact.FirstName.left(1)).toLowerCase() + (contact.LastName.left(4)).toLowerCase();
        

        u.ContactId = contact.Id;
        u.FirstName = contact.FirstName;
        u.LastName = contact.LastName;
        u.Email = contact.Email;
        u.Phone = contact.Phone;
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'nl_NL';
        u.LocaleSidKey = 'nl_NL';
        u.TimeZoneSidKey = 'Europe/Amsterdam';
        u.Username = contact.Email;
        u.ProfileId = p.Id;
        u.Alias = alias;

        System.debug(u);
        insert u;

        PermissionSetGroup permGroup = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'Professional_permissions' LIMIT 1];

        PermissionSetAssignment permissionAssignment = new PermissionSetAssignment();
        permissionAssignment.AssigneeId = u.Id;
        permissionAssignment.PermissionSetGroupId = permGroup.Id;

        insert permissionAssignment;

        return u.Id;
    }
}
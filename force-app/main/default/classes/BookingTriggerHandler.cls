/*
* Method : Calls from Booking Trigger After Update
* Name : K.Ragunath  
* Descripotion : This method created for Handler the trigger methods of Bookign Object
* Date : 25-11-2025.
* 
*/
public class BookingTriggerHandler {
  
    private static Boolean isRunning = false;
    
    public static void afterNocApproved(List<Booking__c> bookings) {
        
        if (isRunning) return;
        isRunning = true;
        
        createCustomerMaster(bookings);
        
        isRunning = false;
    }
    
    private static void createCustomerMaster(List<Booking__c> bkList){
        Map<String,Id> bookIdCustomerMasterMap = new Map<String,Id>();
        List<Customer_Master__c> createCustomerMasterList = new List<Customer_Master__c>();
        List<Booking__c> updatedBookingList = new List<Booking__c>();
        Map<Id,Id> bookIdCustomerMasterIdMap = new Map<Id,Id>();
        Map<String,Id> cmPhonetoIdMap = new Map<String,Id>();
        Map<Id,Customer_Master__c> cmMap = new Map<Id,Customer_Master__c>();
        Set<String> phoneSet = new Set<String>();
        List<Booking__c> availableBookingList = new List<Booking__c>();
        Set<Id> bookingIdsForMail = new Set<Id>(); //added by karthik 23-12-25
        Set<Id> bookingIdSet = new Set<Id>();
        
        Set<Id> LeadIds = new set<Id>();
        Map<String,Lead> LeadCmMap = new Map<String,Lead>();
        
        for(Booking__c bk : bkList){
            bookingIdSet.add(bk.Id);
            phoneSet.add(bk.Contact_Number__c);
            if(bk.Mobile_Number_2__c!=null)
            {
                phoneSet.add(bk.Mobile_Number_2__c);
            }
            
            if(bk.SLead__c != null)
                LeadIds.add(bk.SLead__c);
        }
        
        //Booking -> latest Customer Delight record (used for the CM lookup and the CM owner)
        Map<Id,Customer_Delight__c> bookingIdToCustomerDelightMap = new Map<Id,Customer_Delight__c>();
        Set<Id> customerDelightOwnerIds = new Set<Id>();
        for(Customer_Delight__c cd : [SELECT Id, Booking__c, OwnerId FROM Customer_Delight__c WHERE Booking__c IN :bookingIdSet ORDER BY CreatedDate DESC]){
            if(!bookingIdToCustomerDelightMap.containsKey(cd.Booking__c)){
                bookingIdToCustomerDelightMap.put(cd.Booking__c, cd);
                if(cd.OwnerId != null) customerDelightOwnerIds.add(cd.OwnerId);
            }
        }
        
        //Single user query: active CD record owners + round robin pool (least recently assigned first)
        Set<Id> activeCustomerDelightOwnerIds = new Set<Id>();
        List<User> customerDelightUsers = new List<User>();
        for(User userRec : [SELECT Id, IsActive, LastAssignmentTime1__c, Profile.Name FROM User WHERE Id IN :customerDelightOwnerIds OR (IsActive = true AND Profile.Name = 'Customer Delight') ORDER BY LastAssignmentTime1__c ASC NULLS FIRST]){
            if(userRec.IsActive && customerDelightOwnerIds.contains(userRec.Id)) activeCustomerDelightOwnerIds.add(userRec.Id);
            if(userRec.IsActive && userRec.Profile.Name == 'Customer Delight') customerDelightUsers.add(userRec);
        }
        Integer nextCustomerDelightIndex = 0;
        Map<Id,User> customerDelightUsersToUpdate = new Map<Id,User>();
        
        //To update referral points if any
        for(Lead rfLead : [SELECT Id, Customer_Master__c, Customer_Master__r.Loyality__c from Lead WHERE Id in: LeadIds and Customer_Master__c != null]){
            LeadCmMap.put(rfLead.Id, rfLead);
        }
        
        
        List<Customer_Master__c> cmList = [SELECT Id,Phone__c,Loyality__c FROM Customer_Master__c WHERE Phone__c IN :phoneSet];
        for(Customer_Master__c cm : cmList){
            cmPhonetoIdMap.put(cm.Phone__c, cm.Id);
            cmMap.put(cm.Id,cm);
        }
        
        Map<Id,Customer_Master__c> cmtoUpdate = new Map<Id,Customer_Master__c>();
        String lpLabel = System.Label.On_Registration_Loyalty_Points;
        String rfrlpLabel = System.Label.On_Refer_Loyalty_Points;
        
        for(Booking__c bk : bkList){
            if(cmPhonetoIdMap.containsKey(bk.Contact_Number__c) || cmPhonetoIdMap.containsKey(bk.Mobile_Number_2__c)){
                Booking__c bkRec = new Booking__c();
                bkRec.id = bk.id;
        
                 String lp ;
                if(cmPhonetoIdMap.containsKey(bk.Contact_Number__c))
                {
                    bkRec.Customer_Master__c = cmPhonetoIdMap.get(bk.Contact_Number__c);
                    lp = cmMap.get(cmPhonetoIdMap.get(bk.Contact_Number__c)).Loyality__c;
                }
                else{
                    bkRec.Customer_Master__c = cmPhonetoIdMap.get(bk.Mobile_Number_2__c);
                    lp = cmMap.get(cmPhonetoIdMap.get(bk.Mobile_Number_2__c)).Loyality__c;
                }
                
                if(cmtoUpdate.containskey(bkRec.Customer_Master__c)){
                    cmtoUpdate.get(bkRec.Customer_Master__c).Loyality__c = String.valueOf(Integer.valueOf(String.isBlank(cmtoUpdate.get(bkRec.Customer_Master__c).Loyality__c)? '0': cmtoUpdate.get(bkRec.Customer_Master__c).Loyality__c) + Integer.valueOf(lpLabel));

                }
                else{
                    Customer_Master__c cm = new Customer_Master__c();
                    cm.Id = bkRec.Customer_Master__c;
                    cm.Loyality__c = String.valueOf(Integer.valueOf(String.isBlank(lp) ? '0' : lp)+ Integer.valueOf(lpLabel));

                    cmtoUpdate.put(cm.Id,cm);
                }
                
                
                availableBookingList.add(bkRec);
                bookingIdsForMail.add(bk.Id);
            }
            else{
                
                Customer_Master__c cmRec = new Customer_Master__c();
                cmRec.Email__c = bk.Email__c;
                cmRec.Customer_Name__c = bk.First_Applicant_Name__c;
                cmRec.Member_Since__c = bk.Registration_Date__c;
                cmRec.Phone__c = bk.Contact_Number__c;
                cmRec.CRM_Executive__c = bk.OwnerId;
                cmRec.Loyality__c = lpLabel;
                cmRec.Member_Since__c = bk.Registration_Date__c;
                cmRec.isActive__c = true;
                
                //Customer Delight lookup + owner from the booking's Customer Delight record, else round robin
                Customer_Delight__c relatedCustomerDelight = bookingIdToCustomerDelightMap.get(bk.Id);
                Id customerMasterOwnerId = null;
                if(relatedCustomerDelight != null){
                    cmRec.Customer_Delight__c = relatedCustomerDelight.Id;
                    if(relatedCustomerDelight.OwnerId != null && activeCustomerDelightOwnerIds.contains(relatedCustomerDelight.OwnerId)){
                        customerMasterOwnerId = relatedCustomerDelight.OwnerId;
                    }
                }
                if(customerMasterOwnerId == null && !customerDelightUsers.isEmpty()){
                    User chosenUser = customerDelightUsers[Math.mod(nextCustomerDelightIndex, customerDelightUsers.size())];
                    nextCustomerDelightIndex++;
                    customerMasterOwnerId = chosenUser.Id;
                    customerDelightUsersToUpdate.put(chosenUser.Id, new User(Id = chosenUser.Id, LastAssignmentTime1__c = System.now().getTime()));
                }
                if(customerMasterOwnerId != null){
                    cmRec.OwnerId = customerMasterOwnerId;
                }
                
                // This used to copy the 4 phone number from the Customer Master record (implemented for Adissia One App)
               /*
                cmRec.First_Applicant_Phone_Number__c = bk.Contact_Number__c;
                cmRec.First_Applicant_Alternate_Number__c = bk.Mobile_Alternate__c;
                cmRec.Second_Applicant_Phone_Number__c = bk.Contact_Number1__c;
                cmRec.Second_Applicant_Alternate_Number__c = bk.Mobile_Alternate1__c;
                */
                createCustomerMasterList.add(cmRec);
                bookIdCustomerMasterMap.put(cmRec.Phone__c, bk.Id); 
            }
            
            //Referred Customer Master Loyalty Points
            if(LeadCmMap.containsKey(bk.SLead__c)){
                if(cmtoUpdate.containskey(LeadCmMap.get(bk.SLead__c).Customer_Master__c)){
                    cmtoUpdate.get(LeadCmMap.get(bk.SLead__c).Customer_Master__c).Loyality__c = String.valueOf(Integer.valueOf(String.isBlank(cmtoUpdate.get(LeadCmMap.get(bk.SLead__c).Customer_Master__c).Loyality__c) ? '0' : cmtoUpdate.get(LeadCmMap.get(bk.SLead__c).Customer_Master__c).Loyality__c) + Integer.valueOf(rfrlpLabel));

                }
                else{
                    Customer_Master__c cm = new Customer_Master__c();
                    cm.Id = LeadCmMap.get(bk.SLead__c).Customer_Master__c;
                    cm.Loyality__c = String.valueOf(Integer.valueOf(String.isBlank(LeadCmMap.get(bk.SLead__c).Customer_Master__r.Loyality__c) ? '0' : LeadCmMap.get(bk.SLead__c).Customer_Master__r.Loyality__c) + Integer.valueOf(rfrlpLabel));
                    cmtoUpdate.put(cm.Id,cm);
                }
            }
        }
        if(!createCustomerMasterList.isEmpty()){
            insert createCustomerMasterList;
        }
        
        if(!customerDelightUsersToUpdate.isEmpty()){
            update customerDelightUsersToUpdate.values();
        }
        
        if(!cmtoUpdate.values().isEmpty()){
            update cmtoUpdate.values();
        }
        
        //Customer Master -> Customer Delight Id map
        Map<Id,Id> customerMasterIdToCustomerDelightIdMap = new Map<Id,Id>();
        for(Customer_Master__c cm : createCustomerMasterList){
            if(cm.Customer_Delight__c != null){
                customerMasterIdToCustomerDelightIdMap.put(cm.Id, cm.Customer_Delight__c);
            }
        }
        System.debug('customerMasterIdToCustomerDelightIdMap---->'+customerMasterIdToCustomerDelightIdMap);
        
        for(Customer_Master__c cm: createCustomerMasterList){
            Id bookId = bookIdCustomerMasterMap.get(cm.Phone__c);
            bookIdCustomerMasterIdMap.put(bookId,cm.Id);
        }
        for(Id bookId : bookIdCustomerMasterIdMap.keySet()){
            Booking__c bk = new Booking__c(
                Id = bookId,
                Customer_Master__c = bookIdCustomerMasterIdMap.get(bookId)
            );
            updatedBookingList.add(bk);
            bookingIdsForMail.add(bookId);
        }
        System.debug('updatedBookingList---->'+updatedBookingList);
        if(!updatedBookingList.isEmpty()){
            update updatedBookingList;
        }
        if(!availableBookingList.isEmpty()){
            update availableBookingList;
        }
        
        //trigger mail
        sendCustomerMasterEmail(bookingIdsForMail);
        
        
    }
    
    private static void sendCustomerMasterEmail(Set<Id> bookingIds) {
        
        if (bookingIds == null || bookingIds.isEmpty()) return;
        
        List<OrgWideEmailAddress> lstEmailAddress=[select Id from OrgWideEmailAddress WHERE Address = 'support@adissia.com' limit 1];
        
        List<Booking__c> bookings = [SELECT Id, Email__c,Contact_Number__c,Customer_Master__c, Unit_NumberFor__c, Project__c,First_Applicant_Name__c, Customer_Master__r.Name FROM Booking__c WHERE Id IN :bookingIds];
        
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        
        String playStoreLink = System.Label.Adissia_PlayStore_Link;
        String appStoreLink  = System.Label.Adissia_AppStore_Link;
    Id orgWideEmailId = lstEmailAddress.isEmpty() ? null : lstEmailAddress[0].Id;
        
        for (Booking__c bk : bookings) {
            
            if (String.isBlank(bk.Email__c) || bk.Customer_Master__c == null) {
                continue;
            }
            
            String pltNo = bk.Unit_NumberFor__c;
            if (pltNo != null && pltNo.contains('-')) {
                pltNo = pltNo.substring(pltNo.indexOf('-') + 1);
            }

            //dynamic values
            String plotNo     = pltNo;
            String project    = bk.Project__c;
            String loginId    = bk.Customer_Master__r.Name;
            String regPhnNo   = bk.Contact_Number__c;
         
            String emailBody =
                '<html>' +
                '<body style="font-family: Arial, Helvetica, sans-serif; font-size:14px; color:#000;">' +
                
                '<p>Dear Sir / Madam,</p>' +
                
                '<p>Greetings from <b>Adissia!</b></p>' +
                
                '<p>' +
                'We are delighted to inform you that you have joined our Adissia Family and reserved your seat for a memorable journey ' +
                'on completion of your registration for <b>Plot No. ' + plotNo + '</b> in our prestigious project <b>' + project + '</b>.' +
                '</p>' +
                
                '<p>' +
                'We are glad to introduce you to our <b>Adissia One App</b>, which is going to add more value to our journey ahead ' +
                'with more &amp; more milestones &amp; touch points as one family.' +
                '</p>' +
                
                '<p><b>Please download the Adissia One App using the links below:</b></p>' +
                
                '<ul>' +
                '<li><a href="' + playStoreLink + '" target="_blank">Download from Play Store (Android)</a></li>' +
                '<li><a href="' + appStoreLink  + '" target="_blank">Download from App Store (iOS)</a></li>' +
                '</ul>' +
                
                '<p>' +
                'to reserve your dedicated page as part of our customer portal which will be your facilitating App going forward.' +
                '</p>' +
                
                '<p>' +
                '<b>Your login credentials shall be as follows:</b><br/>' +
                'Login ID: <b>' + loginId + '</b><br/>' +
                'Registered Mobile Number: <b>' + regPhnNo + '</b>' +
                '</p>' +
                
                '<p>' +
                'We are incredibly overwhelmed to have you part of our growing family and we also wish you a prosperous journey ahead ' +
                'with more &amp; more assets adding up to your entitlement.' +
                '</p>' +
                
                '<br/>' +
                
                '<p>' +
                'Regards,<br/>' +
                '<b>Adissia Team</b>' +
                '</p>' +
                
                '</body>' +
                '</html>';
            
            
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[]{ bk.Email__c });
            mail.setSubject('Welcome to Adissia – Customer Portal Access');
            mail.setHtmlBody(emailBody);
            if (orgWideEmailId != null) {
                mail.setOrgWideEmailAddressId(orgWideEmailId);
            }

            
            
            mails.add(mail);

            
        }
        
        if (!mails.isEmpty() && !Test.isRunningTest()) {
            Messaging.sendEmail(mails);
        }
    }
    

    public static void handleRegistrationDone(List<Booking__c> newList, Map<Id, Booking__c> oldMap) {
        List<Booking__c> qualifyingBookings = new List<Booking__c>();

        for (Booking__c bk : newList) {
            Booking__c oldBk = oldMap.get(bk.Id);
            Boolean registrationChanged = bk.Stage__c != oldBk.Stage__c;

            if (registrationChanged
                    && bk.Stage__c == 'Allocate to CD') {
                qualifyingBookings.add(bk);
            }
        }

        if (!qualifyingBookings.isEmpty()) {
            createCustomerDelightRecords(qualifyingBookings);
        }
    }
    private static void createCustomerDelightRecords(List<Booking__c> bookings) {
        Set<Id> bookingIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();
        for (Booking__c bk : bookings) {
            bookingIds.add(bk.Id);
            if (bk.SLead__c != null) leadIds.add(bk.SLead__c);
        }
    
        Set<Id> existingBookingIds = new Set<Id>();
        for (Customer_Delight__c cd : [SELECT Id, Booking__c FROM Customer_Delight__c WHERE Booking__c IN :bookingIds]) {
            existingBookingIds.add(cd.Booking__c);
        }
    
        // Lead -> Customer Delight owner already assigned for an earlier booking of the same lead
        Map<Id, Id> leadToExistingOwnerId = new Map<Id, Id>();
        Set<Id> existingOwnerIds = new Set<Id>();
        if (!leadIds.isEmpty()) {
            for (Customer_Delight__c cd : [SELECT Id, OwnerId, Booking__r.SLead__c FROM Customer_Delight__c WHERE Booking__r.SLead__c IN :leadIds AND OwnerId != null ORDER BY CreatedDate DESC]) {
                leadToExistingOwnerId.put(cd.Booking__r.SLead__c, cd.OwnerId);
                existingOwnerIds.add(cd.OwnerId);
            }
        }
    
        // Single user query: still-active existing owners + round robin pool (least recently assigned first)
        Set<Id> activeOwnerIds = new Set<Id>();
        List<User> candidates = new List<User>();
        for (User userRec : [SELECT Id, IsActive, LastAssignmentTime1__c, Profile.Name FROM User WHERE Id IN :existingOwnerIds OR (IsActive = true AND Profile.Name = 'Customer Delight') ORDER BY LastAssignmentTime1__c ASC NULLS FIRST]) {
            if (userRec.IsActive && userRec.Profile.Name == 'Customer Delight') {
                candidates.add(userRec);
                if (existingOwnerIds.contains(userRec.Id)) activeOwnerIds.add(userRec.Id);
            }
        }
        Integer nextCandidateIndex = 0;
        Map<Id, User> usersToUpdate = new Map<Id, User>();
    
        List<Customer_Delight__c> cdList = new List<Customer_Delight__c>();
    
        for (Booking__c bk : bookings) {
            if (existingBookingIds.contains(bk.Id)) {
                bk.addError('Already record available for this booking');
                continue;
            }
    
            Id assignedOwnerId = null;
            Id stickyOwnerId = (bk.SLead__c != null) ? leadToExistingOwnerId.get(bk.SLead__c) : null;
    
            if (stickyOwnerId != null && activeOwnerIds.contains(stickyOwnerId)) {
                assignedOwnerId = stickyOwnerId;
            } else if (!candidates.isEmpty()) {
                User chosenUser = candidates[Math.mod(nextCandidateIndex, candidates.size())];
                nextCandidateIndex++;
                assignedOwnerId = chosenUser.Id;
                usersToUpdate.put(chosenUser.Id, new User(Id = chosenUser.Id, LastAssignmentTime1__c = System.now().getTime()));
                // remember for the rest of this lead's bookings in the same transaction
                if (bk.SLead__c != null) {
                    leadToExistingOwnerId.put(bk.SLead__c, assignedOwnerId);
                    activeOwnerIds.add(assignedOwnerId);
                }
            }
    
            Customer_Delight__c cd = new Customer_Delight__c();
            cd.Booking__c = bk.Id;
            cd.Requested_By__c = bk.OwnerId;
            cd.Requested_DateTime__c = System.now();
            cd.OwnerId__c = assignedOwnerId;
            cd.OwnerId = assignedOwnerId;
            cd.Status__c = 'New';
            cdList.add(cd);
        }
    
        if (!cdList.isEmpty()) insert cdList;
        if (!usersToUpdate.isEmpty()) update usersToUpdate.values();
    }

    // Round robin based on LastAssignmentTime1__c (Time field) — nulls first (never assigned = highest priority)
    private static Id getLeastRecentlyAssignedUser() {
        List<User> candidates = [SELECT Id, LastAssignmentTime1__c FROM User WHERE IsActive = true AND Profile.Name = 'Customer Delight' ORDER BY LastAssignmentTime1__c ASC NULLS FIRST LIMIT 1];

        if (candidates.isEmpty()) return null;

        Id chosenUserId = candidates[0].Id;

        // Update their LastAssignmentTime1__c so next round robin moves to the next person
        User u = new User(Id = chosenUserId, LastAssignmentTime1__c = System.now().getTime());
        update u;

        return chosenUserId;
    }

    
}


// ========================================================================================================================



/*
* Method : Calls from Booking Trigger After Update
* Name : K.Ragunath
* Descripotion : This method created for Handler the trigger methods of Bookign Object
* Date : 25-11-2025.
*
* CHANGE (Customer Master consolidation — one master per lead):
*   createCustomerMaster is called only when Registration_Done__c goes
*   false -> true (the trigger already guarantees that). New behaviour:
*     1. Booking already HAS a Customer Master -> do nothing at all
*        (covers check/uncheck/re-check of the box).
*     2. Lead's earliest registered booking has a Customer Master
*        -> map the SAME master to this booking.
*     3. Lead has no master anywhere -> create a new Customer Master for
*        this booking, then map it to the lead's OTHER bookings that are at
*        'Registration' stage with no master. Other stages: left alone.
*   PHONE-NUMBER MATCHING IS REMOVED COMPLETELY.
*   Welcome email keeps going as before. Loyalty points: unchanged for the
*   registered booking; propagated sibling bookings get the mapping + email
*   only, no extra points.
*   Search "// CHANGED" / "// ADDED" for the changed parts; the rest of the
*   class is untouched.
*/
// public class BookingTriggerHandler {

//     // ADDED: bypass flag for data-fix scripts. Default false, so normal
//     // user activity is never affected. A cleanup script sets it true at the
//     // start of its run; it resets automatically when the run ends.
//     public static Boolean skipTrigger = false;

//     private static Boolean isRunning = false;

//     public static void afterNocApproved(List<Booking__c> bookings) {

//         if (isRunning) return;
//         isRunning = true;

//         createCustomerMaster(bookings);

//         isRunning = false;
//     }

//     private static void createCustomerMaster(List<Booking__c> bkList){
//         List<Customer_Master__c> createCustomerMasterList = new List<Customer_Master__c>();
//         List<Booking__c> createCmBookingList = new List<Booking__c>();   // ADDED: parallel to createCustomerMasterList (replaces the phone-key mapping)
//         List<Booking__c> deferredLeadBookingList = new List<Booking__c>(); // ADDED: same-run bookings waiting for a master created in this run
//         List<Booking__c> updatedBookingList = new List<Booking__c>();
//         Map<Id,Customer_Master__c> cmMap = new Map<Id,Customer_Master__c>();
//         List<Booking__c> availableBookingList = new List<Booking__c>();
//         Set<Id> bookingIdsForMail = new Set<Id>(); //added by karthik 23-12-25
//         Set<Id> bookingIdSet = new Set<Id>();

//         Set<Id> LeadIds = new set<Id>();
//         Map<String,Lead> LeadCmMap = new Map<String,Lead>();

//         for(Booking__c bk : bkList){
//             bookingIdSet.add(bk.Id);
//             if(bk.SLead__c != null)
//                 LeadIds.add(bk.SLead__c);
//         }

//         // ADDED: Lead -> Customer Master of its EARLIEST registered booking.
//         // This replaces phone matching as the way to find the right master.
//         Map<Id,Id> leadExistingCmMap = new Map<Id,Id>();
//         if(!LeadIds.isEmpty()){
//             for(Booking__c eb : [SELECT Id, SLead__c, Customer_Master__c
//                                  FROM Booking__c
//                                  WHERE SLead__c IN :LeadIds
//                                    AND Customer_Master__c != null
//                                    AND Stage__c = 'Registration'
//                                    AND Id NOT IN :bookingIdSet
//                                  ORDER BY CreatedDate ASC]){
//                 if(!leadExistingCmMap.containsKey(eb.SLead__c)){
//                     leadExistingCmMap.put(eb.SLead__c, eb.Customer_Master__c);
//                 }
//             }
//             if(!leadExistingCmMap.isEmpty()){
//                 for(Customer_Master__c cm : [SELECT Id,Phone__c,Loyality__c FROM Customer_Master__c WHERE Id IN :leadExistingCmMap.values()]){
//                     cmMap.put(cm.Id,cm);
//                 }
//             }
//         }
//         // ADDED ends

//         //Booking -> latest Customer Delight record (used for the CM lookup and the CM owner)
//         Map<Id,Customer_Delight__c> bookingIdToCustomerDelightMap = new Map<Id,Customer_Delight__c>();
//         Set<Id> customerDelightOwnerIds = new Set<Id>();
//         for(Customer_Delight__c cd : [SELECT Id, Booking__c, OwnerId FROM Customer_Delight__c WHERE Booking__c IN :bookingIdSet ORDER BY CreatedDate DESC]){
//             if(!bookingIdToCustomerDelightMap.containsKey(cd.Booking__c)){
//                 bookingIdToCustomerDelightMap.put(cd.Booking__c, cd);
//                 if(cd.OwnerId != null) customerDelightOwnerIds.add(cd.OwnerId);
//             }
//         }

//         //Single user query: active CD record owners + round robin pool (least recently assigned first)
//         Set<Id> activeCustomerDelightOwnerIds = new Set<Id>();
//         List<User> customerDelightUsers = new List<User>();
//         for(User userRec : [SELECT Id, IsActive, LastAssignmentTime1__c, Profile.Name FROM User WHERE Id IN :customerDelightOwnerIds OR (IsActive = true AND Profile.Name = 'Customer Delight') ORDER BY LastAssignmentTime1__c ASC NULLS FIRST]){
//             if(userRec.IsActive && customerDelightOwnerIds.contains(userRec.Id)) activeCustomerDelightOwnerIds.add(userRec.Id);
//             if(userRec.IsActive && userRec.Profile.Name == 'Customer Delight') customerDelightUsers.add(userRec);
//         }
//         Integer nextCustomerDelightIndex = 0;
//         Map<Id,User> customerDelightUsersToUpdate = new Map<Id,User>();

//         //To update referral points if any
//         for(Lead rfLead : [SELECT Id, Customer_Master__c, Customer_Master__r.Loyality__c from Lead WHERE Id in: LeadIds and Customer_Master__c != null]){
//             LeadCmMap.put(rfLead.Id, rfLead);
//         }

//         // CHANGED: the phone-number Customer Master query is REMOVED.

//         Map<Id,Customer_Master__c> cmtoUpdate = new Map<Id,Customer_Master__c>();
//         String lpLabel = System.Label.On_Registration_Loyalty_Points;
//         String rfrlpLabel = System.Label.On_Refer_Loyalty_Points;

//         // ADDED: lead -> position of the master created for it in this run
//         Map<Id,Integer> leadToNewCmIndex = new Map<Id,Integer>();

//         for(Booking__c bk : bkList){
//             // CHANGED: booking already has a Customer Master -> do nothing.
//             // Covers check / uncheck / re-check of Registration_Done__c.
//             if(bk.Customer_Master__c != null){
//                 continue;
//             }

//             // CHANGED: lead already has a master -> map the SAME master.
//             if(bk.SLead__c != null && leadExistingCmMap.containsKey(bk.SLead__c)){
//                 Booking__c bkRec = new Booking__c();
//                 bkRec.Id = bk.Id;
//                 bkRec.Customer_Master__c = leadExistingCmMap.get(bk.SLead__c);

//                 String lp = cmMap.containsKey(bkRec.Customer_Master__c) ? cmMap.get(bkRec.Customer_Master__c).Loyality__c : null;
//                 if(cmtoUpdate.containskey(bkRec.Customer_Master__c)){
//                     cmtoUpdate.get(bkRec.Customer_Master__c).Loyality__c = String.valueOf(Integer.valueOf(String.isBlank(cmtoUpdate.get(bkRec.Customer_Master__c).Loyality__c)? '0': cmtoUpdate.get(bkRec.Customer_Master__c).Loyality__c) + Integer.valueOf(lpLabel));
//                 }
//                 else{
//                     Customer_Master__c cm = new Customer_Master__c();
//                     cm.Id = bkRec.Customer_Master__c;
//                     cm.Loyality__c = String.valueOf(Integer.valueOf(String.isBlank(lp) ? '0' : lp)+ Integer.valueOf(lpLabel));
//                     cmtoUpdate.put(cm.Id,cm);
//                 }

//                 availableBookingList.add(bkRec);
//                 bookingIdsForMail.add(bk.Id);
//             }
//             // ADDED: a master for this lead is already being created in this
//             // same run (bulk case) -> map this booking to it after insert.
//             else if(bk.SLead__c != null && leadToNewCmIndex.containsKey(bk.SLead__c)){
//                 deferredLeadBookingList.add(bk);
//                 bookingIdsForMail.add(bk.Id);
//             }
//             // CHANGED: no master anywhere for this lead -> create a new one.
//             // (Phone matching removed — creation is the only other path.)
//             else{

//                 Customer_Master__c cmRec = new Customer_Master__c();
//                 cmRec.Email__c = bk.Email__c;
//                 cmRec.Customer_Name__c = bk.First_Applicant_Name__c;
//                 cmRec.Member_Since__c = bk.Registration_Date__c;
//                 cmRec.Phone__c = bk.Contact_Number__c;
//                 cmRec.CRM_Executive__c = bk.OwnerId;
//                 cmRec.Loyality__c = lpLabel;
//                 cmRec.Member_Since__c = bk.Registration_Date__c;
//                 cmRec.isActive__c = true;

//                 //Customer Delight lookup + owner from the booking's Customer Delight record, else round robin
//                 Customer_Delight__c relatedCustomerDelight = bookingIdToCustomerDelightMap.get(bk.Id);
//                 Id customerMasterOwnerId = null;
//                 if(relatedCustomerDelight != null){
//                     cmRec.Customer_Delight__c = relatedCustomerDelight.Id;
//                     if(relatedCustomerDelight.OwnerId != null && activeCustomerDelightOwnerIds.contains(relatedCustomerDelight.OwnerId)){
//                         customerMasterOwnerId = relatedCustomerDelight.OwnerId;
//                     }
//                 }
//                 if(customerMasterOwnerId == null && !customerDelightUsers.isEmpty()){
//                     User chosenUser = customerDelightUsers[Math.mod(nextCustomerDelightIndex, customerDelightUsers.size())];
//                     nextCustomerDelightIndex++;
//                     customerMasterOwnerId = chosenUser.Id;
//                     customerDelightUsersToUpdate.put(chosenUser.Id, new User(Id = chosenUser.Id, LastAssignmentTime1__c = System.now().getTime()));
//                 }
//                 if(customerMasterOwnerId != null){
//                     cmRec.OwnerId = customerMasterOwnerId;
//                 }

//                 // This used to copy the 4 phone number from the Customer Master record (implemented for Adissia One App)
//                /*
//                 cmRec.First_Applicant_Phone_Number__c = bk.Contact_Number__c;
//                 cmRec.First_Applicant_Alternate_Number__c = bk.Mobile_Alternate__c;
//                 cmRec.Second_Applicant_Phone_Number__c = bk.Contact_Number1__c;
//                 cmRec.Second_Applicant_Alternate_Number__c = bk.Mobile_Alternate1__c;
//                 */
//                 createCustomerMasterList.add(cmRec);
//                 createCmBookingList.add(bk); // ADDED: position-paired with cmRec (phone-key map removed)
//                 if(bk.SLead__c != null){
//                     leadToNewCmIndex.put(bk.SLead__c, createCustomerMasterList.size()-1); // ADDED
//                 }
//                 bookingIdsForMail.add(bk.Id);
//             }

//             //Referred Customer Master Loyalty Points
//             if(LeadCmMap.containsKey(bk.SLead__c)){
//                 if(cmtoUpdate.containskey(LeadCmMap.get(bk.SLead__c).Customer_Master__c)){
//                     cmtoUpdate.get(LeadCmMap.get(bk.SLead__c).Customer_Master__c).Loyality__c = String.valueOf(Integer.valueOf(String.isBlank(cmtoUpdate.get(LeadCmMap.get(bk.SLead__c).Customer_Master__c).Loyality__c) ? '0' : cmtoUpdate.get(LeadCmMap.get(bk.SLead__c).Customer_Master__c).Loyality__c) + Integer.valueOf(rfrlpLabel));

//                 }
//                 else{
//                     Customer_Master__c cm = new Customer_Master__c();
//                     cm.Id = LeadCmMap.get(bk.SLead__c).Customer_Master__c;
//                     cm.Loyality__c = String.valueOf(Integer.valueOf(String.isBlank(LeadCmMap.get(bk.SLead__c).Customer_Master__r.Loyality__c) ? '0' : LeadCmMap.get(bk.SLead__c).Customer_Master__r.Loyality__c) + Integer.valueOf(rfrlpLabel));
//                     cmtoUpdate.put(cm.Id,cm);
//                 }
//             }
//         }
//         if(!createCustomerMasterList.isEmpty()){
//             insert createCustomerMasterList;
//         }

//         if(!customerDelightUsersToUpdate.isEmpty()){
//             update customerDelightUsersToUpdate.values();
//         }

//         if(!cmtoUpdate.values().isEmpty()){
//             update cmtoUpdate.values();
//         }

//         //Customer Master -> Customer Delight Id map
//         Map<Id,Id> customerMasterIdToCustomerDelightIdMap = new Map<Id,Id>();
//         for(Customer_Master__c cm : createCustomerMasterList){
//             if(cm.Customer_Delight__c != null){
//                 customerMasterIdToCustomerDelightIdMap.put(cm.Id, cm.Customer_Delight__c);
//             }
//         }
//         System.debug('customerMasterIdToCustomerDelightIdMap---->'+customerMasterIdToCustomerDelightIdMap);

//         // CHANGED: created masters are mapped back to their bookings by
//         // LIST POSITION (createCmBookingList[i] <-> createCustomerMasterList[i]);
//         // the old phone-key mapping is removed.
//         Map<Id,Id> leadToNewCmId = new Map<Id,Id>(); // ADDED: for sibling propagation
//         for(Integer i = 0; i < createCustomerMasterList.size(); i++){
//             updatedBookingList.add(new Booking__c(
//                 Id = createCmBookingList[i].Id,
//                 Customer_Master__c = createCustomerMasterList[i].Id
//             ));
//             if(createCmBookingList[i].SLead__c != null){
//                 leadToNewCmId.put(createCmBookingList[i].SLead__c, createCustomerMasterList[i].Id);
//             }
//         }

//         // ADDED: same-run bookings of a lead whose master was just created
//         for(Booking__c dbk : deferredLeadBookingList){
//             if(leadToNewCmId.containsKey(dbk.SLead__c)){
//                 updatedBookingList.add(new Booking__c(
//                     Id = dbk.Id,
//                     Customer_Master__c = leadToNewCmId.get(dbk.SLead__c)
//                 ));
//             }
//         }

//         // ADDED: propagate each newly created master to the lead's OTHER
//         // bookings that are at 'Registration' stage with no master yet,
//         // and mark them Registration_Done__c = true as well so the process
//         // is not missed for them. Bookings at any other stage are left alone.
//         if(!leadToNewCmId.isEmpty()){
//             for(Booking__c sib : [SELECT Id, SLead__c
//                                   FROM Booking__c
//                                   WHERE SLead__c IN :leadToNewCmId.keySet()
//                                     AND Stage__c = 'Registration'
//                                     AND Customer_Master__c = null
//                                     AND Id NOT IN :bookingIdSet]){
//                 updatedBookingList.add(new Booking__c(
//                     Id = sib.Id,
//                     Customer_Master__c = leadToNewCmId.get(sib.SLead__c),
//                     Registration_Done__c = true
//                 ));
//                 bookingIdsForMail.add(sib.Id);
//             }
//         }
//         // ADDED ends

//         System.debug('updatedBookingList---->'+updatedBookingList);
//         if(!updatedBookingList.isEmpty()){
//             update updatedBookingList;
//         }
//         if(!availableBookingList.isEmpty()){
//             update availableBookingList;
//         }

//         //trigger mail
//         // CHANGED: welcome email to customers stopped as per requirement.
//         // To turn it back on, uncomment the line below.
//         // sendCustomerMasterEmail(bookingIdsForMail);


//     }

//     private static void sendCustomerMasterEmail(Set<Id> bookingIds) {

//         if (bookingIds == null || bookingIds.isEmpty()) return;

//         List<OrgWideEmailAddress> lstEmailAddress=[select Id from OrgWideEmailAddress WHERE Address = 'support@adissia.com' limit 1];

//         List<Booking__c> bookings = [SELECT Id, Email__c,Contact_Number__c,Customer_Master__c, Unit_NumberFor__c, Project__c,First_Applicant_Name__c, Customer_Master__r.Name FROM Booking__c WHERE Id IN :bookingIds];

//         List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

//         String playStoreLink = System.Label.Adissia_PlayStore_Link;
//         String appStoreLink  = System.Label.Adissia_AppStore_Link;
//     Id orgWideEmailId = lstEmailAddress.isEmpty() ? null : lstEmailAddress[0].Id;

//         for (Booking__c bk : bookings) {

//             if (String.isBlank(bk.Email__c) || bk.Customer_Master__c == null) {
//                 continue;
//             }

//             String pltNo = bk.Unit_NumberFor__c;
//             if (pltNo != null && pltNo.contains('-')) {
//                 pltNo = pltNo.substring(pltNo.indexOf('-') + 1);
//             }

//             //dynamic values
//             String plotNo     = pltNo;
//             String project    = bk.Project__c;
//             String loginId    = bk.Customer_Master__r.Name;
//             String regPhnNo   = bk.Contact_Number__c;

//             String emailBody =
//                 '<html>' +
//                 '<body style="font-family: Arial, Helvetica, sans-serif; font-size:14px; color:#000;">' +

//                 '<p>Dear Sir / Madam,</p>' +

//                 '<p>Greetings from <b>Adissia!</b></p>' +

//                 '<p>' +
//                 'We are delighted to inform you that you have joined our Adissia Family and reserved your seat for a memorable journey ' +
//                 'on completion of your registration for <b>Plot No. ' + plotNo + '</b> in our prestigious project <b>' + project + '</b>.' +
//                 '</p>' +

//                 '<p>' +
//                 'We are glad to introduce you to our <b>Adissia One App</b>, which is going to add more value to our journey ahead ' +
//                 'with more &amp; more milestones &amp; touch points as one family.' +
//                 '</p>' +

//                 '<p><b>Please download the Adissia One App using the links below:</b></p>' +

//                 '<ul>' +
//                 '<li><a href="' + playStoreLink + '" target="_blank">Download from Play Store (Android)</a></li>' +
//                 '<li><a href="' + appStoreLink  + '" target="_blank">Download from App Store (iOS)</a></li>' +
//                 '</ul>' +

//                 '<p>' +
//                 'to reserve your dedicated page as part of our customer portal which will be your facilitating App going forward.' +
//                 '</p>' +

//                 '<p>' +
//                 '<b>Your login credentials shall be as follows:</b><br/>' +
//                 'Login ID: <b>' + loginId + '</b><br/>' +
//                 'Registered Mobile Number: <b>' + regPhnNo + '</b>' +
//                 '</p>' +

//                 '<p>' +
//                 'We are incredibly overwhelmed to have you part of our growing family and we also wish you a prosperous journey ahead ' +
//                 'with more &amp; more assets adding up to your entitlement.' +
//                 '</p>' +

//                 '<br/>' +

//                 '<p>' +
//                 'Regards,<br/>' +
//                 '<b>Adissia Team</b>' +
//                 '</p>' +

//                 '</body>' +
//                 '</html>';



//             Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
//             mail.setToAddresses(new String[]{ bk.Email__c });
//             mail.setSubject('Welcome to Adissia – Customer Portal Access');
//             mail.setHtmlBody(emailBody);
//             if (orgWideEmailId != null) {
//                 mail.setOrgWideEmailAddressId(orgWideEmailId);
//             }



//             mails.add(mail);


//         }

//         if (!mails.isEmpty() && !Test.isRunningTest()) {
//             Messaging.sendEmail(mails);
//         }
//     }


//     public static void handleRegistrationDone(List<Booking__c> newList, Map<Id, Booking__c> oldMap) {
//         List<Booking__c> qualifyingBookings = new List<Booking__c>();

//         for (Booking__c bk : newList) {
//             Booking__c oldBk = oldMap.get(bk.Id);
//             Boolean registrationChanged = bk.Stage__c != oldBk.Stage__c;

//             if (registrationChanged
//                     && bk.Stage__c == 'Allocate to CD') {
//                 qualifyingBookings.add(bk);
//             }
//         }

//         if (!qualifyingBookings.isEmpty()) {
//             createCustomerDelightRecords(qualifyingBookings);
//         }
//     }
//     private static void createCustomerDelightRecords(List<Booking__c> bookings) {
//         Set<Id> bookingIds = new Set<Id>();
//         Set<Id> leadIds = new Set<Id>();
//         for (Booking__c bk : bookings) {
//             bookingIds.add(bk.Id);
//             if (bk.SLead__c != null) leadIds.add(bk.SLead__c);
//         }

//         Set<Id> existingBookingIds = new Set<Id>();
//         for (Customer_Delight__c cd : [SELECT Id, Booking__c FROM Customer_Delight__c WHERE Booking__c IN :bookingIds]) {
//             existingBookingIds.add(cd.Booking__c);
//         }

//         // Lead -> Customer Delight owner already assigned for an earlier booking of the same lead
//         Map<Id, Id> leadToExistingOwnerId = new Map<Id, Id>();
//         Set<Id> existingOwnerIds = new Set<Id>();
//         if (!leadIds.isEmpty()) {
//             for (Customer_Delight__c cd : [SELECT Id, OwnerId, Booking__r.SLead__c FROM Customer_Delight__c WHERE Booking__r.SLead__c IN :leadIds AND OwnerId != null ORDER BY CreatedDate DESC]) {
//                 leadToExistingOwnerId.put(cd.Booking__r.SLead__c, cd.OwnerId);
//                 existingOwnerIds.add(cd.OwnerId);
//             }
//         }

//         // Single user query: still-active existing owners + round robin pool (least recently assigned first)
//         Set<Id> activeOwnerIds = new Set<Id>();
//         List<User> candidates = new List<User>();
//         for (User userRec : [SELECT Id, IsActive, LastAssignmentTime1__c, Profile.Name FROM User WHERE Id IN :existingOwnerIds OR (IsActive = true AND Profile.Name = 'Customer Delight') ORDER BY LastAssignmentTime1__c ASC NULLS FIRST]) {
//             if (userRec.IsActive && userRec.Profile.Name == 'Customer Delight') {
//                 candidates.add(userRec);
//                 if (existingOwnerIds.contains(userRec.Id)) activeOwnerIds.add(userRec.Id);
//             }
//         }
//         Integer nextCandidateIndex = 0;
//         Map<Id, User> usersToUpdate = new Map<Id, User>();

//         List<Customer_Delight__c> cdList = new List<Customer_Delight__c>();

//         for (Booking__c bk : bookings) {
//             if (existingBookingIds.contains(bk.Id)) {
//                 bk.addError('Already record available for this booking');
//                 continue;
//             }

//             Id assignedOwnerId = null;
//             Id stickyOwnerId = (bk.SLead__c != null) ? leadToExistingOwnerId.get(bk.SLead__c) : null;

//             if (stickyOwnerId != null && activeOwnerIds.contains(stickyOwnerId)) {
//                 assignedOwnerId = stickyOwnerId;
//             } else if (!candidates.isEmpty()) {
//                 User chosenUser = candidates[Math.mod(nextCandidateIndex, candidates.size())];
//                 nextCandidateIndex++;
//                 assignedOwnerId = chosenUser.Id;
//                 usersToUpdate.put(chosenUser.Id, new User(Id = chosenUser.Id, LastAssignmentTime1__c = System.now().getTime()));
//                 // remember for the rest of this lead's bookings in the same transaction
//                 if (bk.SLead__c != null) {
//                     leadToExistingOwnerId.put(bk.SLead__c, assignedOwnerId);
//                     activeOwnerIds.add(assignedOwnerId);
//                 }
//             }

//             Customer_Delight__c cd = new Customer_Delight__c();
//             cd.Booking__c = bk.Id;
//             cd.Requested_By__c = bk.OwnerId;
//             cd.Requested_DateTime__c = System.now();
//             cd.OwnerId__c = assignedOwnerId;
//             cd.OwnerId = assignedOwnerId;
//             cd.Status__c = 'New';
//             cdList.add(cd);
//         }

//         if (!cdList.isEmpty()) insert cdList;
//         if (!usersToUpdate.isEmpty()) update usersToUpdate.values();
//     }

//     // Round robin based on LastAssignmentTime1__c (Time field) — nulls first (never assigned = highest priority)
//     private static Id getLeastRecentlyAssignedUser() {
//         List<User> candidates = [SELECT Id, LastAssignmentTime1__c FROM User WHERE IsActive = true AND Profile.Name = 'Customer Delight' ORDER BY LastAssignmentTime1__c ASC NULLS FIRST LIMIT 1];

//         if (candidates.isEmpty()) return null;

//         Id chosenUserId = candidates[0].Id;

//         // Update their LastAssignmentTime1__c so next round robin moves to the next person
//         User u = new User(Id = chosenUserId, LastAssignmentTime1__c = System.now().getTime());
//         update u;

//         return chosenUserId;
//     }


// }
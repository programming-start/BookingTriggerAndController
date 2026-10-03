// public class BookingController{
    
//         //Method to get Picklist Values
//         //Project Shown in Create Booking Button Lead by sathya 21-06-2026
//         @AuraEnabled
//         public static Map<String, String> getProjectNames(String LdId) {
//             Map<String, String> options = new Map<String, String>();
        
//             if (String.isBlank(ldId)) return options;
        
//             // Get NRI Sales Record Type ID
//             Id nriRecordTypeId = [
//                 SELECT Id 
//                 FROM RecordType 
//                 WHERE SObjectType = 'Lead' 
//                 AND DeveloperName = 'NRI_Sales' 
//                 LIMIT 1
//             ].Id;
        
//             Lead ld = [
//                 SELECT RecordTypeId,
//                        OwnerId,
//                        (SELECT Project__c 
//                         FROM Site_Visit__r
//                         WHERE Status__c = 'Completed'
//                         AND Project__c != null)
//                 FROM Lead
//                 WHERE Id = :ldId
//                 LIMIT 1
//             ];
        
//             // Check if owner is NRI user
//             Boolean isNRIUser = ![
//                 SELECT Id 
//                 FROM User 
//                 WHERE Id = :ld.OwnerId 
//                 AND Is_NRI_User__c = true
//             ].isEmpty();
        
//             Boolean isNRI = ld.RecordTypeId == nriRecordTypeId && isNRIUser;
        
//             if (isNRI) {
//                 for (Project__c prj : [
//                     SELECT Name
//                     FROM Project__c
//                     WHERE Active__c = true
//                     AND Name != null
//                     ORDER BY Name
//                 ]) {
//                     options.put(prj.Name, prj.Name);
//                 }
//             } else {
//                 for (Site_Visit__c sv : ld.Site_Visit__r) {
//                     if (String.isNotBlank(sv.Project__c)) {
//                         options.put(sv.Project__c, sv.Project__c);
//                     }
//                 }
//             }
        
//             return options;
//         }
//         //Project Shown in Create Booking Button Lead by sathya 21-06-2026-- End    
//         //Method to get the project Id
//         @AuraEnabled
//         public static Project__c getProjectId(String projectName){
//             Project__c prj = [select Id,name,CRM_Manager__c,Finance_User__c from Project__c where Project__c =:projectName LIMIT 1];
//             return prj;
//         }
//         //Method to get lead details
//          @AuraEnabled
//         public static Lead getLeadDetails(Id recId){
//             Lead ld = [select Id,Name,Allocated_Project__c from Lead where Id =: recId];
//             return ld;
//         }
        
//         @AuraEnabled
//         public static Plot__c getPlotAllDetails(Id recId){
//             Plot__c plt = [select id,name,Basic_Price__c,Booking_Amount__c,Booking_Amnt_EWS__c,Total_Cost__c,Status__c,Plot_Area_in_Cent__c,Unit_Facing_Direction__c,Corner__c,Plot_Land_Area__c,EWS_Plot__c from Plot__c where Id=: recId];
//             return plt;
//         }
        
//         //Method to fetch All the Available units from a particular project
//         @AuraEnabled
//         public static List<Plot__c> getAllAvailablePlots(Id recId){
//             List<Lead> ldList = [select id,name,Allocated_Project__c from Lead where Id =: recId];
//             String ProjectName = ldList[0].Allocated_Project__c;
//             List<Plot__c> plotList = [select Id,Name,Project__c,Project__r.Name,Unit_Facing_Direction__c,Total_Cost__c,Total__c,Corner__c,Basic_Price__c,North_By__c,West_By__c,East_By__c,South_By__c,Plot_Land_Area__c from Plot__c where Project__r.Project__c =:ProjectName and Status__c = 'Available'];
//             return plotList;
//         }
    
//     //Method to get respective unit details
//     @AuraEnabled
//     public static List<Plot__c> getPlotDetails(Id recId){
//         List<Plot__c> qt = [SELECT Id,Name,Unit_Facing_Direction__c,Total_Cost__c,Project__r.Name,Corner__c,Total__c,Basic_Price__c,North_By__c,West_By__c,East_By__c,South_By__c,Plot_Land_Area__c FROM Plot__c WHERE Id=:recId];
//         return qt;
//     }

//     //Method to chage the Unit Status on Booking Stage Change
//     @AuraEnabled
//     public static void changeUnitStatus(Map<Id,String> plotIds){
//         List<Plot__c> plotList = [Select Id,Name,Status__c from Plot__c where Id in: plotIds.keySet()];
//         for(Plot__c plt : plotList){
//             plt.Status__c = plotIds.get(plt.Id);
//         }
//         update plotList;
//     }
    
//     public static void bookingCancellations(Set<Id> leadIds){
//         List<Lead> leadList = [Select id,name,Lead_Status__c from Lead where Id in: leadIds];
//         for(Lead ld : leadList){
//             ld.Lead_Status__c = 'Booked';
//         }
//         Update leadList;
//     }
    
//     public static void changeLeadStatus(Set<Id> leadIds){
//         List<Lead> leadList = [Select id,name,Lead_Status__c from Lead where Id in: leadIds];
//         for(Lead ld : leadList){
//             ld.Lead_Status__c = 'Booked';
//         }
//         Update leadList;
//     }
    
//     public static void sendCustomNotification(Set<String> recepientIds, String Title, String Body, String recId, String notificationName){
//         CustomNotificationType closedWonNotification = [SELECT Id,DeveloperName FROM CustomNotificationType WHERE DeveloperName =: notificationName LIMIT 1]; 
        
//         Set<String> rectIds = new Set<String>();
        
//         for(User us : [SELECT Id, IsActive FROM User WHERE Id in: recepientIds and IsActive = true]){
//             rectIds.add(us.Id);
//         }
        
        
//         Messaging.CustomNotification Notification = new Messaging.CustomNotification(); 
//         Notification.setNotificationTypeId(closedWonNotification.id); 
//         Notification.setSenderId(Userinfo.getUserId()); 
//         Notification.setBody(Body); 
//         Notification.setTitle(Title); 
//         Notification.setTargetId(recId); 
//         //Notification.send(recepientIds);
//         Notification.send(rectIds);
//     }
    
//     public static Set<String> getUserIdsFromGroup(String groupName) {
//         Set<Id> userIdSet  = new Set<Id>();
//         Set<String> userStringIds = new Set<String>();
        
//         // Get Group Id by name
//         Group g = [SELECT Id FROM Group WHERE Name = :groupName AND Type = 'Regular' LIMIT 1];
        
//         // Get Group Members
//         for (GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :g.Id])
//         {
//             userIdSet.add(gm.UserOrGroupId);
//         }
        
//         // Filter only active users
//         Map<Id, User> activeUsers = new Map<Id, User>([SELECT Id FROM User WHERE Id IN :userIdSet AND IsActive = true]);

//         // Convert to String ids
//         for (Id uid : activeUsers.keySet()) {
//             userStringIds.add((String) uid);
//         }
        
//         return userStringIds;
//     }

    
//     //Method to save the booking details
//     @AuraEnabled
//     public static Id saveBooking(Booking__c oppPlot){
//         if(oppPlot !=null){
//             List<User> uList = new List<User>();
//             List<Round_Robin__c> RRAvaliablequeList=[Select Id,Project_Assigned__c, (select Name,User__c from  Round_Robin_Members__r  where Active__c =true and User_Type__c = 'Post Sales'  order by Last_Assigned_time_user__c,createddate asc nulls first limit 1) from Round_Robin__c where Project_Assigned__c =: oppPlot.Project__c and Active__c = true ];
//             List<Project__c> proJectList = [select Id,Name,CRM_Manager__c,Finance_User__c from Project__c where Project__c =:oppPlot.Project__c ];
//            /* if(RRAvaliablequeList.size()>0){
//                 for(Round_Robin__c rr : RRAvaliablequeList){
//                     if(rr.Round_Robin_Members__r.size()>0){
//                         oppPlot.OwnerId = rr.Round_Robin_Members__r[0].User__c;
//                         User u = new User();
//                         u.Id = rr.Round_Robin_Members__r[0].User__c;
//                         u.LastAssignmentTime1__c = system.now().getTime(); 
//                         uList.add(u);
//                     }
                    
//                 }
//             }
//             else{
//                 oppPlot.OwnerId = proJectList[0].CRM_Manager__c;
//             }
//             oppPlot.Sales_User__c = UserInfo.getUserId();
//             oppPlot.CRM_Manager__c = proJectList[0].CRM_Manager__c;
//             oppPlot.Finance_User__c = proJectList[0].Finance_User__c;*/
//             insert oppPlot;
//             //update uList;
//             return oppPlot.Id;
//         }
//         else{
//             return null;
//         }
        
//     }
    
//     public static void sendWelcomeMail(Booking__c book){
        
//     }
    
//     public static void bookingAmountReceipt(Booking__c booking){ 
        
//         Receipt__c recp = new Receipt__c();
//         recp.Booking__c = booking.Id;
//         recp.Receipt_Name__c = 'Booking Amount Receipt';
//         recp.Remarks__c = 'Receipt for the Booking Amount. Auto Generated by system';
//         insert recp;
        
//         if(recp.Id != null){
//             Receipt_Line_Item__c rli = new Receipt_Line_Item__c();
//             //rli.Name = 'Booking Amount';
//             rli.Cheque_no_Transaction_Number__c = booking.Cheque_DD_NEFT_RTGS_No__c;
//             rli.Receipt__c = recp.Id;
//             rli.Booking__c = booking.Id;
//             rli.Amount__c = booking.Booking_Amount__c;
            
//             insert rli;
//         }
//     }
    
//     @auraEnabled
//     public static string getpageName(string recId){
//          string vfpageName;
//         Booking__c book = [SELECT Id,Name,Project__c FROM Booking__c where Id=:recId];
//         if(book.Project__c=='Bellezea'){
//             vfpageName ='GenerateBellezea';
//         }else if(book.Project__c=='Ellegenza'){
//             vfpageName ='GenerateEllegenzaPdf';
//         }else if(book.Project__c=='Millenia'){
//             vfpageName='GenerateMillenia';
//         }
//         return vfpageName;
//     }

//     public static void sendCancellationApproval(string recId){
//         Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
//         req1.setComments('Booking Cancellation Approval request');
//         req1.setObjectId(recId);
//         req1.setSubmitterId(userInfo.getUserId());
//         req1.setProcessDefinitionNameOrId('Booking_Cancellation_Approval');
//         req1.setSkipEntryCriteria(true);
//         Approval.ProcessResult result = Approval.process(req1);
//     }
//     @auraEnabled
//     public static void sendEmailtoCustomer(string recId){
//         string recordId = recId;
//         Booking__c l = [SELECT Id,CRM_Manager__r.Email,Owner.Email,Name,Email__C,Email1__c,SLead__r.Email,Project__c,First_Applicant_Name__c FROM Booking__c where Id=:recId];
//         List<String> lstCCEmail = new List<String>();
//         if(l.Email__C != null && l.Email__C != ''){
//             lstCCEmail = l.Email__C.split(',');
//         }
//         if (l.Email1__c != null && l.Email1__c != ''){
//             lstCCEmail.addAll(l.Email1__c.split(','));
//         }
//         lstCCEmail.add(l.Owner.Email);
//         if(l.CRM_Manager__c != null){
//             lstCCEmail.add(l.CRM_Manager__r.Email);
//         }

//         list<Messaging.SingleEmailMessage> mails = new list<Messaging.SingleEmailMessage>(); 
//         PageReference pdfPage;
//         pdfPage= page.BookingForm;
//         pdfPage.getParameters().put('Id', recordId);
//         Blob pdfContent;
//         Boolean isTest = System.Test.isRunningTest();
//         if(!isTest){
//             pdfContent = pdfPage.getContent();
//         }else{
//             pdfContent=Blob.valueOf('Test Content');
//         }
//         String accountName = l.Name != null ? l.Name : '';
       
//         List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
//         Messaging.Emailfileattachment efa1 = new Messaging.Emailfileattachment();
//         efa1.setFileName('Application form for '+ accountName+' | #'+system.today().year()+'-'+System.now().format('MMM')+'-'+system.today().day()+'-'+l.name+'.Pdf');
//         efa1.setBody(pdfContent);
//         fileAttachments.add(efa1);
        
//         if(l.Email__C != null && l.Email__C != ''){
//             List<String> lstBCCEmail = l.Email__C != null ? l.Email__C.split(',') : new List<String>();
//             Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
//             mail.toAddresses = new string[]{l.SLead__r.Email};
//                 mail.bccaddresses = lstBCCEmail;
//             mail.ccaddresses = lstCCEmail;
//             mail.setSubject('Application form for '+ accountName+' | #'+system.today().year()+'-'+System.now().format('MMM')+'-'+system.today().day()+'-'+l.name);
//             mail.setFileAttachments(fileAttachments);
            
//             string emailBody='Dear '+l.First_Applicant_Name__c+',<br/>Please find the attached Application Form Letter.<br/><br/>' +
//             'We are pleased to inform you that your booking has been confirmed. ' +
//             'Attached is the Application form for your reference.<br/><br/>' +
//             'If you have any questions or need further assistance, please contact us.<br/><br/>' +
//             'Thank you for choosing NAMBIAR Builders.<br/><br/>' +
//             'Best regards,<br/>' +
//             'NAMBIAR Builders Pvt Ltd';
// 			mail.setHtmlBody(emailBody);
//             mails.add(mail);
//         }
//         Messaging.SendEmailResult[] results = new list<Messaging.SendEmailResult>();
//         if(!isTest){
//             results = Messaging.sendEmail(mails); 
//             system.debug(results);
           
//         }
//     }
    
//     public static void validateRequiredDocuments(Map<Id, Booking__c> bookingMap) {
//         // Map of suffix patterns to display names
//         Map<String, String> documentTypes = new Map<String, String>{
//             ' - [ Aadhar Card ]' => 'Aadhar Card',
//                 ' - [ Pan Card ]' => 'Pan Card',
//                 ' - [ Sale Agreement ]' => 'Sale Agreement',
//                 ' - [ Sale Deed Token ]' => 'Sale Deed Token',
//                 ' - [ Sale Deed Fee Challan ]' => 'Sale Deed Fee Challan',
//                 ' - [ Sale Deed ]' => 'Sale Deed',
//                 ' - [ Loan Sanction Letter ]' => 'Loan Sanction Letter'
//                 };
                    
//                     // Core required documents (without loan document)
//                     Set<String> requiredSuffixes = new Set<String>{
//                         ' - [ Aadhar Card ]',
//                             ' - [ Pan Card ]',
//                             ' - [ Sale Agreement ]',
//                             ' - [ Sale Deed Token ]',
//                             ' - [ Sale Deed Fee Challan ]',
//                             ' - [ Sale Deed ]'
//                             };
                                
//                                 // Query all documents
//                                 Map<Id, Set<String>> bookingToSuffixesMap = new Map<Id, Set<String>>();
//         for(ContentDocumentLink link : [
//             SELECT LinkedEntityId, ContentDocument.Title 
//             FROM ContentDocumentLink 
//             WHERE LinkedEntityId IN :bookingMap.keySet()
//         ]) {
//             if(!bookingToSuffixesMap.containsKey(link.LinkedEntityId)) {
//                 bookingToSuffixesMap.put(link.LinkedEntityId, new Set<String>());
//             }
            
//             // Check all possible document types
//             for(String suffix : documentTypes.keySet()) {
//                 if(link.ContentDocument.Title.endsWith(suffix)) {
//                     bookingToSuffixesMap.get(link.LinkedEntityId).add(suffix);
//                 }
//             }
//         }
        
//         // Validate each booking
//         for(Id bookingId : bookingMap.keySet()) {
//             Booking__c book = bookingMap.get(bookingId);
//             Set<String> requiredForThisBooking = new Set<String>(requiredSuffixes);
            
//             // Add loan document if needed
//             if(book.Funding_Type__c == 'Loan') {
//                 requiredForThisBooking.add(' - [ Loan Sanction Letter ]');
//             }
            
//             // Find missing documents
//             Set<String> missing = new Set<String>();
//             for(String suffix : requiredForThisBooking) {
//                 if(!bookingToSuffixesMap.containsKey(bookingId) || 
//                    !bookingToSuffixesMap.get(bookingId).contains(suffix)) {
//                        missing.add(documentTypes.get(suffix));
//                    }
//             }
            
//             // Show error if any missing
//             if(!missing.isEmpty()) {
//                 String errorMsg = 'Upload missing documents: ' + String.join(new List<String>(missing), ', ');
//                 book.addError(errorMsg);
//             }
//         }
//     }
    
//     @AuraEnabled(cacheable=true)
//     public static Boolean checkIfDashboardExists(String dashName) {
//         // Query the ApexPage object to check if the dashboard exists
//         List<ApexPage> pages = [SELECT Id, Name FROM ApexPage WHERE Name = :dashName LIMIT 1];
//         return !pages.isEmpty();
//     }
//     @AuraEnabled
//     public static void uploadPaymentScheduleFile(Id bookingId, String fileName, String base64Data){
//         ContentVersion contentVersion = new ContentVersion();
//         contentVersion.Title = 'Payment Schedule Form - ' + fileName;
//         contentVersion.PathOnClient = fileName;
//         contentVersion.VersionData = EncodingUtil.base64Decode(base64Data);
//         contentVersion.FirstPublishLocationId = bookingId;
//         insert contentVersion;
//     }
    
// }



// ===================================================================================================================================================
// ==========================================================Added by Sivam V =========================================================================


// public class BookingController{
    
//         //Method to get Picklist Values
//         //Project Shown in Create Booking Button Lead by sathya 21-06-2026
//         @AuraEnabled
//         public static Map<String, String> getProjectNames(String LdId) {
//             Map<String, String> options = new Map<String, String>();
        
//             if (String.isBlank(ldId)) return options;
        
//             // Get NRI Sales Record Type ID
//             Id nriRecordTypeId = [
//                 SELECT Id 
//                 FROM RecordType 
//                 WHERE SObjectType = 'Lead' 
//                 AND DeveloperName = 'NRI_Sales' 
//                 LIMIT 1
//             ].Id;
        
//             Lead ld = [
//                 SELECT RecordTypeId,
//                        OwnerId,
//                        (SELECT Project__c 
//                         FROM Site_Visit__r
//                         WHERE Status__c = 'Completed'
//                         AND Project__c != null)
//                 FROM Lead
//                 WHERE Id = :ldId
//                 LIMIT 1
//             ];
        
//             // Check if owner is NRI user
//             Boolean isNRIUser = ![
//                 SELECT Id 
//                 FROM User 
//                 WHERE Id = :ld.OwnerId 
//                 AND Is_NRI_User__c = true
//             ].isEmpty();
        
//             Boolean isNRI = ld.RecordTypeId == nriRecordTypeId && isNRIUser;
        
//             if (isNRI) {
//                 for (Project__c prj : [
//                     SELECT Name
//                     FROM Project__c
//                     WHERE Active__c = true
//                     AND Name != null
//                     ORDER BY Name
//                 ]) {
//                     options.put(prj.Name, prj.Name);
//                 }
//             } else {
//                 for (Site_Visit__c sv : ld.Site_Visit__r) {
//                     if (String.isNotBlank(sv.Project__c)) {
//                         options.put(sv.Project__c, sv.Project__c);
//                     }
//                 }
//             }
        
//             return options;
//         }
//         //Project Shown in Create Booking Button Lead by sathya 21-06-2026-- End    
//         //Method to get the project Id
//         @AuraEnabled
//         public static Project__c getProjectId(String projectName){
//             Project__c prj = [select Id,name,CRM_Manager__c,Finance_User__c from Project__c where Project__c =:projectName LIMIT 1];
//             return prj;
//         }
//         //Method to get lead details
//          @AuraEnabled
//         public static Lead getLeadDetails(Id recId){
//             Lead ld = [select Id,Name,Allocated_Project__c from Lead where Id =: recId];
//             return ld;
//         }
        
//         @AuraEnabled
//         public static Plot__c getPlotAllDetails(Id recId){
//             Plot__c plt = [select id,name,Basic_Price__c,Booking_Amount__c,Booking_Amnt_EWS__c,Total_Cost__c,Status__c,Plot_Area_in_Cent__c,Unit_Facing_Direction__c,Corner__c,Plot_Land_Area__c,EWS_Plot__c from Plot__c where Id=: recId];
//             return plt;
//         }
        
//         //Method to fetch All the Available units from a particular project
//         @AuraEnabled
//         public static List<Plot__c> getAllAvailablePlots(Id recId){
//             List<Lead> ldList = [select id,name,Allocated_Project__c from Lead where Id =: recId];
//             String ProjectName = ldList[0].Allocated_Project__c;
//             List<Plot__c> plotList = [select Id,Name,Project__c,Project__r.Name,Unit_Facing_Direction__c,Total_Cost__c,Total__c,Corner__c,Basic_Price__c,North_By__c,West_By__c,East_By__c,South_By__c,Plot_Land_Area__c from Plot__c where Project__r.Project__c =:ProjectName and Status__c = 'Available'];
//             return plotList;
//         }
    
//     //Method to get respective unit details
//     @AuraEnabled
//     public static List<Plot__c> getPlotDetails(Id recId){
//         List<Plot__c> qt = [SELECT Id,Name,Unit_Facing_Direction__c,Total_Cost__c,Project__r.Name,Corner__c,Total__c,Basic_Price__c,North_By__c,West_By__c,East_By__c,South_By__c,Plot_Land_Area__c FROM Plot__c WHERE Id=:recId];
//         return qt;
//     }

//     //Method to chage the Unit Status on Booking Stage Change
//     @AuraEnabled
//     public static void changeUnitStatus(Map<Id,String> plotIds){
//         List<Plot__c> plotList = [Select Id,Name,Status__c from Plot__c where Id in: plotIds.keySet()];
//         for(Plot__c plt : plotList){
//             plt.Status__c = plotIds.get(plt.Id);
//         }
//         update plotList;
//     }
    
//     public static void bookingCancellations(Set<Id> leadIds){
//         List<Lead> leadList = [Select id,name,Lead_Status__c from Lead where Id in: leadIds];
//         for(Lead ld : leadList){
//             ld.Lead_Status__c = 'Booked';
//         }
//         Update leadList;
//     }
    
//     public static void changeLeadStatus(Set<Id> leadIds){
//         List<Lead> leadList = [Select id,name,Lead_Status__c from Lead where Id in: leadIds];
//         for(Lead ld : leadList){
//             ld.Lead_Status__c = 'Booked';
//         }
//         Update leadList;
//     }
    
//     public static void sendCustomNotification(Set<String> recepientIds, String Title, String Body, String recId, String notificationName){
//         CustomNotificationType closedWonNotification = [SELECT Id,DeveloperName FROM CustomNotificationType WHERE DeveloperName =: notificationName LIMIT 1]; 
        
//         Set<String> rectIds = new Set<String>();
        
//         for(User us : [SELECT Id, IsActive FROM User WHERE Id in: recepientIds and IsActive = true]){
//             rectIds.add(us.Id);
//         }
        
        
//         Messaging.CustomNotification Notification = new Messaging.CustomNotification(); 
//         Notification.setNotificationTypeId(closedWonNotification.id); 
//         Notification.setSenderId(Userinfo.getUserId()); 
//         Notification.setBody(Body); 
//         Notification.setTitle(Title); 
//         Notification.setTargetId(recId); 
//         //Notification.send(recepientIds);
//         Notification.send(rectIds);
//     }
    
//     public static Set<String> getUserIdsFromGroup(String groupName) {
//         Set<Id> userIdSet  = new Set<Id>();
//         Set<String> userStringIds = new Set<String>();
        
//         // Get Group Id by name
//         Group g = [SELECT Id FROM Group WHERE Name = :groupName AND Type = 'Regular' LIMIT 1];
        
//         // Get Group Members
//         for (GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :g.Id])
//         {
//             userIdSet.add(gm.UserOrGroupId);
//         }
        
//         // Filter only active users
//         Map<Id, User> activeUsers = new Map<Id, User>([SELECT Id FROM User WHERE Id IN :userIdSet AND IsActive = true]);

//         // Convert to String ids
//         for (Id uid : activeUsers.keySet()) {
//             userStringIds.add((String) uid);
//         }
        
//         return userStringIds;
//     }

    
//     //Method to save the booking details
//     @AuraEnabled
//     public static Id saveBooking(Booking__c oppPlot){
//         if(oppPlot !=null){
//             List<User> uList = new List<User>();
//             List<Round_Robin__c> RRAvaliablequeList=[Select Id,Project_Assigned__c, (select Name,User__c from  Round_Robin_Members__r  where Active__c =true and User_Type__c = 'Post Sales'  order by Last_Assigned_time_user__c,createddate asc nulls first limit 1) from Round_Robin__c where Project_Assigned__c =: oppPlot.Project__c and Active__c = true ];
//             List<Project__c> proJectList = [select Id,Name,CRM_Manager__c,Finance_User__c from Project__c where Project__c =:oppPlot.Project__c ];
//            /* if(RRAvaliablequeList.size()>0){
//                 for(Round_Robin__c rr : RRAvaliablequeList){
//                     if(rr.Round_Robin_Members__r.size()>0){
//                         oppPlot.OwnerId = rr.Round_Robin_Members__r[0].User__c;
//                         User u = new User();
//                         u.Id = rr.Round_Robin_Members__r[0].User__c;
//                         u.LastAssignmentTime1__c = system.now().getTime(); 
//                         uList.add(u);
//                     }
                    
//                 }
//             }
//             else{
//                 oppPlot.OwnerId = proJectList[0].CRM_Manager__c;
//             }
//             oppPlot.Sales_User__c = UserInfo.getUserId();
//             oppPlot.CRM_Manager__c = proJectList[0].CRM_Manager__c;
//             oppPlot.Finance_User__c = proJectList[0].Finance_User__c;*/
//             insert oppPlot;
//             //update uList;
//             return oppPlot.Id;
//         }
//         else{
//             return null;
//         }
        
//     }
    
//     public static void sendWelcomeMail(Booking__c book){
        
//     }
    
//     public static void bookingAmountReceipt(Booking__c booking){ 
        
//         Receipt__c recp = new Receipt__c();
//         recp.Booking__c = booking.Id;
//         recp.Receipt_Name__c = 'Booking Amount Receipt';
//         recp.Remarks__c = 'Receipt for the Booking Amount. Auto Generated by system';
//         insert recp;
        
//         if(recp.Id != null){
//             Receipt_Line_Item__c rli = new Receipt_Line_Item__c();
//             //rli.Name = 'Booking Amount';
//             rli.Cheque_no_Transaction_Number__c = booking.Cheque_DD_NEFT_RTGS_No__c;
//             rli.Receipt__c = recp.Id;
//             rli.Booking__c = booking.Id;
//             rli.Amount__c = booking.Booking_Amount__c;
            
//             insert rli;
//         }
//     }
    
//     @auraEnabled
//     public static string getpageName(string recId){
//          string vfpageName;
//         Booking__c book = [SELECT Id,Name,Project__c FROM Booking__c where Id=:recId];
//         if(book.Project__c=='Bellezea'){
//             vfpageName ='GenerateBellezea';
//         }else if(book.Project__c=='Ellegenza'){
//             vfpageName ='GenerateEllegenzaPdf';
//         }else if(book.Project__c=='Millenia'){
//             vfpageName='GenerateMillenia';
//         }
//         return vfpageName;
//     }

//     public static void sendCancellationApproval(string recId){
//         Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
//         req1.setComments('Booking Cancellation Approval request');
//         req1.setObjectId(recId);
//         req1.setSubmitterId(userInfo.getUserId());
//         req1.setProcessDefinitionNameOrId('Booking_Cancellation_Approval');
//         req1.setSkipEntryCriteria(true);
//         Approval.ProcessResult result = Approval.process(req1);
//     }
//     @auraEnabled
//     public static void sendEmailtoCustomer(string recId){
//         string recordId = recId;
//         Booking__c l = [SELECT Id,CRM_Manager__r.Email,Owner.Email,Name,Email__C,Email1__c,SLead__r.Email,Project__c,First_Applicant_Name__c FROM Booking__c where Id=:recId];
//         List<String> lstCCEmail = new List<String>();
//         if(l.Email__C != null && l.Email__C != ''){
//             lstCCEmail = l.Email__C.split(',');
//         }
//         if (l.Email1__c != null && l.Email1__c != ''){
//             lstCCEmail.addAll(l.Email1__c.split(','));
//         }
//         lstCCEmail.add(l.Owner.Email);
//         if(l.CRM_Manager__c != null){
//             lstCCEmail.add(l.CRM_Manager__r.Email);
//         }

//         list<Messaging.SingleEmailMessage> mails = new list<Messaging.SingleEmailMessage>(); 
//         PageReference pdfPage;
//         pdfPage= page.BookingForm;
//         pdfPage.getParameters().put('Id', recordId);
//         Blob pdfContent;
//         Boolean isTest = System.Test.isRunningTest();
//         if(!isTest){
//             pdfContent = pdfPage.getContent();
//         }else{
//             pdfContent=Blob.valueOf('Test Content');
//         }
//         String accountName = l.Name != null ? l.Name : '';
       
//         List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
//         Messaging.Emailfileattachment efa1 = new Messaging.Emailfileattachment();
//         efa1.setFileName('Application form for '+ accountName+' | #'+system.today().year()+'-'+System.now().format('MMM')+'-'+system.today().day()+'-'+l.name+'.Pdf');
//         efa1.setBody(pdfContent);
//         fileAttachments.add(efa1);
        
//         if(l.Email__C != null && l.Email__C != ''){
//             List<String> lstBCCEmail = l.Email__C != null ? l.Email__C.split(',') : new List<String>();
//             Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
//             mail.toAddresses = new string[]{l.SLead__r.Email};
//                 mail.bccaddresses = lstBCCEmail;
//             mail.ccaddresses = lstCCEmail;
//             mail.setSubject('Application form for '+ accountName+' | #'+system.today().year()+'-'+System.now().format('MMM')+'-'+system.today().day()+'-'+l.name);
//             mail.setFileAttachments(fileAttachments);
            
//             string emailBody='Dear '+l.First_Applicant_Name__c+',<br/>Please find the attached Application Form Letter.<br/><br/>' +
//             'We are pleased to inform you that your booking has been confirmed. ' +
//             'Attached is the Application form for your reference.<br/><br/>' +
//             'If you have any questions or need further assistance, please contact us.<br/><br/>' +
//             'Thank you for choosing NAMBIAR Builders.<br/><br/>' +
//             'Best regards,<br/>' +
//             'NAMBIAR Builders Pvt Ltd';
// 			mail.setHtmlBody(emailBody);
//             mails.add(mail);
//         }
//         Messaging.SendEmailResult[] results = new list<Messaging.SendEmailResult>();
//         if(!isTest){
//             results = Messaging.sendEmail(mails); 
//             system.debug(results);
           
//         }
//     }
    
//     public static void validateRequiredDocuments(Map<Id, Booking__c> bookingMap) {
//         // Map of suffix patterns to display names
//         Map<String, String> documentTypes = new Map<String, String>{
//             ' - [ Aadhar Card ]' => 'Aadhar Card',
//                 ' - [ Pan Card ]' => 'Pan Card',
//                 ' - [ Sale Agreement ]' => 'Sale Agreement',
//                 ' - [ Sale Deed Token ]' => 'Sale Deed Token',
//                 ' - [ Sale Deed Fee Challan ]' => 'Sale Deed Fee Challan',
//                 ' - [ Sale Deed ]' => 'Sale Deed',
//                 ' - [ Loan Sanction Letter ]' => 'Loan Sanction Letter'
//                 };
                    
//                     // Core required documents (without loan document)
//                     Set<String> requiredSuffixes = new Set<String>{
//                         ' - [ Aadhar Card ]',
//                             ' - [ Pan Card ]',
//                             ' - [ Sale Agreement ]',
//                             ' - [ Sale Deed Token ]',
//                             ' - [ Sale Deed Fee Challan ]',
//                             ' - [ Sale Deed ]'
//                             };
                                
//                                 // Query all documents
//                                 Map<Id, Set<String>> bookingToSuffixesMap = new Map<Id, Set<String>>();
//         for(ContentDocumentLink link : [
//             SELECT LinkedEntityId, ContentDocument.Title 
//             FROM ContentDocumentLink 
//             WHERE LinkedEntityId IN :bookingMap.keySet()
//         ]) {
//             if(!bookingToSuffixesMap.containsKey(link.LinkedEntityId)) {
//                 bookingToSuffixesMap.put(link.LinkedEntityId, new Set<String>());
//             }
            
//             // Check all possible document types
//             for(String suffix : documentTypes.keySet()) {
//                 if(link.ContentDocument.Title.endsWith(suffix)) {
//                     bookingToSuffixesMap.get(link.LinkedEntityId).add(suffix);
//                 }
//             }
//         }
        
//         // Validate each booking
//         for(Id bookingId : bookingMap.keySet()) {
//             Booking__c book = bookingMap.get(bookingId);
//             Set<String> requiredForThisBooking = new Set<String>(requiredSuffixes);
            
//             // Add loan document if needed
//             if(book.Funding_Type__c == 'Loan') {
//                 requiredForThisBooking.add(' - [ Loan Sanction Letter ]');
//             }
            
//             // Find missing documents
//             Set<String> missing = new Set<String>();
//             for(String suffix : requiredForThisBooking) {
//                 if(!bookingToSuffixesMap.containsKey(bookingId) || 
//                    !bookingToSuffixesMap.get(bookingId).contains(suffix)) {
//                        missing.add(documentTypes.get(suffix));
//                    }
//             }
            
//             // Show error if any missing
//             if(!missing.isEmpty()) {
//                 String errorMsg = 'Upload missing documents: ' + String.join(new List<String>(missing), ', ');
//                 book.addError(errorMsg);
//             }
//         }
//     }
    
//     @AuraEnabled(cacheable=true)
//     public static Boolean checkIfDashboardExists(String dashName) {
//         // Query the ApexPage object to check if the dashboard exists
//         List<ApexPage> pages = [SELECT Id, Name FROM ApexPage WHERE Name = :dashName LIMIT 1];
//         return !pages.isEmpty();
//     }
//     @AuraEnabled
//     public static void uploadPaymentScheduleFile(Id bookingId, String fileName, String base64Data){
//         ContentVersion contentVersion = new ContentVersion();
//         contentVersion.Title = 'Payment Schedule Form - ' + fileName;
//         contentVersion.PathOnClient = fileName;
//         contentVersion.VersionData = EncodingUtil.base64Decode(base64Data);
//         contentVersion.FirstPublishLocationId = bookingId;
//         insert contentVersion;
//     }

//     // Channel Partner on Booking starts - 22-09-2026
//     // Same lookup as the GRE form (greController, without sharing): partner name for a valid Adissia CP code, null when unknown
//     @AuraEnabled
//     public static String getChannelPartnerNameByCode(String cpCode) {
//         return greController.getChannelPartnerNameByCode(cpCode);
//     }
//     // Channel Partner on Booking ends
    
// }

// ======================================================================================================================================
// ======================================================================================================================================

// public class BookingController{
    
//         //Method to get Picklist Values
//         //Project Shown in Create Booking Button Lead by sathya 21-06-2026
//         @AuraEnabled
//         public static Map<String, String> getProjectNames(String LdId) {
//             Map<String, String> options = new Map<String, String>();
        
//             if (String.isBlank(ldId)) return options;
        
//             // Get NRI Sales Record Type ID
//             Id nriRecordTypeId = [
//                 SELECT Id 
//                 FROM RecordType 
//                 WHERE SObjectType = 'Lead' 
//                 AND DeveloperName = 'NRI_Sales' 
//                 LIMIT 1
//             ].Id;
        
//             Lead ld = [
//                 SELECT RecordTypeId,
//                        OwnerId,
//                        (SELECT Project__c 
//                         FROM Site_Visit__r
//                         WHERE Status__c = 'Completed'
//                         AND Project__c != null)
//                 FROM Lead
//                 WHERE Id = :ldId
//                 LIMIT 1
//             ];
        
//             // Check if owner is NRI user
//             Boolean isNRIUser = ![
//                 SELECT Id 
//                 FROM User 
//                 WHERE Id = :ld.OwnerId 
//                 AND Is_NRI_User__c = true
//             ].isEmpty();
        
//             Boolean isNRI = ld.RecordTypeId == nriRecordTypeId && isNRIUser;
        
//             if (isNRI) {
//                 for (Project__c prj : [
//                     SELECT Name
//                     FROM Project__c
//                     WHERE Active__c = true
//                     AND Name != null
//                     ORDER BY Name
//                 ]) {
//                     options.put(prj.Name, prj.Name);
//                 }
//             } else {
//                 for (Site_Visit__c sv : ld.Site_Visit__r) {
//                     if (String.isNotBlank(sv.Project__c)) {
//                         options.put(sv.Project__c, sv.Project__c);
//                     }
//                 }
//             }
        
//             return options;
//         }
//         //Project Shown in Create Booking Button Lead by sathya 21-06-2026-- End    
//         //Method to get the project Id
//         @AuraEnabled
//         public static Project__c getProjectId(String projectName){
//             Project__c prj = [select Id,name,CRM_Manager__c,Finance_User__c from Project__c where Project__c =:projectName LIMIT 1];
//             return prj;
//         }
//         //Method to get lead details
//          @AuraEnabled
//         public static Lead getLeadDetails(Id recId){
//             Lead ld = [select Id,Name,Allocated_Project__c from Lead where Id =: recId];
//             return ld;
//         }
        
//         @AuraEnabled
//         public static Plot__c getPlotAllDetails(Id recId){
//             Plot__c plt = [select id,name,Basic_Price__c,Booking_Amount__c,Booking_Amnt_EWS__c,Total_Cost__c,Status__c,Plot_Area_in_Cent__c,Unit_Facing_Direction__c,Corner__c,Plot_Land_Area__c,EWS_Plot__c from Plot__c where Id=: recId];
//             return plt;
//         }
        
//         //Method to fetch All the Available units from a particular project
//         @AuraEnabled
//         public static List<Plot__c> getAllAvailablePlots(Id recId){
//             List<Lead> ldList = [select id,name,Allocated_Project__c from Lead where Id =: recId];
//             String ProjectName = ldList[0].Allocated_Project__c;
//             List<Plot__c> plotList = [select Id,Name,Project__c,Project__r.Name,Unit_Facing_Direction__c,Total_Cost__c,Total__c,Corner__c,Basic_Price__c,North_By__c,West_By__c,East_By__c,South_By__c,Plot_Land_Area__c from Plot__c where Project__r.Project__c =:ProjectName and Status__c = 'Available'];
//             return plotList;
//         }
    
//     //Method to get respective unit details
//     @AuraEnabled
//     public static List<Plot__c> getPlotDetails(Id recId){
//         List<Plot__c> qt = [SELECT Id,Name,Unit_Facing_Direction__c,Total_Cost__c,Project__r.Name,Corner__c,Total__c,Basic_Price__c,North_By__c,West_By__c,East_By__c,South_By__c,Plot_Land_Area__c FROM Plot__c WHERE Id=:recId];
//         return qt;
//     }

//     //Method to chage the Unit Status on Booking Stage Change
//     @AuraEnabled
//     public static void changeUnitStatus(Map<Id,String> plotIds){
//         List<Plot__c> plotList = [Select Id,Name,Status__c from Plot__c where Id in: plotIds.keySet()];
//         for(Plot__c plt : plotList){
//             plt.Status__c = plotIds.get(plt.Id);
//         }
//         update plotList;
//     }
    
//     public static void bookingCancellations(Set<Id> leadIds){
//         List<Lead> leadList = [Select id,name,Lead_Status__c from Lead where Id in: leadIds];
//         for(Lead ld : leadList){
//             ld.Lead_Status__c = 'Booked';
//         }
//         Update leadList;
//     }
    
//     public static void changeLeadStatus(Set<Id> leadIds){
//         List<Lead> leadList = [Select id,name,Lead_Status__c from Lead where Id in: leadIds];
//         for(Lead ld : leadList){
//             ld.Lead_Status__c = 'Booked';
//         }
//         Update leadList;
//     }
    
//     public static void sendCustomNotification(Set<String> recepientIds, String Title, String Body, String recId, String notificationName){
//         CustomNotificationType closedWonNotification = [SELECT Id,DeveloperName FROM CustomNotificationType WHERE DeveloperName =: notificationName LIMIT 1]; 
        
//         Set<String> rectIds = new Set<String>();
        
//         for(User us : [SELECT Id, IsActive FROM User WHERE Id in: recepientIds and IsActive = true]){
//             rectIds.add(us.Id);
//         }
        
        
//         Messaging.CustomNotification Notification = new Messaging.CustomNotification(); 
//         Notification.setNotificationTypeId(closedWonNotification.id); 
//         Notification.setSenderId(Userinfo.getUserId()); 
//         Notification.setBody(Body); 
//         Notification.setTitle(Title); 
//         Notification.setTargetId(recId); 
//         //Notification.send(recepientIds);
//         Notification.send(rectIds);
//     }
    
//     public static Set<String> getUserIdsFromGroup(String groupName) {
//         Set<Id> userIdSet  = new Set<Id>();
//         Set<String> userStringIds = new Set<String>();
        
//         // Get Group Id by name
//         Group g = [SELECT Id FROM Group WHERE Name = :groupName AND Type = 'Regular' LIMIT 1];
        
//         // Get Group Members
//         for (GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :g.Id])
//         {
//             userIdSet.add(gm.UserOrGroupId);
//         }
        
//         // Filter only active users
//         Map<Id, User> activeUsers = new Map<Id, User>([SELECT Id FROM User WHERE Id IN :userIdSet AND IsActive = true]);

//         // Convert to String ids
//         for (Id uid : activeUsers.keySet()) {
//             userStringIds.add((String) uid);
//         }
        
//         return userStringIds;
//     }

    
//     //Method to save the booking details
//     @AuraEnabled
//     public static Id saveBooking(Booking__c oppPlot){
//         if(oppPlot !=null){
//             List<User> uList = new List<User>();
//             List<Round_Robin__c> RRAvaliablequeList=[Select Id,Project_Assigned__c, (select Name,User__c from  Round_Robin_Members__r  where Active__c =true and User_Type__c = 'Post Sales'  order by Last_Assigned_time_user__c,createddate asc nulls first limit 1) from Round_Robin__c where Project_Assigned__c =: oppPlot.Project__c and Active__c = true ];
//             List<Project__c> proJectList = [select Id,Name,CRM_Manager__c,Finance_User__c from Project__c where Project__c =:oppPlot.Project__c ];
//            /* if(RRAvaliablequeList.size()>0){
//                 for(Round_Robin__c rr : RRAvaliablequeList){
//                     if(rr.Round_Robin_Members__r.size()>0){
//                         oppPlot.OwnerId = rr.Round_Robin_Members__r[0].User__c;
//                         User u = new User();
//                         u.Id = rr.Round_Robin_Members__r[0].User__c;
//                         u.LastAssignmentTime1__c = system.now().getTime(); 
//                         uList.add(u);
//                     }
                    
//                 }
//             }
//             else{
//                 oppPlot.OwnerId = proJectList[0].CRM_Manager__c;
//             }
//             oppPlot.Sales_User__c = UserInfo.getUserId();
//             oppPlot.CRM_Manager__c = proJectList[0].CRM_Manager__c;
//             oppPlot.Finance_User__c = proJectList[0].Finance_User__c;*/
//             insert oppPlot;
//             //update uList;
//             // MIS Sales notification on Booking creation - 03-10-2026
//             notifyMisSalesOnBookingCreation(oppPlot.Id);
//             return oppPlot.Id;
//         }
//         else{
//             return null;
//         }
        
//     }

//     // MIS Sales notification on Booking creation starts - 03-10-2026
//     // Sends Email + Bell notification to the MIS Sales users (Rajalakshmi, Vinoth) through the common notification system
//     public static void notifyMisSalesOnBookingCreation(Id bookingId){
//         Booking__c createdBooking = [SELECT Id, Name, Project__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
//         Set<Id> notificationUserIds = new Set<Id>(new Map<Id, User>([SELECT Id FROM User WHERE Profile.Name = 'MIS Sales' AND Name IN ('Rajalakshmi', 'Vinoth') AND IsActive = true]).keySet());

//         // Sandbox testing only - Sivam receives the same Email + Bell. Remove this line before production deployment
//         notificationUserIds.addAll(new Map<Id, User>([SELECT Id FROM User WHERE Username = 'sivam.v@adissia.com' AND IsActive = true]).keySet());

//         String notificationTitle = 'New Booking Created - ' + createdBooking.Name;
//         String notificationBody = 'Booking ' + createdBooking.Name + ' has been created for project ' + createdBooking.Project__c + ' by ' + UserInfo.getName() + '.';

//         CommonNotificationServices.emailNotificationSystem(createdBooking.Id, notificationUserIds, notificationTitle, notificationBody);
//         CommonNotificationServices.bellNotificationSystem(createdBooking.Id, notificationUserIds, notificationTitle, notificationBody);
//     }
//     // MIS Sales notification on Booking creation ends
    
//     public static void sendWelcomeMail(Booking__c book){
        
//     }
    
//     public static void bookingAmountReceipt(Booking__c booking){ 
        
//         Receipt__c recp = new Receipt__c();
//         recp.Booking__c = booking.Id;
//         recp.Receipt_Name__c = 'Booking Amount Receipt';
//         recp.Remarks__c = 'Receipt for the Booking Amount. Auto Generated by system';
//         insert recp;
        
//         if(recp.Id != null){
//             Receipt_Line_Item__c rli = new Receipt_Line_Item__c();
//             //rli.Name = 'Booking Amount';
//             rli.Cheque_no_Transaction_Number__c = booking.Cheque_DD_NEFT_RTGS_No__c;
//             rli.Receipt__c = recp.Id;
//             rli.Booking__c = booking.Id;
//             rli.Amount__c = booking.Booking_Amount__c;
            
//             insert rli;
//         }
//     }
    
//     @auraEnabled
//     public static string getpageName(string recId){
//          string vfpageName;
//         Booking__c book = [SELECT Id,Name,Project__c FROM Booking__c where Id=:recId];
//         if(book.Project__c=='Bellezea'){
//             vfpageName ='GenerateBellezea';
//         }else if(book.Project__c=='Ellegenza'){
//             vfpageName ='GenerateEllegenzaPdf';
//         }else if(book.Project__c=='Millenia'){
//             vfpageName='GenerateMillenia';
//         }
//         return vfpageName;
//     }

//     public static void sendCancellationApproval(string recId){
//         Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
//         req1.setComments('Booking Cancellation Approval request');
//         req1.setObjectId(recId);
//         req1.setSubmitterId(userInfo.getUserId());
//         req1.setProcessDefinitionNameOrId('Booking_Cancellation_Approval');
//         req1.setSkipEntryCriteria(true);
//         Approval.ProcessResult result = Approval.process(req1);
//     }
//     @auraEnabled
//     public static void sendEmailtoCustomer(string recId){
//         string recordId = recId;
//         Booking__c l = [SELECT Id,CRM_Manager__r.Email,Owner.Email,Name,Email__C,Email1__c,SLead__r.Email,Project__c,First_Applicant_Name__c FROM Booking__c where Id=:recId];
//         List<String> lstCCEmail = new List<String>();
//         if(l.Email__C != null && l.Email__C != ''){
//             lstCCEmail = l.Email__C.split(',');
//         }
//         if (l.Email1__c != null && l.Email1__c != ''){
//             lstCCEmail.addAll(l.Email1__c.split(','));
//         }
//         lstCCEmail.add(l.Owner.Email);
//         if(l.CRM_Manager__c != null){
//             lstCCEmail.add(l.CRM_Manager__r.Email);
//         }

//         list<Messaging.SingleEmailMessage> mails = new list<Messaging.SingleEmailMessage>(); 
//         PageReference pdfPage;
//         pdfPage= page.BookingForm;
//         pdfPage.getParameters().put('Id', recordId);
//         Blob pdfContent;
//         Boolean isTest = System.Test.isRunningTest();
//         if(!isTest){
//             pdfContent = pdfPage.getContent();
//         }else{
//             pdfContent=Blob.valueOf('Test Content');
//         }
//         String accountName = l.Name != null ? l.Name : '';
       
//         List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
//         Messaging.Emailfileattachment efa1 = new Messaging.Emailfileattachment();
//         efa1.setFileName('Application form for '+ accountName+' | #'+system.today().year()+'-'+System.now().format('MMM')+'-'+system.today().day()+'-'+l.name+'.Pdf');
//         efa1.setBody(pdfContent);
//         fileAttachments.add(efa1);
        
//         if(l.Email__C != null && l.Email__C != ''){
//             List<String> lstBCCEmail = l.Email__C != null ? l.Email__C.split(',') : new List<String>();
//             Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
//             mail.toAddresses = new string[]{l.SLead__r.Email};
//                 mail.bccaddresses = lstBCCEmail;
//             mail.ccaddresses = lstCCEmail;
//             mail.setSubject('Application form for '+ accountName+' | #'+system.today().year()+'-'+System.now().format('MMM')+'-'+system.today().day()+'-'+l.name);
//             mail.setFileAttachments(fileAttachments);
            
//             string emailBody='Dear '+l.First_Applicant_Name__c+',<br/>Please find the attached Application Form Letter.<br/><br/>' +
//             'We are pleased to inform you that your booking has been confirmed. ' +
//             'Attached is the Application form for your reference.<br/><br/>' +
//             'If you have any questions or need further assistance, please contact us.<br/><br/>' +
//             'Thank you for choosing NAMBIAR Builders.<br/><br/>' +
//             'Best regards,<br/>' +
//             'NAMBIAR Builders Pvt Ltd';
// 			mail.setHtmlBody(emailBody);
//             mails.add(mail);
//         }
//         Messaging.SendEmailResult[] results = new list<Messaging.SendEmailResult>();
//         if(!isTest){
//             results = Messaging.sendEmail(mails); 
//             system.debug(results);
           
//         }
//     }
    
//     public static void validateRequiredDocuments(Map<Id, Booking__c> bookingMap) {
//         // Map of suffix patterns to display names
//         Map<String, String> documentTypes = new Map<String, String>{
//             ' - [ Aadhar Card ]' => 'Aadhar Card',
//                 ' - [ Pan Card ]' => 'Pan Card',
//                 ' - [ Sale Agreement ]' => 'Sale Agreement',
//                 ' - [ Sale Deed Token ]' => 'Sale Deed Token',
//                 ' - [ Sale Deed Fee Challan ]' => 'Sale Deed Fee Challan',
//                 ' - [ Sale Deed ]' => 'Sale Deed',
//                 ' - [ Loan Sanction Letter ]' => 'Loan Sanction Letter'
//                 };
                    
//                     // Core required documents (without loan document)
//                     Set<String> requiredSuffixes = new Set<String>{
//                         ' - [ Aadhar Card ]',
//                             ' - [ Pan Card ]',
//                             ' - [ Sale Agreement ]',
//                             ' - [ Sale Deed Token ]',
//                             ' - [ Sale Deed Fee Challan ]',
//                             ' - [ Sale Deed ]'
//                             };
                                
//                                 // Query all documents
//                                 Map<Id, Set<String>> bookingToSuffixesMap = new Map<Id, Set<String>>();
//         for(ContentDocumentLink link : [
//             SELECT LinkedEntityId, ContentDocument.Title 
//             FROM ContentDocumentLink 
//             WHERE LinkedEntityId IN :bookingMap.keySet()
//         ]) {
//             if(!bookingToSuffixesMap.containsKey(link.LinkedEntityId)) {
//                 bookingToSuffixesMap.put(link.LinkedEntityId, new Set<String>());
//             }
            
//             // Check all possible document types
//             for(String suffix : documentTypes.keySet()) {
//                 if(link.ContentDocument.Title.endsWith(suffix)) {
//                     bookingToSuffixesMap.get(link.LinkedEntityId).add(suffix);
//                 }
//             }
//         }
        
//         // Validate each booking
//         for(Id bookingId : bookingMap.keySet()) {
//             Booking__c book = bookingMap.get(bookingId);
//             Set<String> requiredForThisBooking = new Set<String>(requiredSuffixes);
            
//             // Add loan document if needed
//             if(book.Funding_Type__c == 'Loan') {
//                 requiredForThisBooking.add(' - [ Loan Sanction Letter ]');
//             }
            
//             // Find missing documents
//             Set<String> missing = new Set<String>();
//             for(String suffix : requiredForThisBooking) {
//                 if(!bookingToSuffixesMap.containsKey(bookingId) || 
//                    !bookingToSuffixesMap.get(bookingId).contains(suffix)) {
//                        missing.add(documentTypes.get(suffix));
//                    }
//             }
            
//             // Show error if any missing
//             if(!missing.isEmpty()) {
//                 String errorMsg = 'Upload missing documents: ' + String.join(new List<String>(missing), ', ');
//                 book.addError(errorMsg);
//             }
//         }
//     }
    
//     @AuraEnabled(cacheable=true)
//     public static Boolean checkIfDashboardExists(String dashName) {
//         // Query the ApexPage object to check if the dashboard exists
//         List<ApexPage> pages = [SELECT Id, Name FROM ApexPage WHERE Name = :dashName LIMIT 1];
//         return !pages.isEmpty();
//     }
//     @AuraEnabled
//     public static void uploadPaymentScheduleFile(Id bookingId, String fileName, String base64Data){
//         ContentVersion contentVersion = new ContentVersion();
//         contentVersion.Title = 'Payment Schedule Form - ' + fileName;
//         contentVersion.PathOnClient = fileName;
//         contentVersion.VersionData = EncodingUtil.base64Decode(base64Data);
//         contentVersion.FirstPublishLocationId = bookingId;
//         insert contentVersion;
//     }

//     // Channel Partner on Booking starts - 22-09-2026
//     // Same lookup as the GRE form (greController, without sharing): partner name for a valid Adissia CP code, null when unknown
//     @AuraEnabled
//     public static String getChannelPartnerNameByCode(String cpCode) {
//         return greController.getChannelPartnerNameByCode(cpCode);
//     }
//     // Channel Partner on Booking ends
    
// }

// ========================================================= Added By Sivam (for MIS Sales Notification) ==========================
// ==================================================================================================================================

public class BookingController{
    
        //Method to get Picklist Values
        //Project Shown in Create Booking Button Lead by sathya 21-06-2026
        @AuraEnabled
        public static Map<String, String> getProjectNames(String LdId) {
            Map<String, String> options = new Map<String, String>();
        
            if (String.isBlank(ldId)) return options;
        
            // Get NRI Sales Record Type ID
            Id nriRecordTypeId = [
                SELECT Id 
                FROM RecordType 
                WHERE SObjectType = 'Lead' 
                AND DeveloperName = 'NRI_Sales' 
                LIMIT 1
            ].Id;
        
            Lead ld = [
                SELECT RecordTypeId,
                       OwnerId,
                       (SELECT Project__c 
                        FROM Site_Visit__r
                        WHERE Status__c = 'Completed'
                        AND Project__c != null)
                FROM Lead
                WHERE Id = :ldId
                LIMIT 1
            ];
        
            // Check if owner is NRI user
            Boolean isNRIUser = ![
                SELECT Id 
                FROM User 
                WHERE Id = :ld.OwnerId 
                AND Is_NRI_User__c = true
            ].isEmpty();
        
            Boolean isNRI = ld.RecordTypeId == nriRecordTypeId && isNRIUser;
        
            if (isNRI) {
                for (Project__c prj : [
                    SELECT Name
                    FROM Project__c
                    WHERE Active__c = true
                    AND Name != null
                    ORDER BY Name
                ]) {
                    options.put(prj.Name, prj.Name);
                }
            } else {
                for (Site_Visit__c sv : ld.Site_Visit__r) {
                    if (String.isNotBlank(sv.Project__c)) {
                        options.put(sv.Project__c, sv.Project__c);
                    }
                }
            }
        
            return options;
        }
        //Project Shown in Create Booking Button Lead by sathya 21-06-2026-- End    
        //Method to get the project Id
        @AuraEnabled
        public static Project__c getProjectId(String projectName){
            Project__c prj = [select Id,name,CRM_Manager__c,Finance_User__c from Project__c where Project__c =:projectName LIMIT 1];
            return prj;
        }
        //Method to get lead details
         @AuraEnabled
        public static Lead getLeadDetails(Id recId){
            Lead ld = [select Id,Name,Allocated_Project__c from Lead where Id =: recId];
            return ld;
        }
        
        @AuraEnabled
        public static Plot__c getPlotAllDetails(Id recId){
            Plot__c plt = [select id,name,Basic_Price__c,Booking_Amount__c,Booking_Amnt_EWS__c,Total_Cost__c,Status__c,Plot_Area_in_Cent__c,Unit_Facing_Direction__c,Corner__c,Plot_Land_Area__c,EWS_Plot__c from Plot__c where Id=: recId];
            return plt;
        }
        
        //Method to fetch All the Available units from a particular project
        @AuraEnabled
        public static List<Plot__c> getAllAvailablePlots(Id recId){
            List<Lead> ldList = [select id,name,Allocated_Project__c from Lead where Id =: recId];
            String ProjectName = ldList[0].Allocated_Project__c;
            List<Plot__c> plotList = [select Id,Name,Project__c,Project__r.Name,Unit_Facing_Direction__c,Total_Cost__c,Total__c,Corner__c,Basic_Price__c,North_By__c,West_By__c,East_By__c,South_By__c,Plot_Land_Area__c from Plot__c where Project__r.Project__c =:ProjectName and Status__c = 'Available'];
            return plotList;
        }
    
    //Method to get respective unit details
    @AuraEnabled
    public static List<Plot__c> getPlotDetails(Id recId){
        List<Plot__c> qt = [SELECT Id,Name,Unit_Facing_Direction__c,Total_Cost__c,Project__r.Name,Corner__c,Total__c,Basic_Price__c,North_By__c,West_By__c,East_By__c,South_By__c,Plot_Land_Area__c FROM Plot__c WHERE Id=:recId];
        return qt;
    }

    //Method to chage the Unit Status on Booking Stage Change
    @AuraEnabled
    public static void changeUnitStatus(Map<Id,String> plotIds){
        List<Plot__c> plotList = [Select Id,Name,Status__c from Plot__c where Id in: plotIds.keySet()];
        for(Plot__c plt : plotList){
            plt.Status__c = plotIds.get(plt.Id);
        }
        update plotList;
    }
    
    public static void bookingCancellations(Set<Id> leadIds){
        List<Lead> leadList = [Select id,name,Lead_Status__c from Lead where Id in: leadIds];
        for(Lead ld : leadList){
            ld.Lead_Status__c = 'Booked';
        }
        Update leadList;
    }
    
    public static void changeLeadStatus(Set<Id> leadIds){
        List<Lead> leadList = [Select id,name,Lead_Status__c from Lead where Id in: leadIds];
        for(Lead ld : leadList){
            ld.Lead_Status__c = 'Booked';
        }
        Update leadList;
    }
    
    public static void sendCustomNotification(Set<String> recepientIds, String Title, String Body, String recId, String notificationName){
        CustomNotificationType closedWonNotification = [SELECT Id,DeveloperName FROM CustomNotificationType WHERE DeveloperName =: notificationName LIMIT 1]; 
        
        Set<String> rectIds = new Set<String>();
        
        for(User us : [SELECT Id, IsActive FROM User WHERE Id in: recepientIds and IsActive = true]){
            rectIds.add(us.Id);
        }
        
        
        Messaging.CustomNotification Notification = new Messaging.CustomNotification(); 
        Notification.setNotificationTypeId(closedWonNotification.id); 
        Notification.setSenderId(Userinfo.getUserId()); 
        Notification.setBody(Body); 
        Notification.setTitle(Title); 
        Notification.setTargetId(recId); 
        //Notification.send(recepientIds);
        Notification.send(rectIds);
    }
    
    public static Set<String> getUserIdsFromGroup(String groupName) {
        Set<Id> userIdSet  = new Set<Id>();
        Set<String> userStringIds = new Set<String>();
        
        // Get Group Id by name
        Group g = [SELECT Id FROM Group WHERE Name = :groupName AND Type = 'Regular' LIMIT 1];
        
        // Get Group Members
        for (GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :g.Id])
        {
            userIdSet.add(gm.UserOrGroupId);
        }
        
        // Filter only active users
        Map<Id, User> activeUsers = new Map<Id, User>([SELECT Id FROM User WHERE Id IN :userIdSet AND IsActive = true]);

        // Convert to String ids
        for (Id uid : activeUsers.keySet()) {
            userStringIds.add((String) uid);
        }
        
        return userStringIds;
    }

    
    //Method to save the booking details
    @AuraEnabled
    public static Id saveBooking(Booking__c oppPlot){
        if(oppPlot !=null){
            List<User> uList = new List<User>();
            List<Round_Robin__c> RRAvaliablequeList=[Select Id,Project_Assigned__c, (select Name,User__c from  Round_Robin_Members__r  where Active__c =true and User_Type__c = 'Post Sales'  order by Last_Assigned_time_user__c,createddate asc nulls first limit 1) from Round_Robin__c where Project_Assigned__c =: oppPlot.Project__c and Active__c = true ];
            List<Project__c> proJectList = [select Id,Name,CRM_Manager__c,Finance_User__c from Project__c where Project__c =:oppPlot.Project__c ];
           /* if(RRAvaliablequeList.size()>0){
                for(Round_Robin__c rr : RRAvaliablequeList){
                    if(rr.Round_Robin_Members__r.size()>0){
                        oppPlot.OwnerId = rr.Round_Robin_Members__r[0].User__c;
                        User u = new User();
                        u.Id = rr.Round_Robin_Members__r[0].User__c;
                        u.LastAssignmentTime1__c = system.now().getTime(); 
                        uList.add(u);
                    }
                    
                }
            }
            else{
                oppPlot.OwnerId = proJectList[0].CRM_Manager__c;
            }
            oppPlot.Sales_User__c = UserInfo.getUserId();
            oppPlot.CRM_Manager__c = proJectList[0].CRM_Manager__c;
            oppPlot.Finance_User__c = proJectList[0].Finance_User__c;*/
            insert oppPlot;
            //update uList;
            return oppPlot.Id;
        }
        else{
            return null;
        }
        
    }

    // MIS Sales notification on Booking creation starts - 03-10-2026
    // Called from BookingTrigger (after insert), so it fires for every new booking including the Create Booking form (lightning:recordEditForm)
    // Sends Email + Bell notification to the MIS Sales users (Rajalakshmi, Vinoth) through the common notification system
    public static void notifyMisSalesOnBookingCreation(Set<Id> bookingIds){
        if (bookingIds == null || bookingIds.isEmpty()) return;

        // Matched by username so it works in both sandbox (.fullcopy suffix) and production
        Set<Id> notificationUserIds = new Set<Id>(new Map<Id, User>([SELECT Id FROM User WHERE Profile.Name = 'MIS Sales' AND IsActive = true AND (Username LIKE 'rajalakshmi.v@adissia.com%' OR Username LIKE 'vinoth.m@adissia.com%')]).keySet());

        // Sandbox testing only - Sivam receives the same Email + Bell. Remove this line before production deployment
        notificationUserIds.addAll(new Map<Id, User>([SELECT Id FROM User WHERE Username = 'sivam.v@adissia.com' AND IsActive = true]).keySet());

        if (notificationUserIds.isEmpty()) return;

        for (Booking__c createdBooking : [SELECT Id, Name, Project__c FROM Booking__c WHERE Id IN :bookingIds]) {
            String notificationTitle = 'New Booking Created - ' + createdBooking.Name;
            String notificationBody = 'Booking ' + createdBooking.Name + ' has been created for project ' + createdBooking.Project__c + ' by ' + UserInfo.getName() + '.';

            CommonNotificationServices.emailNotificationSystem(createdBooking.Id, notificationUserIds, notificationTitle, notificationBody);
            CommonNotificationServices.bellNotificationSystem(createdBooking.Id, notificationUserIds, notificationTitle, notificationBody);
        }
    }
    // MIS Sales notification on Booking creation ends
    
    public static void sendWelcomeMail(Booking__c book){
        
    }
    
    public static void bookingAmountReceipt(Booking__c booking){ 
        
        Receipt__c recp = new Receipt__c();
        recp.Booking__c = booking.Id;
        recp.Receipt_Name__c = 'Booking Amount Receipt';
        recp.Remarks__c = 'Receipt for the Booking Amount. Auto Generated by system';
        insert recp;
        
        if(recp.Id != null){
            Receipt_Line_Item__c rli = new Receipt_Line_Item__c();
            //rli.Name = 'Booking Amount';
            rli.Cheque_no_Transaction_Number__c = booking.Cheque_DD_NEFT_RTGS_No__c;
            rli.Receipt__c = recp.Id;
            rli.Booking__c = booking.Id;
            rli.Amount__c = booking.Booking_Amount__c;
            
            insert rli;
        }
    }
    
    @auraEnabled
    public static string getpageName(string recId){
         string vfpageName;
        Booking__c book = [SELECT Id,Name,Project__c FROM Booking__c where Id=:recId];
        if(book.Project__c=='Bellezea'){
            vfpageName ='GenerateBellezea';
        }else if(book.Project__c=='Ellegenza'){
            vfpageName ='GenerateEllegenzaPdf';
        }else if(book.Project__c=='Millenia'){
            vfpageName='GenerateMillenia';
        }
        return vfpageName;
    }

    public static void sendCancellationApproval(string recId){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Booking Cancellation Approval request');
        req1.setObjectId(recId);
        req1.setSubmitterId(userInfo.getUserId());
        req1.setProcessDefinitionNameOrId('Booking_Cancellation_Approval');
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
    }
    @auraEnabled
    public static void sendEmailtoCustomer(string recId){
        string recordId = recId;
        Booking__c l = [SELECT Id,CRM_Manager__r.Email,Owner.Email,Name,Email__C,Email1__c,SLead__r.Email,Project__c,First_Applicant_Name__c FROM Booking__c where Id=:recId];
        List<String> lstCCEmail = new List<String>();
        if(l.Email__C != null && l.Email__C != ''){
            lstCCEmail = l.Email__C.split(',');
        }
        if (l.Email1__c != null && l.Email1__c != ''){
            lstCCEmail.addAll(l.Email1__c.split(','));
        }
        lstCCEmail.add(l.Owner.Email);
        if(l.CRM_Manager__c != null){
            lstCCEmail.add(l.CRM_Manager__r.Email);
        }

        list<Messaging.SingleEmailMessage> mails = new list<Messaging.SingleEmailMessage>(); 
        PageReference pdfPage;
        pdfPage= page.BookingForm;
        pdfPage.getParameters().put('Id', recordId);
        Blob pdfContent;
        Boolean isTest = System.Test.isRunningTest();
        if(!isTest){
            pdfContent = pdfPage.getContent();
        }else{
            pdfContent=Blob.valueOf('Test Content');
        }
        String accountName = l.Name != null ? l.Name : '';
       
        List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
        Messaging.Emailfileattachment efa1 = new Messaging.Emailfileattachment();
        efa1.setFileName('Application form for '+ accountName+' | #'+system.today().year()+'-'+System.now().format('MMM')+'-'+system.today().day()+'-'+l.name+'.Pdf');
        efa1.setBody(pdfContent);
        fileAttachments.add(efa1);
        
        if(l.Email__C != null && l.Email__C != ''){
            List<String> lstBCCEmail = l.Email__C != null ? l.Email__C.split(',') : new List<String>();
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.toAddresses = new string[]{l.SLead__r.Email};
                mail.bccaddresses = lstBCCEmail;
            mail.ccaddresses = lstCCEmail;
            mail.setSubject('Application form for '+ accountName+' | #'+system.today().year()+'-'+System.now().format('MMM')+'-'+system.today().day()+'-'+l.name);
            mail.setFileAttachments(fileAttachments);
            
            string emailBody='Dear '+l.First_Applicant_Name__c+',<br/>Please find the attached Application Form Letter.<br/><br/>' +
            'We are pleased to inform you that your booking has been confirmed. ' +
            'Attached is the Application form for your reference.<br/><br/>' +
            'If you have any questions or need further assistance, please contact us.<br/><br/>' +
            'Thank you for choosing NAMBIAR Builders.<br/><br/>' +
            'Best regards,<br/>' +
            'NAMBIAR Builders Pvt Ltd';
			mail.setHtmlBody(emailBody);
            mails.add(mail);
        }
        Messaging.SendEmailResult[] results = new list<Messaging.SendEmailResult>();
        if(!isTest){
            results = Messaging.sendEmail(mails); 
            system.debug(results);
           
        }
    }
    
    public static void validateRequiredDocuments(Map<Id, Booking__c> bookingMap) {
        // Map of suffix patterns to display names
        Map<String, String> documentTypes = new Map<String, String>{
            ' - [ Aadhar Card ]' => 'Aadhar Card',
                ' - [ Pan Card ]' => 'Pan Card',
                ' - [ Sale Agreement ]' => 'Sale Agreement',
                ' - [ Sale Deed Token ]' => 'Sale Deed Token',
                ' - [ Sale Deed Fee Challan ]' => 'Sale Deed Fee Challan',
                ' - [ Sale Deed ]' => 'Sale Deed',
                ' - [ Loan Sanction Letter ]' => 'Loan Sanction Letter'
                };
                    
                    // Core required documents (without loan document)
                    Set<String> requiredSuffixes = new Set<String>{
                        ' - [ Aadhar Card ]',
                            ' - [ Pan Card ]',
                            ' - [ Sale Agreement ]',
                            ' - [ Sale Deed Token ]',
                            ' - [ Sale Deed Fee Challan ]',
                            ' - [ Sale Deed ]'
                            };
                                
                                // Query all documents
                                Map<Id, Set<String>> bookingToSuffixesMap = new Map<Id, Set<String>>();
        for(ContentDocumentLink link : [
            SELECT LinkedEntityId, ContentDocument.Title 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId IN :bookingMap.keySet()
        ]) {
            if(!bookingToSuffixesMap.containsKey(link.LinkedEntityId)) {
                bookingToSuffixesMap.put(link.LinkedEntityId, new Set<String>());
            }
            
            // Check all possible document types
            for(String suffix : documentTypes.keySet()) {
                if(link.ContentDocument.Title.endsWith(suffix)) {
                    bookingToSuffixesMap.get(link.LinkedEntityId).add(suffix);
                }
            }
        }
        
        // Validate each booking
        for(Id bookingId : bookingMap.keySet()) {
            Booking__c book = bookingMap.get(bookingId);
            Set<String> requiredForThisBooking = new Set<String>(requiredSuffixes);
            
            // Add loan document if needed
            if(book.Funding_Type__c == 'Loan') {
                requiredForThisBooking.add(' - [ Loan Sanction Letter ]');
            }
            
            // Find missing documents
            Set<String> missing = new Set<String>();
            for(String suffix : requiredForThisBooking) {
                if(!bookingToSuffixesMap.containsKey(bookingId) || 
                   !bookingToSuffixesMap.get(bookingId).contains(suffix)) {
                       missing.add(documentTypes.get(suffix));
                   }
            }
            
            // Show error if any missing
            if(!missing.isEmpty()) {
                String errorMsg = 'Upload missing documents: ' + String.join(new List<String>(missing), ', ');
                book.addError(errorMsg);
            }
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Boolean checkIfDashboardExists(String dashName) {
        // Query the ApexPage object to check if the dashboard exists
        List<ApexPage> pages = [SELECT Id, Name FROM ApexPage WHERE Name = :dashName LIMIT 1];
        return !pages.isEmpty();
    }
    @AuraEnabled
    public static void uploadPaymentScheduleFile(Id bookingId, String fileName, String base64Data){
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Payment Schedule Form - ' + fileName;
        contentVersion.PathOnClient = fileName;
        contentVersion.VersionData = EncodingUtil.base64Decode(base64Data);
        contentVersion.FirstPublishLocationId = bookingId;
        insert contentVersion;
    }

    // Channel Partner on Booking starts - 22-09-2026
    // Same lookup as the GRE form (greController, without sharing): partner name for a valid Adissia CP code, null when unknown
    @AuraEnabled
    public static String getChannelPartnerNameByCode(String cpCode) {
        return greController.getChannelPartnerNameByCode(cpCode);
    }
    // Channel Partner on Booking ends
    
}
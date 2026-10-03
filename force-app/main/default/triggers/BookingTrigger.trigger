trigger BookingTrigger on Booking__c (before insert,before update,after insert, after update, after delete, after undelete){
  if(label.Enable_Booking_Trigger =='TRUE'){
        system.debug('Trigger.New--->'+ Trigger.New);
      List<Booking__c> bkToSend = new List<Booking__c>();
      Set<Id> bookingLeadIds = new Set<Id>();
      Map<Id, Datetime> leadToBookingDateMap = new Map<Id, Datetime>();
      Set<Id> unitIds = new Set<Id>();
      
      // Starts by Ragu
        if(Trigger.isbefore && Trigger.isInsert){
           
            Set<Id> leadIds = new Set<Id>();
            Set<String> projectIds = new Set<String>();
            for (Booking__c b : Trigger.new) {
                if (b.SLead__c != null) {
                    leadIds.add(b.SLead__c);
                }
                if (b.Project__c != null) {
                    projectIds.add(b.Project__c);
                }
            }
            System.debug('leadIds--->'+leadIds);
            Map<String, DateTime> leadToCompletedDateMap = new Map<String, DateTime>();
        
            List<Site_Visit__c> visits = [
                SELECT Lead__c, Status__c, SV_Completed_Date_Time__c,Project__c
                FROM Site_Visit__c
                WHERE Lead__c IN :leadIds AND Project__c IN :projectIds AND Status__c = 'Completed'
                ORDER BY SV_Completed_Date_Time__c DESC
            ];
                    System.debug('visits--->'+visits);
    
            for (Site_Visit__c visit : visits) {
                String key = visit.Lead__c + '-' + String.valueOf(visit.Project__c);
                if (!leadToCompletedDateMap.containsKey(key)) {
                    leadToCompletedDateMap.put(key, visit.SV_Completed_Date_Time__c);
                }
            }
        
            for (Booking__c b : Trigger.new) {
                if (b.SLead__c != null && b.Project__c != null) {
                    String key = b.SLead__c + '-' + String.valueOf(b.Project__c);
                    if(leadToCompletedDateMap.containsKey(key)){
                       b.Site_Visit_Completed_Date__c = leadToCompletedDateMap.get(key);  
                    }
                }
            }
        }
        // Ends by ragu

        if(Trigger.isAfter && Trigger.isInsert){
            System.debug('Trigger.new --->'+Trigger.New);
			// Whats app api on 26-02-2026 starts
            for (Booking__c bk : Trigger.new) {
                if (bk.OwnerId != null) {
                    bkToSend.add(bk);
                }
                if (bk.Plot__c != null) unitIds.add(bk.Plot__c); // Created for Landowner TDS
            } 
            if (!bkToSend.isEmpty()) {
                System.enqueueJob(new BookingWhatsAppQueueable(bkToSend));
            }
            // Whats app api on 26-02-2026 ends            
            Map<Id,String> plotIds = new Map<Id,String>();
            Set<Id> leadIds = new Set<Id>();
            List<Booking__c> preSalesBookings = new List<Booking__c>();
            for(Booking__c books : trigger.new){
                if(books.Plot__c != null && books.Stage__c == 'Blocked'){
                    System.debug('Blocked booking stage----.');
                    plotIds.put(books.Plot__c,'Blocked');
                }
                if(books.SLead__c != null){
                    leadIds.add(books.SLead__c);
                }
                if(books.Pre_Sales_User__c != null){
                    preSalesBookings.add(books);
                } 
                //added by karthik 07-07
                try {
                    if (books.Plot__c != null) {
                        Set<String> crmExecUserIds = BookingController.getUserIdsFromGroup('CRM_Executives_Group');
                        
                        if (!crmExecUserIds.isEmpty()) {
                            BookingController.sendCustomNotification(crmExecUserIds,'New Booking Notification','A new booking has been created for unit ' + books.Plot__r.Name + '.',
                                books.Plot__c,'Notification_for_Blocked');
                        }
                    }
                } catch (Exception e) {
                    System.debug('Failed to send group notification for Booking: ' + books.Id + ' - ' + e.getMessage());
                }
            }
            if(plotIds.size()>0){
                BookingController.changeUnitStatus(plotIds);
            }
            if (!Test.isRunningTest()) {
                if(leadIds.size()>0){
                    BookingController.changeLeadStatus(leadIds);
                }
            }
            if(preSalesBookings.size()>0){
                manulaSharingClass.shareBookingRecord(preSalesBookings,'Read','PreSales');
            }

            // Added by Sivam V
            // if (Trigger.isAfter && Trigger.isInsert) {
                BookingCbsLifecycleHandler.createCbsForNewLoanBookings(Trigger.new);
            // }

            // MIS Sales Email + Bell notification on Booking creation starts - 03-10-2026
            try {
                BookingController.notifyMisSalesOnBookingCreation(Trigger.newMap.keySet());
            } catch (Exception notificationException) {
                System.debug('MIS Sales booking notification failed: ' + notificationException.getMessage());
            }
            // MIS Sales Email + Bell notification on Booking creation ends
            
       }
        
        //modified by karthik 18/04
        if(Trigger.isBefore && Trigger.isUpdate){
            Map<Id, Booking__c> bookingsNeedingValidation = new Map<Id, Booking__c>();
            
            for (Booking__c books : Trigger.new) {
                // Check for Registration_Done__c being set to true
                
                if(books.Registration_Done__c != Trigger.oldMap.get(books.Id).Registration_Done__c && books.Registration_Done__c == true) {           
                    bookingsNeedingValidation.put(books.Id, books);
                }
                
                if(books.Booking_Cancellation_Status__c != Trigger.oldmap.get(books.Id).Booking_Cancellation_Status__c && books.Booking_Cancellation_Status__c == 'Rejected'){
                    if(books.Pre_Booking_Cancellation__c == true){ 
                        books.Stage__c = 'Blocked';       
                        books.Pre_Booking_Cancellation__c = false;  
                    }
                }     
            }  
            
           
            // Validate documents if needed
            /* Commented by Ragu
                if(!bookingsNeedingValidation.isEmpty()) {
                    BookingController.validateRequiredDocuments(bookingsNeedingValidation);
                }
			*/

            // Added By Sivam V 
            // if (Trigger.isBefore && Trigger.isUpdate) {
                BookingCbsLifecycleHandler.captureLoanToSelfFundingChangeTime(Trigger.new, Trigger.oldMap);
            // }
        }
        
        
        if(Trigger.isAfter && Trigger.isDelete){
            Map<Id, Set<Id>> leadBookingIdMap = new Map<Id, Set<Id>>();
            Set<Id> leadIds = new Set<Id>();
            Set<Id> leadRecIds = new Set<Id>();
            Set<Id> NotRegleadRecIds = new Set<Id>();
            for(Booking__c bookRec : Trigger.old){
                //if(bookRec.Stage__c=='Registration' && bookRec.SLead__c != null){
                leadIds.add(bookRec.SLead__c);
                //}
            }
            
            /***********New***********/
            List<Lead> updateFinalLeads = new List<Lead>();
            Map<Lead,Integer> LdCountMap = new  Map<Lead,Integer>() ;
            for(Lead ld: [select id,name,Is_Lead_Registered__c, (select id,name from Bookings__r where Stage__c = 'Registration') from Lead where Id in:leadIds]){
                LdCountMap.put(ld,ld.Bookings__r.size());
            }
            
            for(Lead Ldrec : LdCountMap.keyset()){
                if(LdCountMap.get(Ldrec) > 0){
                    Ldrec.Is_Lead_Registered__c = true;
                    updateFinalLeads.add(Ldrec);
                }
                else{
                    Ldrec.Is_Lead_Registered__c = false;
                    updateFinalLeads.add(Ldrec);
                }
            }
            update updateFinalLeads;
            
        }
        
        if(Trigger.isAfter && Trigger.isUndelete){
            
            Set<Id> LeadIds = new Set<Id>();
            List<Lead> updateLeads = new List<Lead>();
            for (Booking__c booking : Trigger.new) {
                system.debug('Bk > '+ booking);
                if(booking.Stage__c == 'Registration' && booking.SLead__c != null){
                    LeadIds.add(booking.SLead__c);
                    system.debug('in If > '+ booking.Stage__c + ' >>> '+ booking.SLead__c);
                }
                else{
                    system.debug('in Else > '+ booking.Stage__c + ' >>> '+ booking.SLead__c);
                }
            }
            
            for(Lead ld : [select id,name,Is_Lead_Registered__c from Lead where id in: LeadIds]){
                system.debug('Ld >> '+ ld);
                if(ld.Is_Lead_Registered__c == false){
                    system.debug('In 2 If >>');
                    ld.Is_Lead_Registered__c = true;
                    updateLeads.add(ld);
                }
            }
            update updateLeads;
            
        }
        
        if(Trigger.isAfter && Trigger.isUpdate){
        Map<Id,String> plotIds = new Map<Id,String>();
        Set<Id> leadIds = new Set<Id>();
        List<Booking__c> bookingsToShare = new List<Booking__c>();
        List<Booking__c> shareBookingRecords = new List<Booking__c>();
        List<Lead> updateRegisteredLeadList = new List<Lead>();
        List<Booking__c> nocApprovedBookings = new List<Booking__c>(); //added by karthik 23-12-25
        Set<Id> bookingIds = new Set<Id>();
       
        
        for(Booking__c books : trigger.new){
           // Added for Land owner TDS starts 20-08-26
            Booking__c oldBooking = Trigger.oldMap.get(books.Id);
            if (books.Stage__c != oldBooking.Stage__c || books.Plot__c != oldBooking.Plot__c) {
                if (books.Plot__c != null) unitIds.add(books.Plot__c);
                if (oldBooking.Plot__c != null) unitIds.add(oldBooking.Plot__c);
            }
			// Ends for Land owner TDS starts 20-08-26
            // Added for Customer Delight starts 16-07-26
            BookingTriggerHandler.handleRegistrationDone(Trigger.new, Trigger.oldMap);
            // Customer Delight ends 
            /* Commented by Ragu as cancellation request process differs
            if(books.Stage__c != Trigger.oldmap.get(books.Id).Stage__c && books.Stage__c=='Cancelled'){
                BookingController.sendCancellationApproval(books.Id);
            }
            if(books.Stage__c == Trigger.oldmap.get(books.Id).Stage__c && books.Stage__c=='Cancelled' && books.Booking_Cancellation_Status__c == 'Rejected' && (books.Booking_Cancellation_Reason__c != Trigger.oldmap.get(books.Id).Booking_Cancellation_Reason__c || books.Booking_Cancellation_Date__c != Trigger.oldmap.get(books.Id).Booking_Cancellation_Date__c)){
                BookingController.sendCancellationApproval(books.Id);
            }
			Commented by Ragu as cancellation request process differs ends */

            if(books.Stage__c != Trigger.oldmap.get(books.Id).Stage__c && books.Stage__c=='Registration'){
                if(books.Plot__c != null){
                    plotIds.put(books.Plot__c,'Registered');
                }
            }

            //added by karthik 23-12-25
			if(books.Registration_Done__c == true && Trigger.oldMap.get(books.Id).Registration_Done__c == false){
                   nocApprovedBookings.add(books);
            }       
            
            if(books.Stage__c != Trigger.oldmap.get(books.Id).Stage__c && books.Stage__c=='Booked'){
                Set<String> repIds = new Set<String>();
                if(books.Plot__c != null){
                    plotIds.put(books.Plot__c,'Booked');
                }
                if(books.OwnerId != null){
                    repIds.add(books.OwnerId);
                    repIds.add(System.Label.Admin_ID);
                }
                String body = 'The Booking '+books.Name+' has been approved';
                BookingController.sendCustomNotification(repIds,'Booking Approved',body,books.Id,'Booking_Notification');
                
      
                if(!Test.isRunningTest()){
                    EMailController.sendWelcomeEmail(books.Id,'',new List<String>(),new List<String>());
                    
                    //sms modification by karthik
                    bookingIds.add(books.Id);
                    
                }
            }
            if(books.Booking_Cancellation_Status__c != Trigger.oldmap.get(books.Id).Booking_Cancellation_Status__c && books.Booking_Cancellation_Status__c == 'Approved'){
                if(books.Plot__c != null){
                    plotIds.put(books.Plot__c,'Available');
                }
                if(!Test.isRunningTest()){
                    EMailController.sendCancellationEmail(books.Id);  
                }
                
            }
            
            if(books.Booking_Cancellation_Status__c != Trigger.oldmap.get(books.Id).Booking_Cancellation_Status__c && (books.Booking_Cancellation_Status__c == 'Approved' || books.Booking_Cancellation_Status__c == 'Rejected')){
                Set<String> repIds = new Set<String>();
                if(books.OwnerId != null){
                    repIds.add(books.OwnerId);
                    repIds.add(books.Sales_User__c);
                }
                String body;
                if(books.Booking_Cancellation_Status__c=='Approved'){
                    body = 'The Booking '+books.Name+' for cancellation has been approved';
                    //leadIds.add(books.SLead__c);
                }
                else if(books.Booking_Cancellation_Status__c=='Rejected'){
                    body = 'The Booking '+books.Name+' for cancellation has been rejected';
                    
                }
                if(!Test.isRunningTest()){
                    BookingController.sendCustomNotification(repIds,'Booking Cancellation',body,books.Id,'Booking_Notification');
                }
                
            }
            if(books.OwnerId != Trigger.oldmap.get(books.Id).OwnerId){
                bookingsToShare.add(books);
            }
            
            
            // Starts to Share Lead records to Post sales Construction Added by ragu
            if(books.Stage__c != Trigger.oldmap.get(books.Id).Stage__c && (books.Stage__c=='Registration' || Trigger.oldmap.get(books.Id).Stage__c == 'Registration') && books.SLead__c != null){
                leadIds.add(books.SLead__c);
            }            
            // Ends to Share Lead records to Post sales Construction
            
        }
        
        System.debug('leadToBookingDateMap-->'+leadToBookingDateMap);
    	if(!unitIds.isEmpty()) LandOwnerTDSHandler.syncBookingByUnitIds(unitIds);
            
        if(plotIds.size()>0){
            BookingController.changeUnitStatus(plotIds);
        }
        
        // Starts to Share Lead records to Post sales Construction
        if(leadIds.size() > 0){
            List<Lead> updateFinalLeads = new List<Lead>();
            Map<Lead,Integer> LdCountMap = new  Map<Lead,Integer>() ;
            for(Lead ld: [select id,name,Is_Lead_Registered__c, (select id,name from Bookings__r where Stage__c = 'Registration') from Lead where Id in:leadIds]){
                LdCountMap.put(ld,ld.Bookings__r.size());
            }
            
            for(Lead Ldrec : LdCountMap.keyset()){
                if(LdCountMap.get(Ldrec) > 0){
                    Ldrec.Is_Lead_Registered__c = true;
                    updateFinalLeads.add(Ldrec);
                }
                else{
                    Ldrec.Is_Lead_Registered__c = false;
                    updateFinalLeads.add(Ldrec);
                }
            }
            update updateFinalLeads;
        }
        
        
        // Ends to Share Lead records to Post sales Construction
        
        
        /*if(leadIds.size()>0){
BookingController.bookingCancellations(leadIds);
}*/
        if(bookingsToShare.size()>0){
            manulaSharingClass.shareBookingRecord(bookingsToShare,'Read','PreSalesAndSales');
        }
        
        if(bookingIds.size()>0){
            
        }
        if (!nocApprovedBookings.isEmpty()) {
            BookingTriggerHandler.afterNocApproved(nocApprovedBookings);
        }
        
        
        
        /* commented by karthik 
if(bookingIds.size()>0){
SMSHandleBatch batch = new SMSHandleBatch(bookingIds, 50, 'Booking_Confirmation', 'Booking__c');
Database.executeBatch(batch, 50);
}*/
        // Added by Sivam V
        // if (Trigger.isAfter && Trigger.isUpdate) {
                BookingCbsLifecycleHandler.activateOrInactivateCbsForBookings(Trigger.new, Trigger.oldMap);
            // }
    }
      
  }
    
    
}
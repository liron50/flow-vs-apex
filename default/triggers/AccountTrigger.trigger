trigger AccountTrigger on Account (after update) {
                                    
    //when flag in account set to true (Get_Report__c = true):
    //
    //  Send the account owner email with the following input
    //  New leads related to the account: open leads with Company = account name or open leads with same email as for contact under the account
    //
    //      Output example:
    //  Please find below report for account XXX:
    //
    //  
    //  
    
    Map<Id, Account> changedAcc = new Map<Id, Account>();
    
    for(Account acc : trigger.new){
        if(acc.Get_Report__c != trigger.oldMap.get(acc.Id).Get_Report__c
            && acc.Get_Report__c){
            
            changedAcc.put(acc.Id, acc);
        }
    }
    
    if(! changedAcc.isEmpty()){
        
        Map<Id, String> accountMessage = new Map<Id, String>();
        Map<String, String> emailToAccount = new Map<String, String>();
        
        for(Account acc : changedAcc.values()){
            accountMessage.put(acc.Id, '');
        }
        
        for(Contact con : [SELECT Id,Email,AccountId FROM Contact WHERE AccountId IN :changedAcc.keyset()]){
            emailToAccount.put(con.Email, con.AccountId);
        }
        
        for(Lead leadItem : [SELECT Id,Name,Email FROM Lead WHERE Email IN :emailToAccount.keyset() AND Status = 'Open - Not Contacted']){
            accountMessage.put(emailToAccount.get(leadItem.Email), 
                accountMessage.get(emailToAccount.get(leadItem.Email)) +  '<br/>Duplicate lead? ' + leadItem.Name);
        }
        
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for(Account acc : changedAcc.values()){
            String msg = 'Please find below report for account ' + acc.Name + ':<br/><br/>';
        
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            mail.setTargetObjectId(acc.OwnerId);
            mail.setReplyTo('testing@rf.com');
            mail.setSenderDisplayName('Automation Process');
            mail.setSubject('Duplication Report for Account : ' + acc.Name);
            mail.setHtmlBody(accountMessage.get(acc.Id));
            mail.saveAsActivity  = false;
            emails.add(mail);
        }
        
        Messaging.sendEmail(emails);
    }
}
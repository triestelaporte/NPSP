/*
    Copyright (c) 2020, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2020
* @group HGE
* @group-content
* @description Controller for the Gift Entry lightning web components and procesing
* form save.
*/
public with sharing class GE_GiftEntryController {

    /*******************************************************************************************************
    * @description Creates an AuraHandledException with the specified error message
    *
    * @param errorMsg contents of the exception error messagae
    *
    * @return AuraHandledException
    */
    public static AuraHandledException returnAuraException(String errorMsg) {
        AuraHandledException ex = new AuraHandledException(errorMsg);
        ex.setMessage(errorMsg);
        return ex;
    }

    /*******************************************************************************************************
    * @description Creates an DmlException with the specified error message
    *
    * @param errorMsg contents of the exception error messagae
    *
    * @return DmlException
    */
    public static DmlException returnDmlException(String errorMsg) {
        DmlException ex = new DmlException(errorMsg);
        ex.setMessage(errorMsg);
        return ex;
    }

    /*******************************************************************************************************
    * @description Saves the data import record, dry runs the record, and returns updated
    * totals with the new row.
    * @param batchId: ID of the NPSP_Data_Import_Batch__c
    * @param dataImport: the NPSP_Data_Import__c record to update
    * @return String serialized DataImportModel
    */
    @AuraEnabled
    public static String saveAndDryRunDataImport(Id batchId, DataImport__c dataImport, String widgetData) {

        try {
            String additionalObjectJSON = GE_FormRendererService.convertWidgetDataToObjectJSON(widgetData);
            dataImport.Additional_Object_JSON__c = additionalObjectJSON;
            saveDataImport(dataImport);
            return BGE_DataImportBatchEntry_CTRL.runSingleDryRun(dataImport.Id, batchId);

        } catch (Exception ex) {
            // create custom lwc exception and throw it
            String JSONExceptionData = ERR_ExceptionData.createExceptionWrapperJSONString(ex);

            throw returnDmlException(JSONExceptionData);
        }
    }

    /*******************************************************************************************************
    * @description Takes a Data Import record from the Gift Entry form and saves it to the database.
    * @param diRecord - The DataImport__c record, as filled in by the user.
    * @return The Id of the new Opportunity record, created from the Data Import
    */
    @AuraEnabled
    public static Id saveAndProcessDataImport(DataImport__c diRecord, String widgetData, Boolean updateGift) {

        // Check for widget data and convert it to the correct format for processing
        String additionalObjectJSON = GE_FormRendererService.convertWidgetDataToObjectJSON(widgetData);
        diRecord.Additional_Object_JSON__c = additionalObjectJSON;

        // Save the Data Import record to the Database
        diRecord = saveDataImport(diRecord);

        // Run the BDI process on this new Data Import
        processDataImport(diRecord, false, updateGift);

        // Get the ID of the created Opportunity so we can return it
        Id oppId = getOpportunityIdFromImport(diRecord.Id);

        return oppId;
    }

    // START POC METHODS
    @AuraEnabled
    public static DataImport__c insertDataImport(DataImport__c diRecord, String widgetData) {
        // Check for widget data and convert it to the correct format for processing
        String additionalObjectJSON = GE_FormRendererService.convertWidgetDataToObjectJSON(widgetData);
        diRecord.Additional_Object_JSON__c = additionalObjectJSON;

        // Save the Data Import record to the Database
        diRecord = saveDataImport(diRecord);

        return diRecord;
    }

    @AuraEnabled
    public static String makePurchaseCall(String token) {
        System.debug('makePurchaseCall: ' + token);

        String jwtToken = generateJWT();

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://7jpea5zk79.execute-api.us-west-2.amazonaws.com/v1/payments/verified/purchase');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader('jwttoken', jwtToken);
        request.setHeader('sfdo.merchantids', '47b70ca4-0f6e-4c52-819f-667ae804f9d2');
        request.setHeader('sfdo.username', 'cbaxter');

        // Set the body as a JSON object...
        request.setBody('{"amount": 25, "currencyCode": "USD", "paymentMethodToken": "' + token + '", "merchantId": "47b70ca4-0f6e-4c52-819f-667ae804f9d2", "gatewayId": "f23da98a-c7aa-4637-962a-8c852e765e38", "email": "bart.simpson@example.com", "firstName": "Bart", "lastName": "Simpson", "metadata": { "campaignCode": "fake-campaign-code" }}');

        HttpResponse response = http.send(request);

        // Parse the JSON response...
        if (response.getStatusCode() != 201) {
            System.debug('The status code returned was not expected: ' +
                response.getStatusCode() + ' ' + response.getStatus());
            return JSON.serialize('Status Code: ' + response.getStatusCode() + ' JWT: ' + jwtToken);
        } else {
            System.debug(response.getBody());
            return JSON.serialize(response.getBody());
        }
    }

    private static String getSecret() {
        // TODO: Remove later, hardcoded only for early dev
        // Dev2 secret
        return 'd733100d-2fcb-4bcc-9ef2-8f27c40aa006';

        // Dev1 secret
        //return ' cdd7216e-2b19-4803-a047-68543d9dd483';
    }

    private static String generateJWT() {
        //String payload = '{"iss": "ApiKeyManager", "sub": "bart.simpson@example.com", "iat": 1582839616, "nbf": 1582839616, "exp": 1609488000, "jti": "4821d896-746b-40af-9567-d45ee73cca87", "sfdo.roles": "Payments.Purchase", "sfdo.product": "CRM", "sfdo.id": "00D6g0000000000EAA", "given_name": "Bart", "family_name": "Simpson", "name": "Bart Simpson", "crm_user_id": "bart.user@sf.org", "spc_org_id": "000000000000000"}';
        String payload = '{"iss": "ApiKeyManager","iat": 1583196101,"exp": 1614732110,"aud": "www.example.com","sub": "cbaxter","sfdo.id": "00D6g0000000000EAA","sfdo.product": "CRM","sfdo.roles": "Payments.Purchase"}';
        String secret = getSecret();
        String jwt = UTIL_Jwt.getSignedJWTFromString(payload, secret);

        // jwt generated from apex
        return jwt;

        // jwt from docs
        //return 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJBcGlLZXlNYW5hZ2VyIiwiaWF0IjoxNTgzMTk2MTAxLCJleHAiOjE2MTQ3MzIxMTAsImF1ZCI6Ind3dy5leGFtcGxlLmNvbSIsInN1YiI6ImNiYXh0ZXIiLCJzZmRvLmlkIjoiMDBENmcwMDAwMDAwMDAwRUFBIiwic2Zkby5wcm9kdWN0IjoiQ1JNIiwic2Zkby5yb2xlcyI6IlBheW1lbnRzLlB1cmNoYXNlIn0.Fk2kH8occu-tEabrYALiAN16XlIUj4vpptWGs0x8eZs';
    }

    @AuraEnabled
    public static DataImport__c updateDataImport(DataImport__c diRecord) {
        update diRecord;

        return diRecord;
    }

    @AuraEnabled
    public static String processDataImport(DataImport__c diRecord, Boolean updateGift) {
        // Run the BDI process on this new Data Import
            //processDataImport(diRecord, false, updateGift);
        // Get the ID of the created Opportunity so we can return it
            //String oppId = getOpportunityIdFromImport(diRecord.Id);
        return 'Attempted to process';
    }
    // END POC METHODS

    /*******************************************************************************************************
    * @description Set DataImport Settings that are important to Gift Entry matching
    * @return Data_Import_Settings__c diSettings object used to process gifts
    */
    private static Data_Import_Settings__c getGiftEntrySettings(Boolean updateGift) {
        Data_Import_Settings__c diSettings = Data_Import_Settings__c.getOrgDefaults();
        // If we are updating an existing gift, set the matching logic accordingly
        diSettings.Donation_Matching_Behavior__c = 
            updateGift ? BDI_DataImport_API.ExactMatchOrCreate : BDI_DataImport_API.DoNotMatch;
        return diSettings;
    }

    /*******************************************************************************************************
    * @description Takes a Data Import record and saves it to the database. If the id is already defined
    * update the record; otherwise, insert it.
    *
    * @param dataImport - The DataImport__c record, as filled in by the user.
    * @return The DataImport__c record that was saved
    */
    private static DataImport__c saveDataImport(DataImport__c dataImport) {
        try {
            if (String.isNotBlank(dataImport.Id)) {
                Database.update(dataImport);
            } else {
                Database.insert(dataImport);
            }

            return dataImport;
        } catch(Exception e) {
            String JSONExceptionData = ERR_ExceptionData.createExceptionWrapperJSONString(e);

            throw returnDmlException(JSONExceptionData);
        }
    }

    /*******************************************************************************************************
    * @description Run the DataImport process on a single gift
    * @param @param diRecord DataImport record to be processed
    * @param isDryRun Boolean to set if the process should only return import results and not process
    * @param updateGift Boolean to determine our matching criteria.
    *                   true = "single match or create" and means we are updating
    *                   false = "do not match"
    * @return void
    */
    private static void processDataImport(DataImport__c diRecord, Boolean isDryRun, Boolean updateGift) {
        Id diRecordId = diRecord.Id;

        Data_Import_Settings__c diSettings = getGiftEntrySettings(updateGift);

        List<DataImport__c> listDI = new List<DataImport__c>{diRecord};

        BDI_DataImport_API.processDataImportRecords(diSettings, listDI, isDryRun);
    } 

    /*******************************************************************************************************
    * @description Return the imported Opportunity (Donation) from a DataImport process
    * @param diObjId Id of DataImport object that created or matching this Opportunity
    * @return Id of the Opportunity
    */
    private static String getOpportunityIdFromImport(Id diRecordId) {
        try {
            DataImport__c di = [
                    SELECT DonationImported__c,
                            FailureInformation__c
                    FROM DataImport__c
                    WHERE Id = :diRecordId
            ];
            if(di.FailureInformation__c != null) {
                String JSONExceptionData = ERR_ExceptionData.createExceptionWrapperJSONString(di.FailureInformation__c);

                throw returnAuraException(JSONExceptionData);
            }
            return di.DonationImported__c;
        } catch(Exception e) {
            String JSONExceptionData = ERR_ExceptionData.createExceptionWrapperJSONString(e);

            throw returnAuraException(JSONExceptionData);
        }
    }


}
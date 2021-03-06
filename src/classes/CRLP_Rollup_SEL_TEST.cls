/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Selectors
* @description Unit Test for the Rollup Definition Custom Metadata Type object selector
*/
@isTest(IsParallel=True)
public class CRLP_Rollup_SEL_TEST {

    private static Integer rollupMdtCount = 0;

    /**
     * @description Verify that the getReferencedFieldsByObject() method returns the expected fields to be
     * queried, including validating that fields that shouldn't be queried aren't included.
     */
    @IsTest
    private static void shouldReturnExpectedFieldsToQuery() {
        CMT_UnitTestData_TEST.mockRollupCmtForAccountHC();

        Set<String> expectedFields = new Set<String>{
                'AccountId', 'CloseDate', 'Amount',
                Opportunity.Primary_Contact__c.getDescribe().getName(),
                Opportunity.Fair_Market_Value__c.getDescribe().getName()
        };
        if (UserInfo.isMultiCurrencyOrganization()) {
            expectedFields.add('CurrencyIsoCode');
        }

        // Verify that the returned set of fields exactly match the expected fields
        List<Schema.DescribeFieldResult> referencedFields = CRLP_Rollup_SEL.getReferencedFieldsByObject(Opportunity.SObjectType);
        Set<String> returnedFields = new Set<String>();
        for (DescribeFieldResult fr : referencedFields) {
            System.assert(expectedFields.contains(fr.getName()),
                    'The ' + fr.getName() + ' field is not in the expected fields set');
            returnedFields.add(fr.getName());
        }

        // Verify that the expected fields are all in the returned set of fields
        for (String fld : expectedFields) {
            System.assert(returnedFields.contains(fld), 'The ' + fld + ' field is not in the returned set of fields');
        }

        // Test that a query can be built and executed, though it's likely there will be zero rows returned
        // so don't attempt to validate the result.
        String queryFields = CRLP_Rollup_SEL.getReferencedFieldsByObjectAsString(Opportunity.SObjectType);
        String soql = 'SELECT Id,' + queryFields + ' FROM Opportunity LIMIT 1';
        System.assertEquals(0, Database.query(soql).size());
    }

    /**
     * @description Test the Rollup selector methods. Relies on hardcoded JSON deserialized
     * MDT data for these tests.
     */
    @IsTest
    static void validateRollupSelectorGetterMethodResults() {

        rollupMdtCount = CMT_UnitTestData_TEST.mockRollupCmtForAccountHC();

        String devName = CRLP_Rollup_SEL.getRollupDefinitions()[0].DeveloperName;
        String mdtId = CRLP_Rollup_SEL.getRollupDefinitions()[0].Id;

        System.assertEquals(rollupMdtCount, CRLP_Rollup_SEL.getRollupDefinitions().size(), 'There should be 2 rollup definitions');

        System.assertEquals(rollupMdtCount, CRLP_Rollup_SEL.getRollupsByDetailType().get(Opportunity.SObjectType).size(),
                'There should be 2 rollups for the Opportunity detail object');

        System.assertEquals(rollupMdtCount, CRLP_Rollup_SEL.getRollupsBySummaryType().get(Account.SObjectType).size(),
                'There should be 2 rollups for the Account summary object');

        System.assertNotEquals(null, CRLP_Rollup_SEL.getRollupIdByDeveloperName(devName),
                'There should be one Rollup that matches that dev name');

        System.assertNotEquals(null, CRLP_Rollup_SEL.getRollupById(mdtId),
                'There should be one Rollup returned');

        System.assertEquals(rollupMdtCount, CRLP_Rollup_SEL.getRollupsById().size(),
                'There should be 2 rollup definitions returned');

        System.assertEquals(1, CRLP_Rollup_SEL.getRollupsByFilterGroup().size(),
                'There should be 1 filter group that has rollups');
    }

    /**
     * @description Tests CRLP_Rollup_SEL.UNSUPPORTED_OPERATIONS_BY_ROLLUP_FIELD is set as expected.
     */
    @IsTest
    private static void shouldMatchUnsupportedOperationsMap() {

        // This should be an exact duplicate of what is in CRLP_Rollup_SEL
        Map<Schema.SObjectField, Set<String>> expectedOperationsByRollupField = new Map<Schema.SObjectField, Set<String>> {
                Schema.Rollup__mdt.Date_Field__c => new Set<String> {}, // All Operations Supported
                Schema.Rollup__mdt.Amount_Field__c => new Set<String> {
                        CRLP_Operation.RollupType.Count.name(),
                        CRLP_Operation.RollupType.First.name(),
                        CRLP_Operation.RollupType.Last.name()
                },
                Schema.Rollup__mdt.Detail_Field__c => new Set<String> {
                        CRLP_Operation.RollupType.Sum.name(),
                        CRLP_Operation.RollupType.Count.name(),
                        CRLP_Operation.RollupType.Average.name(),
                        CRLP_Operation.RollupType.Years_Donated.name(),
                        CRLP_Operation.RollupType.Donor_Streak.name(),
                        CRLP_Operation.RollupType.Best_Year.name(),
                        CRLP_Operation.RollupType.Best_Year_Total.name()
                }
        };

        System.assertEquals(expectedOperationsByRollupField, CRLP_Rollup_SEL.UNSUPPORTED_OPERATIONS_BY_ROLLUP_FIELD,
            'CRLP_Rollup_SEL.UNSUPPORTED_OPERATIONS_BY_ROLLUP_FIELD has unexpected values'
        );
    }

    /**
     * @description Validate the validateReferencedFields() method to ensure it properly identifies bad fields
     */
    @IsTest
    private static void shouldValidateFieldDescribes() {
        Map<String, Schema.DescribeFieldResult> referencedFields = new Map<String, Schema.DescribeFieldResult>();
        Map<String, Schema.DescribeFieldResult> allFields = UTIL_Describe.getAllFieldsDescribe('Account');

        Exception actualException;
        try {
            referencedFields.put('name', allFields.get('name'));
            CRLP_Rollup_SEL.validateReferencedFields(referencedFields, 'Account');

        } catch (Exception ex) {
            actualException = ex;
        }
        System.assertEquals(null, actualException, 'An exception should not have been thrown for a valid field');

        actualException = null;
        try {
            referencedFields.put('nothing', allFields.get('nothing'));
            CRLP_Rollup_SEL.validateReferencedFields(referencedFields, 'Account');

        } catch (Exception ex) {
            actualException = ex;
        }
        System.assertNotEquals(null, actualException, 'An exception should be thrown for invalid fields');
    }

    /**
     * @description Validate the getRollupDefinitionsToUse() method retrieves the correct set of Rollup definitions
     * based on the mocked Rollup__mdt records in this class and the specified RollupType enum.
     */
    @IsTest
    private static void shouldReturnExpectedRollupDefinitions() {
        rollupMdtCount = CMT_UnitTestData_TEST.mockRollupCmtForAccountHC();

        List<Rollup__mdt> rollupsAccountHC = CRLP_Rollup_SEL.getRollupDefinitionsToUse(
            CRLP_RollupProcessingOptions.RollupType.AccountHardCredit,
            CRLP_RollupProcessingOptions.RollupTypeFilter.All);
        System.assertEquals(rollupMdtCount, rollupsAccountHC.size(), 'There should be exactly two Rollups returned for AccountHardCredit');

        List<Rollup__mdt> rollups = CRLP_Rollup_SEL.getRollupDefinitionsToUse(
            CRLP_RollupProcessingOptions.RollupType.ContactHardCredit,
            CRLP_RollupProcessingOptions.RollupTypeFilter.All);
        System.assertEquals(0, rollups.size(), 'There should be exactly zero Rollup returned for ContactHardCredit');

        rollups = CRLP_Rollup_SEL.getRollupDefinitionsToUse(
            CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit,
            CRLP_RollupProcessingOptions.RollupTypeFilter.All);
        System.assertEquals(0, rollups.size(), 'There should be exactly zero Rollup returned for AccountSoftCredit');

        rollups = CRLP_Rollup_SEL.getRollupDefinitionsToUse(
            CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit,
            CRLP_RollupProcessingOptions.RollupTypeFilter.All);
        System.assertEquals(0, rollups.size(), 'There should be exactly zero Rollup returned for AccountContactSoftCredit');
    }
}
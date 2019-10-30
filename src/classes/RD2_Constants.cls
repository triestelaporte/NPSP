/*
    Copyright (c) 2019 Salesforce.org
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
* @date 2019
* @group Recurring Donations
* @description Enhanced Recurring Donations constants for specific picklist values and logic
*
*/
public inherited sharing class RD2_Constants {

    /**
    * @description Api Values of the npe03_RecurringDonation.Installment_Frequency__c picklist
    */
    public static final String FREQUENCY_MONTHLY = 'Monthly';
    public static final String FREQUENCY_WEEKLY = 'Weekly';
    public static final String FREQUENCY_YEARLY = 'Yearly';
    public static final String FREQUENCY_FIRST_AND_FIFTEENTH = '1st and 15th';

    /**
    * @description Api Values of the npe03_RecurringDonation.Day_Of_Month__c picklist
    */
    public static final String DAY_OF_MONTH_FIRST = '1';
    public static final String DAY_OF_MONTH_FIFTEENTH = '15';
    public static final String DAY_OF_MONTH_LAST_DAY = 'Last_Day';

    /**
    * @description Api Values of the npe03_RecurringDonation.Status__c picklist
    */
    public static final String STATUS_ACTIVE = 'Active';
    public static final String STATUS_LAPSED = 'Lapsed';
    public static final String STATUS_CLOSED = 'Closed';

    /**
    * @description Api Values of the npe03__RecurringDonation.RecurringType__c picklist
    */
    public static final String RECURRING_TYPE_OPEN = 'Open';

}
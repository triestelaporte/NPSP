import { LightningElement, track } from 'lwc';
import getDomainUrl from '@salesforce/apex/GE_FormRendererService.getDomainUrl';
import makePurchaseCall from '@salesforce/apex/GE_FormRendererService.makePurchaseCall';

export default class paymentsGateway extends LightningElement {

    @track domain;
    @track visualforceOrigin;
    @track visualforcePageUrl;
    @track lexOrigin;
    @track result;
    @track purchaseResult;

    get hasResult() {
        return this.result !== undefined ? true : false;
    }

    async connectedCallback() {
        let domainUrl = await getDomainUrl();
        this.domain = domainUrl.split('.')[0];
        console.log('domain: ', this.domain);
        this.visualforceOrigin = `https://${this.domain}--npsp.visualforce.com`;
        this.visualforcePageUrl = `${this.visualforceOrigin}/apex/paymentsGateway`;
        this.lexOrigin = `https://${this.domain}.lightning.force.com`;
    }

    renderedCallback() {
        let component = this;

        window.onmessage = async function (e) {
            console.log('origin: ', e.origin);
            console.log('vfOrigin: ', component.visualforceOrigin);
            if (e.data && e.origin === component.visualforceOrigin) {
                console.log('e.data: ', e.data);
                let response = JSON.parse(e.data);
                console.log('response: ', response);

                if (response.error) {
                    let error = JSON.stringify(response.error);
                    component.result = error;
                } else if (response.token) {
                    // We have a token...
                    component.result = response.token;

                    // Create JWT...

                    // Make purchase call...
                    let purchaseCallResponse = await makePurchaseCall({ token: response.token });
                    component.purchaseResult = JSON.parse(purchaseCallResponse);

                    console.log(component.purchaseResult);
                }
            }
        }
    }

    sendMessageToIframe() {
        console.log('*** sendMessageToIframe');
        this.template.querySelector('iframe').contentWindow.postMessage(
            { action: 'createToken' },
            '*'
        );
    }
}
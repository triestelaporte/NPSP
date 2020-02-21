import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
// importing jquery library  from static resource
//import SFDO_PAYMENTS_JS_SDK from '@salesforce/resourceUrl/sfdoPaymentsJsSdk';
//import SFDO_PAYMENTS_JS_SDK from '@salesforce/resourceUrl/MODIFIEDsfdoPaymentsJsSdk';
import ELEVATE_SDK from '@salesforce/resourceUrl/ElevateSdk';

export default class paymentsGateway extends LightningElement {
    sfdo;
    elementId = 'payments';
    connected = false;

    @track visualforcePageUrl;
    @track sdkSourcedUrl;

    renderedCallback() {
        console.log('%c*** renderedCallback', 'font-size: 0.5rem; font-weight: bold; color: green;');
        if (this.connected === false) {
            this.connected = true;
            this.loadStaticResource();
        }

        this.visualforcePageUrl = `https://dream-saas-8770-dev-ed--npsp.visualforce.com/apex/paymentsGateway`;
        this.sdkSourcedUrl = "https://cctokenization-webapp.s3-us-west-1.amazonaws.com/index.html";

    }

    loadStaticResource() {
        Promise.all([
            loadScript(this,ELEVATE_SDK)
        ])
            .then(() => {

                let element = this.template.querySelector("[data-name='payments']");
                console.log('Manual Dom Element Id: ', element.id);
                this.sfdo = new sfdoPaymentsJsSdk();

                this.sfdo.mount({
                    id: element.id,
                    designSystem: 'Lightning'
                })
                .catch(error => {
                    console.error(error);
                });

                /*this.sfdo.mount({
                    element: element,
                    designSystem: 'Lightning'
                })
                .catch(error => {
                    console.error(error);
                });*/

                /*this.sfdo
                    .createToken({
                        nameOnCard: 'Test Name'
                    })
                    .then(function response(resp) {
                        const token = resp.token
                        console.log('token: ', token);
                        // Handle submitting your token to Payments.
                    })
                    .catch(function handleError(err) {
                        console.error(err);
                        console.log(`Show error ${JSON.stringify(err)}`)
                    })*/
                console.log('%c*** We\'re mounted?', 'font-size: 0.5rem; font-weight: bold; color: green;');
                this.showSuccessMessage();
                //this.handlePaymentsGatewayMounting();
            })
            .catch(error => {
                this.error = error;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!!',
                        message: error.message,
                        variant: 'error',
                    }),
                );
            });
    }

    showSuccessMessage() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success!!',
                message: 'StaticResource ElevateSdk loaded successfully!!',
                variant: 'success',
            }),
        );
    }
}
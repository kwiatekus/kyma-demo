## Prerequisites

You need to have ( as manual prep)
 - an administrative access to an SAP BTP Global Account.
 - a [shared mailbox ](https://sapit-home-prod-004.launchpad.cfapps.eu10.hana.ondemand.com/site/Home?sap-language=en#rmmt2uiuser-Display?sap-ui-app-id-hint=1dc4d034-7c78-4d79-bc17-39a70945fce6).
 - a [custom SAP IAS tenant](https://help.sap.com/docs/cloud-identity-services/cloud-identity-services/get-your-tenant)
 - trust established between your global account and custom IAS tenant.
 - address of the shared maibloxbot added to administrator role collection on global account level.

Copy `env/.env-template` into `env/.env` file and fill in the missing variables:
 - Use email address of a shared mailbox (bot user) as a value for `BTP_BOT_USER`.
 - Invite bot user as as a P-user in the custom SAP IAS tenant. Having access to the shared mailbox, complete the invitation flow and set a strong password and store tha password in a secure vault. Use the password for `BTP_BOT_PASSWORD`.
 - The `env-template` assumes that canary landscape is used. It contains already proper values for `BTP_BACKEND_URL` and `BTP_CUSTOM_IAS_DOMAIN`. Adjust the values if needed.
 - Use the tenant name of your custom SAP IAS tenant as `BTP_CUSTOM_IAS_TENANT`
 - Adjust the `BTP_KYMA_PLAN`, `BTP_SA_REGION` and `BTP_KYMA_REGION`

## Automated bootstrap 

The following command ( executed from `/hack` folder) would 
 - create btp platform resources, such as subaccount, entitlements, service instances for SAP IAS Application and Kyma environment
 - craft a one-off headless kubeconfig for initial access to kyma environment
 - download and use kyma@v3 CLI to create a service account based access
 - enable docker registry in the kyma environment
 - build the image of the [bookstore service](src/bookstore) and push it to the kyma's internal docker registry.
 - deploy the bookstore service [manifests](k8s-resources/bookstore)

Pass an additional human user as a second argument in order to provide yourself access to the kyma runtime. Make sure you are also added to the users of the custom SAP IAS tenant.

```sh
cd hack 
./bootstrap.sh bla john.doe@sap.com
```



<!-- todo: initialize via hana design time services
Initialize DB manually 
```sql

CREATE SCHEMA DKOM OWNED BY DBADMIN;

CREATE TABLE DKOM.BOOKS (
     id                 VARCHAR(64)     not null,
     title              VARCHAR(64)    null,
     author             VARCHAR(64)      null,
     primary key(id)
);
``` -->

## How it works


![diagram](assets/kyma-demo.drawio.svg)


## Verify

### Read books  

`GET https://books.e9b2722.stage.kyma.ondemand.com`

### Add book

Issue JWT

```sh
export CLIENT_ID={IAS_APP_CLIENT_ID}
export CLIENT_SECRET={IAS_APP_CLIENT_SECRET}

export ENCODED_CREDENTIALS=$(echo -n "$CLIENT_ID:$CLIENT_SECRET" | base64)

curl -X POST "https://${IAS_TENANT}.accounts400.ondemand.com/oauth2/token?grant_type=client_credentials" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Basic $ENCODED_CREDENTIALS"

export TOKEN={ACCESS_TOKEN}
```

Post a book

```sh
curl  -X POST https://books.e9b2722.stage.kyma.ondemand.com -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"author":"Astrid Lindgren","title":"Pippi Goes On Board"}'  

```


## Traces

Enable `telemetry` module

Deploy Jaeger (with dependencies )and configure it as backend for traces in telemetry module:

```sh
make deploy_tracing
```

Inspect traces in browser https://jaeger.e9b2722.stage.kyma.ondemand.com/search

![traces](assets/traces.png)

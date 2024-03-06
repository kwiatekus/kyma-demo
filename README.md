## Prerequisites


<!-- [Create hana instance](https://help.sap.com/docs/hana-cloud/sap-hana-cloud-administration-guide/create-sap-hana-database-instance-in-kyma-environment?locale=en-US) -->

<!-- https://community.sap.com/t5/technology-blogs-by-sap/provisioning-sap-hana-cloud-databases-from-kyma-and-kubernetes-2-kyma/ba-p/13577215 -->

<!-- TODO: initialize using hana design time stuff -->

[Cloud Identity Services tenant](https://help.sap.com/docs/identity-provisioning?locale=en-US&version=Cloud)

## Deploy

```sh

# Make sure btp-manager, serverless are enabled in kyma runtime
make enable_kyma_modules

# Provision SAP Hana Cloud instance and create bindings
make provision_hana

# Deploy application
make deploy_app

```

Initialize DB manually 
```sql

CREATE SCHEMA DKOM OWNED BY DBADMIN;

CREATE TABLE DKOM.BOOKS (
     id                 VARCHAR(64)     not null,
     title              VARCHAR(64)    null,
     author             VARCHAR(64)      null,
     primary key(id)
);
```

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

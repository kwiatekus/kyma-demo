# Prerequisites


<!-- [Create hana instance](https://help.sap.com/docs/hana-cloud/sap-hana-cloud-administration-guide/create-sap-hana-database-instance-in-kyma-environment?locale=en-US) -->

Update `k8s-resources/hana.env` by providing hana host ([issue](https://github.tools.sap/kyma/backlog/issues/5177))

Initialize DB
```sql

CREATE SCHEMA DKOM OWNED BY DBADMIN;

CREATE TABLE DKOM.BOOKS (
     id                 VARCHAR(64)     not null,
     title              VARCHAR(64)    null,
     author             VARCHAR(64)      null,
     primary key(id)
);
```

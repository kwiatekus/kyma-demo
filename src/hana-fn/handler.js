const xsenv = require('@sap/xsenv');
const hana = require('@sap/hana-client');

const { v4: uuidv4 } = require('uuid');

var services = xsenv.getServices({
   hana: { name: 'hana' },
   hanaUrl: { name: 'hana-url' },
 });

services.hana.schema = process.env.HANA_SCHEMA;
services.hana.host = services.hanaUrl.host;
services.hana.port = services.hanaUrl.port;

const hanaConn = hana.createConnection();

var tracer = undefined;

async function queryDB(sql) {
  const span = tracer.startSpan('query-hana');
  span.setAttribute("sql", sql);
  try {
    await hanaConn.connect(services.hana);
    await hanaConn.exec('SET SCHEMA ' + services.hana.schema);
    results = await hanaConn.exec(sql);
  } catch (err) {
    console.error('queryDB ', err.message, err.stack);
    results = err.message;
  }
  finally {
    await hanaConn.disconnect()
    span.end();
  }
  return results;
}


module.exports = {
    main: async function (event, context) {
        tracer = event.tracer;
        if (event.extensions.request.method === 'GET') {
            const books = await queryDB(`SELECT * FROM BOOKS`) 
            return books
        } else if(event.extensions.request.method === 'POST'){
            let query = `insert into BOOKS values ('${uuidv4()}', '${event.extensions.request.body.title}', '${event.extensions.request.body.author}')`
            try {
                let result =  await queryDB(query)
                return `${result} book added`
            } catch (err) {
                return err.message;
            }
        }
    }
}
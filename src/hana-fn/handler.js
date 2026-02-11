const xsenv = require('@sap/xsenv');
const hana = require('@sap/hana-client');

const { v4: uuidv4 } = require('uuid');

var services = xsenv.getServices({
   hana: { name: 'hana' },
 });


const hanaConn = hana.createConnection();

var tracer = undefined;

async function queryDB(sql) {
  const span = tracer.startSpan('query-hana');
  span.setAttribute("sql", sql);
  try {
    console.log('Connecting to HANA with config: ', services.hana);
    await hanaConn.connect(services.hana);
    console.log('setting schema to ', services.hana.schema);
    await hanaConn.exec('SET SCHEMA ' + services.hana.schema);
    console.log('schema set to ', services.hana.schema);
    console.log('Executing SQL: ', sql);
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
            const books = await queryDB(`SELECT * FROM "bookstore.db::books"`) 
            return books
        } else if(event.extensions.request.method === 'POST'){
            let query = `insert into "bookstore.db::books" values ('${uuidv4()}', '${event.extensions.request.body.title}', '${event.extensions.request.body.author}')`
            try {
                let result =  await queryDB(query)
                return `${result} book added`
            } catch (err) {
                return err.message;
            }
        }
    }
}
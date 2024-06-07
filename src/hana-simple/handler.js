const hana = require('@sap/hana-client');


var conn = hana.createConnection();

var services = {
  hana: {
      password: 'b5bnQRE_x^E7IKxI',
      username: 'DBADMIN',
      schema: 'DEVOXX',
      host: 'f8ebcd28-6523-4726-9bff-1c976afd1677.hana.canary-eu10.hanacloud.ondemand.com',
      port: '443'
  }
}


module.exports = {
  main: function (event, context){
    console.log('ello')
    conn.connect(services.hana, function(err) {
        console.error(err)
        if (err) throw err;
        conn.exec('SELECT * FROM DEVOXX.BOOKS', function (err, result) {
          console.error(err)
          if (err) throw err;
          console.log(result[0]);
          conn.disconnect();
        })
      });
  } 
}  

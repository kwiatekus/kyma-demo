import hanaClient from "hdb"

var services = {
  hana: {
      password: 'b5bnQRE_x^E7IKxI',
      user: 'DBADMIN',
      schema: 'DEVOXX',
      host: 'f8ebcd28-6523-4726-9bff-1c976afd1677.hana.canary-eu10.hanacloud.ondemand.com',
      port: '443'
  }
}

let conn = hanaClient.createClient(services.hana)
conn.on('error', (err) => {
    console.err(err)
})

console.log("client created")

export function main (event, context) {

    conn.connect((err) => {
        if (err) {
            console.error(err)
        } else {
            conn.exec("SELECT * FROM DEVOXX.BOOKS", (err, result) => {
                if (err) {
                    console.error(err)
                } else {
                    conn.disconnect()
                    console.log(result)
                }
            })
        }
        return null
    })
}
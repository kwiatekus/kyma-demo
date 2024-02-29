const axios = require('axios');
const dataSrcURL = process.env.DATA_SRC_URL;

class Cache {
    constructor() {
      this.data = undefined;
    }
    // Method
    async getData() {
        if (!this.data){
            this.data = await this.fetchData() 
        }
        return this.data
    }
    async fetchData() {
      try{
        var resp = await axios.get(dataSrcURL)
        return resp.data
      } catch (err) {
        return err
      }
    }

    invalidate() {
        this.data=undefined
    }
}
  
const cache = new Cache();


module.exports = {
    main: async function (event, context) {
        if (event.extensions.request.method === 'GET') {
            return await cache.getData()
        } else if(event.extensions.request.method === 'POST'){
            if(event.extensions.request.body.title && event.extensions.request.body.author){
                try{
                    var resp = await axios.post(dataSrcURL, event.data)
                    cache.invalidate();
                    return resp.data
                  } catch (err) {
                    return err
                  }
            }
            res = event.extensions.response;
            
            res.statusMessage="'author' & 'title' required in the payload"
            res.status(400)
            return
        }
    }
}


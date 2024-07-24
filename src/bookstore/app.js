const express = require('express');
const bodyParser = require('body-parser');
const { v4: uuidv4 } = require('uuid');
//const tracing = require('./tracing.js');
const app = express();
const port = 3000;
const readBooksQuery = "SELECT * FROM BOOKS"

// const hanaLib = require('./hana.js');

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

// hanaLib.setupHana();


app.get('/v1/books', async (req, res) => {
    // try{
    //     console.log(`Running ${readBooksQuery}`)
    //     var books = await hanaLib.queryDB(readBooksQuery);
    //     res.json(books);
    // } catch (e) {
    //     console.error(`Error: ${e}`)
    //     res.status(500).send(e);
    // }    
    res.send("OK")
})

// app.post('/v1/books', async (req, res) => {
//   let title = getTitle(req.body);
//   let author = getAuthor(req.body);

//   if (title === undefined || author === undefined) {
//     console.log('No author or title received!');
//     res.sendStatus(400);
//   } else {
//     let query = `insert into BOOKS values ('${uuidv4()}', '${title}', '${author}')`
//     try {
//         let result =  await hanaLib.queryDB(query);
//         console.log(`Book ${title} by ${author} registered`);
//         res.send(`${result} book added`);
//     } catch (e) {
//         console.error(`Error: ${e}`)
//         res.status(500).send(e);
//     }
//   }
// });

var server = app.listen(port, () =>
  console.log('Example app listening on port ' + port + '!')
);

app.stop = function() {
  server.close();
};

module.exports = app;

//TODO: refactor
function getTitle(body) {
  if (body.title === undefined ) {
    return undefined;
  }
  return body.title;
}

function getAuthor(body) {
  if (body.author === undefined ) {
    return undefined;
  }
  return body.author;
}
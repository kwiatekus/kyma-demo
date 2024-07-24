const chai = require('chai');
const chaiHttp = require('chai-http');
const app = require('../src/bookstore/app');
const should = chai.should();

chai.use(chaiHttp);

it('Request without body', function(done) {
    chai.request(app)
        .post('/v1/books')
        .end(function(err, res){
        res.should.have.status(400);
        done();
        });
});

it('Request with correct body', function(done) {
    chai.request(app)
        .post('/v1/books')
        .send({"title":"AAA", "author": "BBB"})
        .end(function(err, res){
        res.should.have.status(200);
        done();
        });
});

after(async () => {
    app.stop();
});
let chai = require('chai'),
    expect = chai.expect,
    assert = chai.assert,
    should = chai.should();
let chaiHttp = require('chai-http');

chai.use(chaiHttp);

describe("Node status", function () {
    it("returns 200 OK for /status on timon", function (done) {
        chai.request('http://192.78.86.7:1323')
            .get('/status')
            .end((err, res) => {
                err.should.be.null
                res.should.have.status(200);
                res.body.should.be.eql('OK');
                done()
            });
    });
});

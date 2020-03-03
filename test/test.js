if (!global.Promise) {
    global.Promise = require('q');
}

let chai = require('chai'),
    expect = chai.expect,
    assert = chai.assert,
    should = chai.should();
let chaiHttp = require('chai-http');

chai.use(chaiHttp);

describe("Node status", () => {
    it("returns 200 OK for /status on timon", () => {
        return chai
            .request('http://localhost:11323')
            .get('/status')
            .then( (res) => {
                res.should.have.status(200);
            });
    });
});

const exec = require('child_process').exec;
let chai = require('chai'),
    expect = chai.expect,
    assert = chai.assert,
    should = chai.should();
let chaiHttp = require('chai-http');

chai.use(chaiHttp);

function pauseContainer(container) {
    var cmd = `pumba pause --duration 30s ${container}`

    return new Promise((resolve, reject) => {
        exec(cmd, (error, stdout, stderr) => {
            if (error) {
                console.log(`error: ${error.message}`);
            }
            if (stderr) {
                console.log(`stderr: ${stderr}`);
            }
            console.log(`stdout: ${stdout}`);
            resolve(stdout ? stdout : stderr);
        });
    });
}

function submitConsent(patientId) {
    console.log("Submitting consent")

    chai.request('http://localhost:11323')
        .post('/api/consent')
        .set('Content-Type', 'application/json')
        .send({
            subject: `urn:oid:2.16.840.1.113883.2.4.6.3:${patientId}`,
            custodian: "urn:oid:2.16.840.1.113883.2.4.6.1:1",
            actor: "urn:oid:2.16.840.1.113883.2.4.6.1:2",
            records: [
                {
                    consentProof: {
                        ID: `UUID + ${patientId}`,
                        title: "someproof.pdf",
                        contentType: "application/pdf",
                        hash: `hash + ${patientId}`
                    },
                    period: {
                        "start": "2020-01-01T12:00:00+02:00"
                    },
                    dataClass: [
                        "urn:oid:1.3.6.1.4.1.54851.1:MEDICAL"
                    ]
                }
            ]
        }).then( (res) => {
            console.log(`status ${res.status} for registering consent, body: ${JSON.stringify(res.body)}`)
        });
}

function waitForOk(patientId) {
    console.log("Waiting for state to propagate")

    let attemptsLeft = 10;
    const expectedValue = 'yes';
    const delayBetweenRequest = 10000;

    function check() {
        chai.request('http://localhost:21323')
            .post('/consent/check')
            .set('Content-Type', 'application/json')
            .send({
                subject: `urn:oid:2.16.840.1.113883.2.4.6.3:${patientId}`,
                custodian: "urn:oid:2.16.840.1.113883.2.4.6.1:1",
                actor: "urn:oid:2.16.840.1.113883.2.4.6.1:2",
                dataClass: "urn:oid:1.3.6.1.4.1.54851.1:MEDICAL"
            }).then( (res) => {
                console.log(`status ${res.status} for checking consent, body: ${JSON.stringify(res.body)}`)

                if (res.body.consentGiven != expectedValue) {
                    if (attemptsLeft-- != 0) {
                        setTimeout(check, delayBetweenRequest)
                    } else {
                        console.log("FAILURE");
                    }
                } else {
                    console.log("SUCCESS");
                }
            });
    }

    check();
}

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

describe("Record consent", () => {
    var currentPatient = 4;
    var containers = ["timonb", "timonc", "pumba", "pumbab", "pumbac", "notary"];

    //containers.forEach( (item) => {
        // pause container
    it("transfers consent to the other side", () => {
        pauseContainer("timonc")

        // submit consent request
        submitConsent(currentPatient);

        // poll otherside
        waitForOk(currentPatient);

        // next patient
        currentPatient++;
    });
});

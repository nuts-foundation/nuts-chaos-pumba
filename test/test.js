const exec = require('child_process').exec;
let chai = require('chai'),
    expect = chai.expect,
    assert = chai.assert,
    should = chai.should();
let chaiHttp = require('chai-http');

require("isomorphic-fetch")

chai.use(chaiHttp);

async function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function stopContainer(container) {
    //var cmd = `pumba pause --duration 150s ${container}`
    cmd = `docker stop ${container}`
    return new Promise((resolve, reject) => {
        exec(cmd, (error, stdout, stderr) => {
            resolve(stdout ? stdout : stderr);
        });
    });
}

async function startContainer(container) {
    cmd = `docker start ${container}`

    return new Promise((resolve, reject) => {
        exec(cmd, (error, stdout, stderr) => {
            resolve(stdout ? stdout : stderr);
        });
    });
}

function submitConsent(patientId) {
    //console.log(`submitting consent for ${patientId}`)

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
                        ID: `UUID-${patientId}`,
                        title: "someproof.pdf",
                        contentType: "application/pdf",
                        hash: `hash-${patientId}`
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
            //console.log(`status ${res.status} for registering consent, body: ${JSON.stringify(res.body)}`)
        });
}

async function endConsent(patientId) {
    //console.log(`submitting consent for ${patientId}`)
    var endDate = new Date()
    endDate.setDate(endDate.getDate() - 1)

    // query current consent
    var resp = fetch('http://localhost:11323/consent/query', {
        method: "POST",
        body: JSON.stringify({
            subject: `urn:oid:2.16.840.1.113883.2.4.6.3:${patientId}`,
            custodian: "urn:oid:2.16.840.1.113883.2.4.6.1:1",
            actor: "urn:oid:2.16.840.1.113883.2.4.6.1:2"
        })
    }).then(response => response.json()
    ).catch(error => {
        console.error(error);
    });

    var currentConsent = await resp;
    var previousRecordHash = currentConsent.results[0].records[0].recordHash

    data = {
        subject: `urn:oid:2.16.840.1.113883.2.4.6.3:${patientId}`,
        custodian: "urn:oid:2.16.840.1.113883.2.4.6.1:1",
        actor: "urn:oid:2.16.840.1.113883.2.4.6.1:2",
        records: [
            {
                consentProof: {
                    ID: `UUID-${patientId}`,
                    title: "someproof.pdf",
                    contentType: "application/pdf",
                    hash: `hash-${patientId}`
                },
                previousRecordHash: previousRecordHash,
                period: {
                    "start": "2020-01-01T12:00:00+02:00",
                    "end": endDate.toISOString()
                },
                dataClass: [
                    "urn:oid:1.3.6.1.4.1.54851.1:MEDICAL"
                ]
            }
        ]
    }

    chai.request('http://localhost:11323')
        .post('/api/consent')
        .set('Content-Type', 'application/json')
        .send(data)
        .then( (res) => {
            //console.log(`status ${res.status} for ending consent, body: ${JSON.stringify(res.body)}`)
    });
}

function waitForConsentValue(patientId, expectedValue, done) {
    //console.log(`checking consent for ${patientId}`)

    let attemptsLeft = 100;
    const delayBetweenRequest = 3000;
    var result = 'unknown'

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
                //console.log(`status ${res.status} for checking consent, body: ${JSON.stringify(res.body)}`)

                if (res.body.consentGiven != expectedValue) {
                    if (attemptsLeft-- != 0) {
                        setTimeout(check, delayBetweenRequest)
                    } else {
                        result = "FAILURE";
                    }
                } else {
                    result = "SUCCESS";
                }
            });
    }

    check();

    var waitForHello = timeoutms => new Promise((r, j)=>{
        var c = () => {
            if(result != 'unknown')
                r()
            else if((timeoutms -= 100) < 0)
                j('timed out!')
            else
                setTimeout(c, 100)
        }
        setTimeout(c, 100)
    })
    waitForHello(300000).then( () => {
        result.should.eql('SUCCESS')
        done()
    });
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

async function containerTest(container, patientId, test, consentValue, done) {
    stopContainer(container);

    await new Promise(r => setTimeout(r, 125000));

    // submit consent request
    test(patientId);

    startContainer(container);

    // problem with polling below if pumba gets restarted, give it 10 seconds
    await new Promise(r => setTimeout(r, 10000));

    // poll otherside
    waitForConsentValue(patientId, consentValue, done);
}

describe("Record consent", () => {
    var currentPatient = 0;
    var containers = ["timonb", "timonc", "pumba", "pumbab", "pumbac", "notary"];

    containers.forEach( (item) => {
        describe("transfers consent to the other side when stopping/starting " + item, () => {
            it("works" + item, (done) => {
                containerTest(item, currentPatient++, submitConsent, 'yes', done);
            }).timeout(300000);
        });
    });
});

describe("End consent", () => {
    var currentPatient = 0;
    var containers = ["timonb", "timonc", "pumba", "pumbab", "pumbac", "notary"];

    containers.forEach( (item) => {
        // pause container
        describe("transfers consent to the other side when pausing " + item, () => {
            it("works" + item, (done) => {
                containerTest(item, currentPatient++, endConsent, 'no', done);
            }).timeout(300000);
        });
    });
});
const hm = require('header-metadata');
const sm = require('service-metadata');
const uh = require('local://util-header.js')

let tr = uh.traceheader();
const statusCode = hm.current.statusCode;
const reasonPhrase = hm.current.reasonPhrase;

console.error(`${tr} ${statusCode} ${reasonPhrase}`);

if (hm.current.statusCode >= 400) {
    sm.setVar('var://service/error-protocol-response', statusCode.toString());
    sm.setVar('var://service/error-protocol-reason-phrase', reasonPhrase);

    session.reject(`${statusCode} ${reasonPhrase}`);
}
const hm = require('header-metadata');
const sm = require('service-metadata');

console.error(`backend service test1 ... received authorization header .... ${hm.current.get('Authorization')}`);

hm.response.statusCode = "429 Too Many Requests";
session.output.write('Rate Exceeded');
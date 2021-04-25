const sm = require('service-metadata');
const hm = require('header-metadata');
const oa = require('local://oauth-client-config.js');
const uh = require('local://util-header.js');

sm.setVar('var://service/routing-url', oa.tokenendpoint);

const clientid = oa.clientid;
const clientsecret = oa.clientsecret;
const scope = oa.scope;

hm.current.set('accept', 'application/json');
hm.current.set('content-type','application/x-www-form-urlencoded');
hm.current.set('authorization', uh.aznheader(clientid, clientsecret));

const body = encodeURI(`grant_type=client_credentials&scope=${scope}`);

session.output.write(body);

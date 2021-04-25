const sm = require('service-metadata');
const hm = require('header-metadata');
const pf = require('local://promise-factories.js');
const oa = require('local://oauth-client-config.js');
const uh = require('local://util-header.js')

function responseprocessor(response, json, resolve, reject) {
    // 400 - client error; 500 - server error
    if (response.statusCode >= 400) {

        // response-status-code =  401
        // response-reason-phrase =  'Unauthorized'
        // { error: 'invalid_client', error_description: 'The client secret supplied for a confidential client is invalid.' }

        // The status code corresponds to the error protocol response service variable. 
        // The reason phrase corresponds to the error protocol reason phrase service variable

        sm.setVar('var://service/error-protocol-response', response.statusCode.toString());
        sm.setVar('var://service/error-protocol-reason-phrase', response.reasonPhrase);

        // set service error-message svar
        reject(json.error + ": " + json.error_description)
    }
    else {
        // response.statusCode == 200:
        // { token_type: 'Bearer', expires_in: 3600, access_token: '...' scope:'scope'}
        resolve(json);
    }
}

(async function get_access_token() {
    try {
        let tr = uh.traceheader();

        console.error(`${tr} calling token endpoint...`);

        const clientid = oa.clientid;
        const clientsecret = oa.clientsecret;
        const scope = oa.scope;
        const tokenendpoint = oa.tokenendpoint;
        const sslclientprofile = oa.sslclientprofile;

        const options = {
            target: `${tokenendpoint}`, // param
            method: 'post',
            headers: {
               'accept':'application/json',
               'content-type':'application/x-www-form-urlencoded',
            //    'cache-control':'no-cache',
               'authorization': uh.aznheader(clientid, clientsecret)
            },
            sslClientProfile: sslclientprofile,
            data: encodeURI(`grant_type=client_credentials&scope=${scope}`)
        }

        const json = await pf.urlopenpromisefactory(options, responseprocessor);
        console.error(`${tr} token endpoint response: ${JSON.stringify(json)}`);

        // set authorization header
        hm.current.set('Authorization', 'Bearer ' + json.access_token);
        console.error(`${tr} bearer token azn header: ${hm.current.get('Authorization')}`);

    } catch (err) {
        console.error(`${tr} i got it...`);
        console.error(err);

        // { Error: URL open: Error when connecting to target 'https://.../token', status code: 6
        // errorMessage: 'URL open: Error when connecting to target \'.../token\', status code: 6',
        // errorCode: '0x85800040',
        // errorDescription: 'The URL target cannot be opened to read data.',
        // errorSuggestion: 'Verify that the URL target is correct and that the host is reachable and healthy.' }

        // sm.setVar('var://service/error-protocol-response', ...);
        sm.setVar('var://service/error-protocol-reason-phrase', err.errorDescription);
        // console.error("error-ignore-svar = ", sm.getVar('var://service/error-ignore'));
        // sm.setVar('var://service/error-code', err.errorCode);
        // sm.setVar('var://service/error-message', err.errorMessage);
        // console.error("formatted-error-message-svar = ", sm.getVar('var://service/formatted-error-message'))

        session.reject(err.errorMessage);
    }
})();

const urlopen = require('urlopen');
const sm = require('service-metadata');
const hm = require('header-metadata');
const fs = require('fs');
const util = require('util');

// create authorization header from client id and client secret
function aznhdr(clientid, clientsecret) {
    let up = clientid + ':' + clientsecret;
    return 'Basic ' + Buffer.from(up).toString('base64');
}

const readasync = util.promisify(fs.readFile);
const writeasync = util.promisify(fs.writeFile);
const urlopenasync = util.promisify(urlopen.open);

function readresponse(response, cb) {
    return response.readAsJSON(cb);
}

const responseasync = util.promisify(readresponse);

console.error("calling token endpoint...");

(async function get_access_token() {
    try {
        const clientid = await readasync("local:///clientid"); // param: client-id name
        const clientsecret = await readasync("local:///clientsecret"); // param: client-secret name

        const options = {
            target: 'https://dev-01567076.okta.com/oauth2/default/v1/token', // param
            method: 'post',
            headers: {
               'accept':'application/json',
               'content-type':'application/x-www-form-urlencoded',
               'cache-control':'no-cache','authorization': aznhdr(clientid, clientsecret)
            },
            sslClientProfile: 'default',
            data: encodeURI('grant_type=client_credentials&scope=zorro') // scope - param
        }
        
        let response = await urlopenasync(options);

        let json = await responseasync(response);
        handlejson(json, response.statusCode, response.reasonPhrase);
    }
    catch (error) {
        console.error(error);
        session.reject(error.errorMessage);
    }
})();

function handlejson(json, statusCode, reasonPhrase) {
    console.error(json);

    // 400 - client error; 500 - server error
    if (statusCode >= 400) {

      // response-status-code =  401
      // response-reason-phrase =  'Unauthorized'
      // { error: 'invalid_client', error_description: 'The client secret supplied for a confidential client is invalid.' }

      // The status code corresponds to the error protocol response service variable. 
      // The reason phrase corresponds to the error protocol reason phrase service variable

      sm.setVar('var://service/error-protocol-response', statusCode.toString());
      sm.setVar('var://service/error-protocol-reason-phrase', reasonPhrase);

      // sets service error-message svar
      session.reject(json.error + ": " + json.error_description);
    }

    else {
      // response.statusCode == 200:
      // { token_type: 'Bearer', expires_in: 3600, access_token: '...' scope:'scope'}

      // set authorization header
      hm.current.set('Authorization', 'Bearer ' + json.access_token);
      console.error(hm.current.get('Authorization'));

      // write output
      session.output.write(json.access_token);
    }
}

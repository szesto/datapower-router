const urlopen = require('urlopen');
const sm = require('service-metadata');
const fs = require('fs');

exports.writepromisefactory = function writepromisefactory(file, data) {
    return new Promise(function(resolve, reject) {
        fs.writeFile(file, data, function(err) {
            if (err) {
                reject(err);
            } else {
                resolve(0);
            }
        });
    });
}

exports.readpromisefactory = function readpromisefactory(file) {
    return new Promise(function(resolve, reject) {
        fs.exists(file, function(exists) {
            if (exists) {
                fs.readFile(file, function(err, data) {
                    if (err) {
                        reject(err);
                    } else {
                        resolve(data);
                    }
                });
            } else {
                reject(`file ${file} not found...`);
            }
        });
    });
}

exports.urlopenpromisefactory = function urlopenpromisefactory(options, responseprocessor) {
    return new Promise(function(resolve, reject) {
        urlopen.open(options, function(err, response) {
            if (err) {
                reject(err);
            } 
            else {
                response.readAsJSON(function(err, json) {
                    if (err) {
                        reject(err);
                    } else {
                        if (responseprocessor) {
                            return responseprocessor(response, json, resolve, reject);
                        }
                        // 400 - client error; 500 - server error
                        if (response.statusCode >= 400) {

                            // response-status-code =  401
                            // response-reason-phrase =  'Unauthorized'
                            // { error: 'invalid_client', error_description: 'The client secret supplied for a confidential client is invalid.' }
  
                            // The status code corresponds to the error protocol response service variable. 
                            // The reason phrase corresponds to the error protocol reason phrase service variable
  
                            sm.setVar('var://service/error-protocol-response', response.statusCode.toString());
                            sm.setVar('var://service/error-protocol-reason-phrase', response.reasonPhrase);
  
                            // sets service error-message svar
                            reject(json.error + ": " + json.error_description)
                        }
                        else {
                            // response.statusCode == 200:
                            // { token_type: 'Bearer', expires_in: 3600, access_token: '...' scope:'scope'}
                            resolve(json);
                        }
                    }
                });
            }
        });
    });
}

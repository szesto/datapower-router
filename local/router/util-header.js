const hm = require('header-metadata');

// create authorization header from client id and client secret
exports.aznheader = function aznheader(clientid, clientsecret) {
    return 'Basic ' + Buffer.from(`${clientid}:${clientsecret}`).toString('base64');
}

// read traceheader
exports.traceheader = function traceheader() {
    let tval = 'no-trace';
    if (session.parameters.traceheader) {
        tval = hm.current.get(session.parameters.traceheader);
        if (tval == undefined) {
            tval = 'no-trace';
        }
    }
    return `tr(${tval})`;
}

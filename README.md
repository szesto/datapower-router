# datapower-router

Datapower router is a proxy that routes incoming requests based on the request uri
and plays a role of oauth client to invoke backend services.

**Router**

Router is multi-protocol-gateway sevice in the `router` domain.

To configure datapower router, edit local://routes.xml file in the `router` domain.

`<routes>
    <route uri="/hello">
        <destination>http://localhost:8181</destination>
        <tls-client-profile>tls1</tls-client-profile>
    </route>
    <route uri="/hello/world">
        <destination>http://localhost:8282</destination>
        <tls-client-profile>tls1</tls-client-profile>
    </route>
    <route uri="/goodbye">
        <destination>http://localhost:8182</destination>
        <tls-client-profile>default</tls-client-profile>
    </route>
</routes>`

Incominig url is matched against the `uri` attribute of the `route` element.
Longest possible match is selected.

`tls-client-profile` is a name of the tls client profile configured for the router domain.

**Oauth Client**
Oauth client implements client credentials grant to obtain oauth access token.
Configure `local://oauth-client-config.js` file in the `router` domain.
Define `clientid`, `clientsecret`, `scope`, `oauth token endpoint url`, and `tls client profile`.

`exports.clientid = 'hello';
exports.clientsecret = 'world';
exports.scope = "scope";
exports.tokenendpoint = 'https://token';
exports.sslclientprofile = 'default';`

`scope` parameter is a list of scopes delimited by comma.
Oauth client configuration can be injected from secrets by tekton task at build time.

**Custom trace header**
Custom trace header is used for for logging to trace requests and replies.

Define the value of the `traceheader` parameter for stylesheets and js files.
Default value of the `traceheader` parameter is `trace`.

**Custom error messages**
Custom error handler stylesheet is `local://error-handler.xls` in the `router` domain.

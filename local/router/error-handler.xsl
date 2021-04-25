<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpconfig="http://www.datapower.param.config"
    exclude-result-prefixes="xs dp dpconfig"
    extension-element-prefixes="dp"
    version="2.0">

    <xsl:param name="dpconfig:traceheader" select="''"/>
    <xsl:variable name="th">tr(<xsl:value-of select="dp:request-header($dpconfig:traceheader)"/>)</xsl:variable>

    <xsl:variable name="error-headers" select="dp:variable('var://service/error-headers')"/>
    <xsl:variable name="error-message" select="dp:variable('var://service/error-message')"/>
    <xsl:variable name="transaction-id" select="dp:variable('var://service/transaction-id')"/>
    <xsl:variable name="error-code" select="dp:variable('var://service/error-code')"/>
    <xsl:variable name="error-subcode" select="dp:variable('var://service/error-subcode')"/>
    <xsl:variable name="formatted-error-message" select="dp:variable('var://service/formatted-error-message')"/>
    <xsl:variable name="error-protocol-response" select="dp:variable('var://service/error-protocol-response')"/>
    <xsl:variable name="error-protocol-reason-phrase" select="dp:variable('var://service/error-protocol-reason-phrase')"/>        

    <xsl:template match="/">
        <env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
            <env:Body>
                <env:Fault>
                    <faultcode>env:Client</faultcode>
                    <xsl:choose>
                        <!-- 
                            error code 0x00d30003 is returned from session.reject()
                            url do not match any of existing services
                            backend authentication failure
                            token expired
                        -->
                        <xsl:when test="$error-code = '0x00d30003' and contains($error-message, 'Route not found')">
                            <faultstring><xsl:value-of select="$th"/>, error-code = <xsl:value-of select="$error-code"/>, error-message = <xsl:value-of select="$error-message"/></faultstring>
                        </xsl:when>
                        <!-- 
                            backend is down
                            error-code = 0x01130006, 
                            error-subcode = 0x00000000, 
                            error-message = Failed to establish a backside connection
                        -->
                        <xsl:when test="$error-code = '0x01130006'">
                            <faultstring><xsl:value-of select="$th"/>, error-code = <xsl:value-of select="$error-code"/>, error-message = <xsl:value-of select="$error-message"/></faultstring>
                        </xsl:when>
                        <!-- 
                            default error message
                            datapower failure
                        -->
                        <xsl:otherwise>
                            <faultstring>
                                trace-header = <xsl:value-of select="$th"/>
                                transaction-id = <xsl:value-of select="$transaction-id"/>, 
                                error-code = <xsl:value-of select="$error-code"/>, 
                                error-subcode = <xsl:value-of select="$error-subcode"/>, 
                                error-message = <xsl:value-of select="$error-message"/>,
                                error-protocol-response = <xsl:value-of select="$error-protocol-response"/>
                                error-protocol-reason-phrase = <xsl:value-of select="$error-protocol-reason-phrase"/>
                            </faultstring>
                        </xsl:otherwise>
                    </xsl:choose>
                </env:Fault>
            </env:Body>
        </env:Envelope>
    </xsl:template>
</xsl:stylesheet>
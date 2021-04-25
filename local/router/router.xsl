<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpconfig="http://www.datapower.param.config"
    xmlns:tr="http://www.custom.trace"
    exclude-result-prefixes="xs dp dpconfig tr"
    extension-element-prefixes="dp"
    version="2.0">
    
    <xsl:param name="dpconfig:traceheader" select="''"/>

    <!-- set logging category to domain name -->
    <xsl:variable name="routes-file" select="'routes.xml'"/>
    <xsl:variable name="th">tr(<xsl:value-of select="dp:request-header($dpconfig:traceheader)"/>)</xsl:variable>

    <xsl:variable name="logpri" select="'error'"/>
    <xsl:variable name="logcat" select="'router'"/>

    <xsl:template match="/">
        <!--
        <xsl:message dp:priority="error">trace-header-name <xsl:value-of select="$dpconfig:traceheader"/>, trace-header-value <xsl:value-of select="$th"/></xsl:message>
        -->

        <!-- load routes file -->
        <xsl:variable name="routes" select="document($routes-file)/routes"/>

        <!-- get service uri -->
        <xsl:variable name="uri" select="dp:variable('var://service/URI')"/>

        <!-- find route matches -->
        <xsl:variable name="route-matches" select="$routes/route[starts-with($uri,@uri)]"/>
        <xsl:variable name="match-count" select="count($route-matches)"/>

        <xsl:message dp:priority="{$logpri}" dp:type="{$logcat}">
            <xsl:value-of select="$th"/> uri: <xsl:value-of select="$uri"/>;;route-uri: <xsl:value-of select="$route-matches/@uri"/>;;match-count: <xsl:value-of select="$match-count"/>"/>
        </xsl:message>

        <xsl:choose>
            <!-- no route matches -->
            <xsl:when test="0 = $match-count">
                <!-- log message -->
                <xsl:message dp:priority="error" dp:type="{$logcat}">
                    <xsl:value-of select="$th"/> Route not found. Service URI = <xsl:value-of select="$uri"/>
                </xsl:message>

                <!-- reject datapower transaction -->
                <dp:reject>Route not found. Service URI = <xsl:value-of select="$uri"/></dp:reject>
            </xsl:when>

            <!-- multiple route matches -->
            <xsl:when test="1 &lt; $match-count">
                <!-- log message -->
                <xsl:message dp:priority="{$logpri}" dp:type="{$logcat}">
                    <xsl:value-of select="$th"/> Multiple route matches. Match count = <xsl:value-of select="$match-count"/>. Service URI = <xsl:value-of select="$uri"/>
                </xsl:message>                
            </xsl:when>
            
            <!-- one match -->
            <xsl:otherwise>
                <!-- log message -->
                <xsl:message dp:priority="{$logpri}" dp:type="{$logcat}">
                    <xsl:value-of select="$th"/> Route match found. Service URI = <xsl:value-of select="$uri"/>. Destination: <xsl:value-of select="$route-matches/destination"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>

        <!-- for multiple route matches find longest matching uri -->
        <xsl:variable name="longest-matching-uri">
            <xsl:choose>
                <xsl:when test="1 &lt; $match-count">
                    <xsl:call-template name="find-longest-matching-uri">
                        <xsl:with-param name="route-matches-param" select="$route-matches"/>
                    </xsl:call-template>                    
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="$route-matches/@uri"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:message dp:priority="debug" dp:type="{$logcat}"><xsl:value-of select="$th"/> longest-matching-uri = <xsl:value-of select="$longest-matching-uri"/></xsl:message>

        <xsl:variable name="the-match" select="$route-matches[@uri=$longest-matching-uri]"/>

        <!-- set routing destination and tls client profile -->
        <xsl:variable name="destination" select="$the-match/destination"/>
        <xsl:variable name="tls-client-profile" select="$the-match/tls-client-profile"/>

        <xsl:message dp:priority="{$logpri}" dp:type="{$logcat}"><xsl:value-of select="$th"/> routing url: <xsl:value-of select="concat($destination,$uri)"/></xsl:message>

        <!-- set datapower routing destination -->
        <dp:set-variable name="'var://service/routing-url'" value="concat($destination,$uri)"/>
        
        <xsl:if test="string-length($tls-client-profile) &gt; 0">
            <xsl:message dp:priority="{$logpri}" dp:type="{$logcat}"><xsl:value-of select="$th"/> routing url ssl profile = <xsl:value-of select="$tls-client-profile"/></xsl:message>
            
            <!-- set datapower routing ssl profile -->
            <dp:set-variable name="'var://service/routing-url-sslprofile'" value="$tls-client-profile" />
        </xsl:if>

        <!-- write diagnostics -->

    </xsl:template>

    <!-- 
        find longest matching uri when multiple routes match input uri 
    -->
    <xsl:template name="find-longest-matching-uri">
        <xsl:param name="route-matches-param"/>
        <xsl:param name="match-index-param" select="1"/>
        <xsl:param name="current-longest-uri-param" select="''"/>

        <xsl:variable name="current-uri" select="$route-matches-param[$match-index-param]/@uri"/>

        <xsl:variable name="maybe-longest-uri">
            <xsl:choose>
                <xsl:when test="string-length($current-longest-uri-param) &gt; $current-uri">
                    <xsl:value-of select="$current-longest-uri-param"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$current-uri"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$match-index-param &lt; count($route-matches-param)">
                <xsl:call-template name="find-longest-matching-uri">
                    <xsl:with-param name="route-matches-param" select="$route-matches-param"/>
                    <xsl:with-param name="match-index-param" select="$match-index-param + 1"/>
                    <xsl:with-param name="current-longest-uri-param" select="$maybe-longest-uri"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$maybe-longest-uri"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>

</xsl:stylesheet>
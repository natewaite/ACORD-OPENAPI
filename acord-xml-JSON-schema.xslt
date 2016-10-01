<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
		xmlns:fo="http://www.w3.org/1999/XSL/Format" 
		xmlns:xs="http://www.w3.org/2001/XMLSchema" 
		xmlns:fn="http://www.w3.org/2005/xpath-functions" 
		xmlns:json="http://json.org/"
        xmlns:acord="http://acord.org">
	 	<xsl:output name="json-file" method="text" encoding="US-ASCII" media-type="text/plain"/>
		<xsl:param name="outputMessagesFolder" as="xs:string"/>
		<xsl:param name="outputElementsFolder" as="xs:string"/>
		<xsl:param name="outputAggregatesFolder" as="xs:string"/>
		<xsl:param name="inputACORDDataDictionary" as="xs:string" select="acord-data-dictionary.xml"/>
		<xsl:variable name="dictionary" select="document($inputACORDDataDictionary)"/>
		<xsl:key name="tag" match="ACORD-XML-DOC/Tags/Tag" use="@id"/>
		<xsl:key name="dataType" match="ACORD-XML-DOC/DataTypes/DataType" use="@id"/>
		<xsl:key name="attribute" match="ACORD-XML-DOC/AttributesInfo/AttributeInfo" use="@id"/>
		<xsl:key name="usage" match="ACORD-XML-DOC/Usages/TagUsage" use="@idref"/>

	<xsl:template match="/">
		<xsl:variable name="document" select="/ACORD-XML-DOC"/>
		<!-- Build out Message JSON SCHEMAS -->
		<xsl:for-each-group select="/ACORD-XML-DOC/Tags/Tag" group-by="@id">
			<xsl:variable name="tag" select="current-group()"/>
			<xsl:variable name="tagName" select="$tag/TagName"/>
			<xsl:variable name="tagType" select="$tag/@type"/>
			<xsl:if test="$tagType = 'Message'">
				<xsl:result-document href="{$outputMessagesFolder}/{$tagName}-{$tagType}.json" format="json-file">{"$schema": "http://json-schema.org/draft-04/schema#",
					<xsl:value-of select="json:strip-end-characters(acord:renderElements($tag,'Reference',$document),1)"/>}</xsl:result-document>
			</xsl:if>
		</xsl:for-each-group>
		<!-- Build out combined Elements JSON SCHEMA -->
		<xsl:result-document href="{$outputElementsFolder}acordAPI-elements.json" format="json-file">{"$schema": "http://json-schema.org/draft-04/schema#",
			<xsl:variable name="elements">
				<xsl:for-each-group select="/ACORD-XML-DOC/Tags/Tag" group-by="@id">
					<xsl:variable name="tag" select="current-group()"/>
					<xsl:variable name="tagName" select="$tag/TagName"/>
					<xsl:variable name="tagType" select="$tag/@type"/>
					<xsl:if test="$tagType = 'Element'">
						<xsl:value-of select="acord:renderElements($tag,'Normal',$document)"/>
					</xsl:if>
				</xsl:for-each-group>
			</xsl:variable>
			<xsl:value-of select="json:strip-end-characters($elements,1)"/>}</xsl:result-document>
		<!-- Build out Separate Aggregate Schema -->
		<xsl:for-each-group select="/ACORD-XML-DOC/Tags/Tag" group-by="@id">
			<xsl:variable name="tag" select="current-group()"/>
			<xsl:variable name="tagName" select="$tag/TagName"/>
			<xsl:variable name="tagType" select="$tag/@type"/>	
			<xsl:if test="$tagType = 'Aggregate'">
				<xsl:result-document href="{$outputElementsFolder}/{$tagName}-aggregate.json" format="json-file">
				<xsl:variable name="aggregates" select="acord:renderElements($tag,'Reference',$document)"/>{"$schema": "http://json-schema.org/draft-04/schema#",<xsl:value-of select="json:strip-end-characters($aggregates,1)"/>}</xsl:result-document>
			</xsl:if>
		</xsl:for-each-group>
			
			
	</xsl:template>

<!-- ACORD Meta XML to JSON Schema Functions -->
	<xsl:function name="acord:renderDocumentRoot">
		<xsl:param name="tag"/>
		<xsl:param name="document"/>
		<xsl:variable name="id" select="$tag/@id"/>
		<xsl:variable name="dataTypeObj" select="key('dataType',$tag/BaseClassName/@baseclassref,$tag)"/>
		<xsl:variable name="json">"<xsl:value-of select="$tag/TagName"/>":{<xsl:copy-of select="acord:json-DataType($tag,$document)"/>,"description":"<xsl:value-of select="json:encode-string($dataTypeObj/Desc)"/>","xml":{},"properties":{<xsl:value-of select="acord:json-baseclass($dataTypeObj,'Reference')"/>}},</xsl:variable>
		<xsl:value-of select="$json"/>
	</xsl:function>
	<xsl:function name="acord:renderElements">
		<xsl:param name="tag"/>
		<xsl:param name="kind"/>
		<xsl:param name="document"/>
		<xsl:variable name="id" select="$tag/@id"/>
		<xsl:variable name="baseClassRef" select="$tag/BaseClassName/@baseclassref"/>
		<xsl:variable name="datatyperef" select="$tag/DataTypeName/@datatyperef"/>
		<xsl:variable name="reference">
			<xsl:choose>
				<xsl:when test="string-length(normalize-space($baseClassRef)) > 0">
					<xsl:value-of select="$baseClassRef"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$datatyperef"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="dataTypeObj" select="key('dataType',$reference,$document)"/>
		<xsl:variable name="json">"<xsl:value-of select="$tag/TagName"/>":{<xsl:copy-of select="acord:json-DataType($tag,$document)"/>,"description":"<xsl:value-of select="json:encode-string($tag/Desc)"/>","xml":{},"properties":{<xsl:copy-of select="acord:json-baseclass($dataTypeObj,$kind,$document)"/>}},</xsl:variable>
		<xsl:copy-of select="$json"/>
	</xsl:function>
	<xsl:function name="acord:renderMessages">
		<!-- Renders the json schema for an ACORD Message -->
		<xsl:param name="tag"/>
		<xsl:param name="document"/>
		<xsl:variable name="id" select="$tag/@id"/>
		<xsl:variable name="baseClassRef" select="$tag/BaseClassName/@baseclassref"/>
		<xsl:variable name="datatyperef" select="$tag/DataTypeName/@datatyperef"/>
		<xsl:variable name="reference">
			<xsl:choose>
				<xsl:when test="string-length(normalize-space($baseClassRef)) > 0">
					<xsl:value-of select="$baseClassRef"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$datatyperef"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="dataTypeObj" select="key('dataType',$reference,$document)"/>
		<xsl:variable name="json">"<xsl:value-of select="$tag/TagName"/>":{<xsl:copy-of select="acord:json-DataType($tag,$document)"/>,"description":"<xsl:value-of select="json:encode-string($tag/Desc)"/>","xml":{},"properties":{<xsl:value-of select="acord:json-baseclass($dataTypeObj,'AggregateReference',$document)"/>}},</xsl:variable>
		<xsl:copy-of select="$json"/>
	</xsl:function>
	<xsl:function name="acord:json-DataType">
		<xsl:param name="tag"/>
		<xsl:param name="document"/>
		<xsl:variable name="tagType" select="$tag/@type"/>
		<xsl:variable name="dataTypeName" select="$tag/DataTypeName/@datatyperef"/>
		<xsl:variable name="baseClassRef" select="$tag/BaseClassName/@baseclassref"/>
		<xsl:variable name="reference">
			<xsl:choose>
				<xsl:when test="string-length(normalize-space($baseClassRef)) > 0">
					<xsl:value-of select="$baseClassRef"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$dataTypeName"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!--"array", "boolean", "integer", "null", "number", "object", "string" -->
		<xsl:variable name="json">
			<xsl:choose>
				<xsl:when test="$tagType = 'Aggregate' or $tagType = 'Message'">"type": "object","format":"<xsl:copy-of select="$reference"/>"</xsl:when>
				<xsl:when test="$dataTypeName = 'C-255'">"type":"string","format":"C-255"</xsl:when>
				<xsl:when test="$dataTypeName='Long'">"type":"integer","format":"int64"</xsl:when>
				<xsl:when test="$dataTypeName='Boolean'">"type":"boolean"</xsl:when>
				<xsl:when test="$dataTypeName='Date'">"type":"date","format":"date"</xsl:when>
				<xsl:when test="$dataTypeName='Time'">"type":"string","format":"time"</xsl:when>
				<xsl:when test="$dataTypeName='IndustryCode_Type'">"type":"string", "format":"IndustryCode_Type"</xsl:when>
				<xsl:when test="$dataTypeName='AssignedIdentifier'">"type":"object","format":"AssignedIdentifier"</xsl:when>
				<xsl:when test="$dataTypeName='CURRENCY'">"type":"object","format":"CURRENCY"</xsl:when>
				<xsl:when test="$dataTypeName='Decimal'">"type":"number","format":"float"</xsl:when>
				<xsl:when test="$dataTypeName='IDREF'">"type":"string","format":"IDREF"</xsl:when>
				<xsl:when test="$dataTypeName='IDREFS'">"type":"string","format":"IDREFS"</xsl:when>
				<xsl:when test="$dataTypeName='RAWBINARYDATA'">"type":"string","format":"RAWBINARYDATA"</xsl:when>
				<xsl:when test="$dataTypeName='Year'">"type":"string","format":"Year"</xsl:when>
				<xsl:when test="$dataTypeName='MethodOfPayment'">"type":"string","format":"MethodOfPayment"</xsl:when>
				<xsl:when test="$dataTypeName='ID'">"type":"string","format":"ID"</xsl:when>
				<xsl:when test="$dataTypeName='AcquisitionMethod'">"type":"string","format":"AcquisitionMethod"</xsl:when>
				<xsl:when test="$dataTypeName='C-Infinite'">"type":"string","format":"C-Infinite"</xsl:when>
				<xsl:when test="$dataTypeName='C-64'">"type":"string","format":"C-64"</xsl:when>
				<xsl:when test="$dataTypeName='C-60'">"type":"string","format":"C-60"</xsl:when>
				<xsl:when test="$tagType='Element' and string-length($dataTypeName) > 0">"type":"string","format":"<xsl:copy-of select="$reference"/>"</xsl:when>
				<xsl:otherwise>"type": "string","format":"<xsl:copy-of select="$reference"/>"</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:copy-of select="$json"/>
	</xsl:function>
	<xsl:function name="acord:json-baseclass">
		<xsl:param name="dataType"/>
		<xsl:param name="kind"/>
		<xsl:param name="document"/>
		<xsl:variable name="ExtensionBaseType" select="$dataType/Extension/BaseType/@type"/>
		
		<xsl:choose>
			<xsl:when test="string-length($ExtensionBaseType) > 0">
				<xsl:variable name="ExtDataType" select="key('dataType',$ExtensionBaseType,$document)"/>
				<xsl:copy-of select="acord:json-baseclass-groups($ExtDataType/BaseClass/Group,$kind,$document)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="json:add-params(acord:json-baseclass-attributes($dataType/BaseClass/Attributes,$kind,$document),acord:json-baseclass-groups($dataType/BaseClass/Group,$kind,$document),',')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<xsl:function name="acord:json-baseclass-attributes">
		<xsl:param name="attributes"/>
		<xsl:param name="kind"/>
		<xsl:param name="document"/>
		<xsl:variable name="jsonAttributes">
			<xsl:if test="count($attributes/Attribute) &gt; 0">
				<xsl:for-each select="$attributes/Attribute">
				<xsl:variable name="attribute" select="key('attribute',@idref,$document)"/>
				<xsl:variable name="type" select="$attribute/@type"/>
					"@<xsl:value-of select="@idref"/>":{"type":"string","format":"<xsl:value-of select="$type"/>","description":"<xsl:copy-of select="json:encode-string(key('attribute',@idref,$document)/Desc)"/>","xml":{"attribute":true,"name":"<xsl:value-of select="@idref"/>"}}<xsl:if test="position() &lt; last()">,</xsl:if></xsl:for-each>
			</xsl:if>
		</xsl:variable>
		<xsl:copy-of select="$jsonAttributes"/>
	</xsl:function>
	<xsl:function name="acord:json-baseclass-groups">
		<xsl:param name="group"/>
		<xsl:param name="kind"/>
		<xsl:param name="document"/>
		<xsl:variable name="json">
			<xsl:if test="count($group/Content) &gt; 0">
				<xsl:for-each select="$group/Content">
					<xsl:variable name="tag" select="key('tag',@idref,$document)"/>
					<xsl:variable name="type" select="$tag/@type"/>
					<xsl:variable name="tagName" select="$tag/@type"/>
					
					<xsl:variable name="dataTypeName" select="$tag/dataTypeName/@datatyperef"/>
					<xsl:variable name="usage" select="acord:json-usage(@idRef,$kind,$document)"/>
					<xsl:choose>
						<xsl:when test="$kind = 'Reference' and $type = 'Element'">
							<xsl:if test="$type != 'Entity'">"<xsl:value-of select="@idref"/>":{"$ref":"../acordAPI-elements.json#/<xsl:value-of select="@idref"/>"},</xsl:if>
						</xsl:when>
						<xsl:when test="$kind = 'Reference' and $type != 'Element'">
							<xsl:if test="$type != 'Entity'">"<xsl:value-of select="@idref"/>":{"$ref":"../aggregates/<xsl:value-of select="@idref"/>-aggregate.json#/<xsl:value-of select="@idref"/>"},</xsl:if>
						</xsl:when>
						<xsl:when test="$kind = 'AggregateReference' and $type != 'Element'">
							<xsl:if test="$type != 'Entity'">"<xsl:value-of select="@idref"/>":{"$ref":"../aggregates/<xsl:value-of select="@idref"/>-aggregate.json#/<xsl:value-of select="@idref"/>"},</xsl:if>
						</xsl:when>
						<xsl:otherwise>
							<xsl:if test="$type != 'Entity'">"<xsl:value-of select="@idref"/>":{<xsl:value-of select="acord:json-DataType($tag,$document)"/>,"description":"","properties":{<xsl:value-of select="$usage"/>}},</xsl:if>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:if test="$type = 'Entity'">
						<xsl:value-of select="acord:json-usage($tag/@id,$kind,$document)"/>,</xsl:if>
				</xsl:for-each>
			</xsl:if>
		</xsl:variable>
		<xsl:copy-of select="json:strip-end-characters($json,1)"/>
	</xsl:function>
	<xsl:function name="acord:json-usage">
		<xsl:param name="id"/>
		<xsl:param name="kind"/>
		<xsl:param name="tag"/>
		<xsl:variable name="usage" select="key('usage',$id,$tag)"/>
		<xsl:copy-of select="json:add-params(acord:json-baseclass-attributes($usage/Attributes,'$kind',$tag),acord:json-baseclass-groups($usage/Group,$kind,$tag),',')"/>
	</xsl:function>

	<!-- JSON Helper functions-->
	<xsl:function name="json:strip-end-characters" as="xs:string">
		<xsl:param name="text"/>
		<xsl:param name="strip-count"/>
		<xsl:value-of select="substring($text, 1, string-length($text) - $strip-count)"/>
	</xsl:function>
	<xsl:function name="json:add-params" as="xs:string">
		<xsl:param name="one"/>
		<xsl:param name="two"/>
		<xsl:param name="separator"/>
		<xsl:variable name="out">
			<xsl:if test="((string-length(replace($one, '^\s+|\s+$', '')) &gt; 0) and (string-length(replace($two, '^\s+|\s+$', ''))&gt;0))">
				<xsl:value-of select="replace($one, '^\s+|\s+$', '')"/>
				<xsl:value-of select="$separator"/>
				<xsl:value-of select="replace($two, '^\s+|\s+$', '')"/>
			</xsl:if>
			<xsl:if test="((string-length(replace($one, '^\s+|\s+$', '')) = 0) and (string-length(replace($two, '^\s+|\s+$', ''))&gt;0))">
				<xsl:value-of select="replace($two, '^\s+|\s+$', '')"/>
			</xsl:if>
			<xsl:if test="((string-length(replace($one, '^\s+|\s+$', '')) &gt; 0) and (string-length(replace($two, '^\s+|\s+$', ''))=0))">
				<xsl:value-of select="replace($one, '^\s+|\s+$', '')"/>
			</xsl:if>
		</xsl:variable>
		<xsl:value-of select="$out"/>
	</xsl:function>
	<xsl:function name="json:encode-string" as="xs:string">
		<xsl:param name="string" as="xs:string"/>
		<xsl:sequence select="replace(           replace(           replace(           replace(           replace(           replace(           replace(           replace(           replace($string,             '\\','\\\\'),             '/', '\\/'),             '&quot;', '\\&quot;'),             '&#xA;','\\n'),             '&#xD;','\\r'),             '&#x9;','\\t'),             '\n','\\n'),             '\r','\\r'),             '\t','\\t')"/>
	</xsl:function>
</xsl:stylesheet>
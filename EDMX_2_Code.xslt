<?xml version="1.0" encoding="utf-8" standalone="yes" ?>
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:edmx="http://schemas.microsoft.com/ado/2009/11/edmx"
                xmlns:store="http://schemas.microsoft.com/ado/2007/12/edm/EntityStoreSchemaGenerator"
                xmlns:ssdl="http://schemas.microsoft.com/ado/2009/11/edm/ssdl"
                xmlns:cs="http://schemas.microsoft.com/ado/2009/11/mapping/cs"
                xmlns:edm="http://schemas.microsoft.com/ado/2009/11/edm"
                xmlns:a="http://schemas.microsoft.com/ado/2006/04/codegeneration"
                xmlns:annotation="http://schemas.microsoft.com/ado/2009/02/edm/annotation"
                xmlns:customannotation="http://schemas.microsoft.com/ado/2013/11/edm/customannotation"
                xml:space="default" >
  <xsl:output method="text" omit-xml-declaration="yes"  />

  <xsl:template match="/">
    <xsl:apply-templates 
      select="edmx:Edmx/edmx:Runtime/edmx:ConceptualModels/edm:Schema" /> 
  </xsl:template>
  <xsl:template match="edm:Schema">
      <xsl:apply-templates select="edm:EntityType" >
        <xsl:with-param name="namespace" select="'XXXXXX.YYYYYY'" />
      </xsl:apply-templates>
    <xsl:apply-templates select="edm:ComplexType" >
      <xsl:with-param name="namespace" select="'XXXXXX.YYYYYY'" />
    </xsl:apply-templates>
  </xsl:template>

<!-- Process each of the main EDMX entities -->
  <xsl:template match="edm:EntityType|edm:ComplexType" >
    <xsl:param name="namespace" />
    <xsl:result-document method="text" href="{@Name}.cs">
    namespace <xsl:value-of select="$namespace"/>
    {
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    [Table("<xsl:value-of select="@Name"/>")]
    public class <xsl:value-of select="@Name"/>
    {
    <xsl:variable name="entityName" select="@Name"/>
    <xsl:variable name="keyField" select="edm:Key/edm:PropertyRef/@Name"/>
      <xsl:apply-templates select="edm:Property" >
        <xsl:with-param name="keyField" select="$keyField" />
        <xsl:with-param name="entityName" select="$entityName" />
      </xsl:apply-templates>
    <xsl:apply-templates select="edm:NavigationProperty">
      <xsl:with-param name="entityName" select="$entityName" />
    </xsl:apply-templates>
    }
    }
    </xsl:result-document>
 </xsl:template>
  
  <xsl:template match="edm:Property" >
    <xsl:param name="keyField" />
    <xsl:param name="entityName" />
    <!-- Check to see if this is a key field -->
    <xsl:if test="@Name=$keyField">    [Key]
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
    <!-- Does it have a fixed length -->
    <xsl:if test="@FixedLength='false'">
      <xsl:if test="@MaxLength!='Max'">    [MaxLength(<xsl:value-of select="@MaxLength"/>)]
        <xsl:text>&#10;</xsl:text>
      </xsl:if>
    </xsl:if>
    <!-- Not Nullable -->
    <xsl:if test="@Nullable='false'">    [Required]<xsl:text>&#10;</xsl:text></xsl:if>

    <!-- Is it being used as a foreign key -->
    <xsl:if test="@Name=../../edm:Association/edm:ReferentialConstraint/edm:Dependent[@Role=$entityName]/edm:PropertyRef/@Name">
      <xsl:apply-templates select="../edm:NavigationProperty" mode="fKey" >
        <xsl:with-param name="propertyName" select="@Name"/>
      </xsl:apply-templates>
      <xsl:text>&#10;</xsl:text></xsl:if>
    <!-- If we can find the column name write it out -->
    <xsl:if test="/edmx:Edmx/edmx:Runtime/edmx:Mappings/cs:Mapping/cs:EntityContainerMapping/cs:EntitySetMapping/cs:EntityTypeMapping/cs:MappingFragment[@StoreEntitySet=$entityName]/cs:ScalarProperty/@Name=current()/@Name">
    [Column("<xsl:value-of select="/edmx:Edmx/edmx:Runtime/edmx:Mappings/cs:Mapping/cs:EntityContainerMapping/cs:EntitySetMapping/cs:EntityTypeMapping/cs:MappingFragment[@StoreEntitySet=$entityName]/cs:ScalarProperty[@Name=current()/@Name]/@ColumnName" />")]
    </xsl:if>    public <xsl:choose>
      <!-- Change types for simplified c# types -->
      <xsl:when test="@Type='String'">string</xsl:when>
      <xsl:when test="@Type='Int32'">int</xsl:when>
      <xsl:when test="@Type='Time'">TimeSpan</xsl:when>
      <xsl:when test="@Type='Binary'">byte[]</xsl:when>
      <xsl:when test="@Type='Boolean'">bool</xsl:when>
      <xsl:when test="@Type='Decimal'">decimal</xsl:when>
      <xsl:otherwise><xsl:value-of select="@Type"/></xsl:otherwise>
    </xsl:choose><xsl:choose>
      <!-- Allow for nullable values -->
      <xsl:when test="@Nullable='false'"></xsl:when>
      <xsl:otherwise><xsl:if test="@Type!='String' and @Type!='Binary'">?</xsl:if></xsl:otherwise>
    </xsl:choose><xsl:text> </xsl:text><xsl:value-of select="@Name"/> { get; set; } <xsl:text>&#10;&#10;</xsl:text>
  </xsl:template>
  
  <!-- Foreign Key processing -->
  <xsl:template match="edm:NavigationProperty" mode="fKey" >
    <xsl:param name="propertyName" />
    <xsl:variable name="assSet" select="../../edm:EntityContainer/edm:AssociationSet[@Association=current()/@Relationship]/@Name"/>
    <xsl:if test="$propertyName=../../edm:Association[@Name=$assSet]/edm:ReferentialConstraint/edm:Dependent[@Role=current()/@FromRole]/edm:PropertyRef/@Name" >
      [ForeignKey("<xsl:value-of select="@Name"/>")]
    </xsl:if>
  </xsl:template>

  <xsl:template match="edm:NavigationProperty" >
    <xsl:param name="entityName" />
    <xsl:variable name="assSet" select="../../edm:EntityContainer/edm:AssociationSet[@Association=current()/@Relationship]/@Name"/>
    <xsl:choose>
      <xsl:when test="../../edm:Association[@Name=$assSet]/edm:End[@Role=$entityName]/@Multiplicity!='*'">
      public virtual ICollection<xsl:text disable-output-escaping="yes">&lt;</xsl:text><xsl:value-of select="@ToRole"/><xsl:text disable-output-escaping="yes">&gt;</xsl:text><xsl:text> </xsl:text><xsl:value-of select="@Name"/> { get; set; }
      </xsl:when>
      <xsl:otherwise>
        public virtual <xsl:value-of select="@ToRole"/><xsl:text> </xsl:text><xsl:value-of select="@Name"/> { get; set; }
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

# EDMX_2_Code
This is repository contains an XSLT file that can be used to generate C# code from an EDMX file. Really useful if you want to move away from using an EDMX.

I've used this to move a project that had 260 tables away from EDMX to CodeFirst. IT will decorate teh relevant attributes againset the properties, such as Key, ForeignKey, MaxLength etc

## How to use
1. take a copy of your EDMX file and change the file extension to XML
2. Add a reference to the XSLT file as a stylsheet in the XML file
`<?xml-stylesheet type="text/xsl" href="XSLTFile1.xslt"  ?>`
3. Edit the XSLT to use the namespace you'd like to appear in your classes
4. Use a tool such as [Oxygen XML](https://www.oxygenxml.com/) to transform the XML and create individual files for each EntityType.
5. Thats it

## Things to be aware of
1. The XSLT assumes that your table names match your EntityTypes
2. Currently it doesn't add the `Order` number on mulitple keys (I wish I had done it, as there were more multiple key tables than I remembered in the project I converted.
3. Its by no means perfect, but it generated the files in no time at all and it took me 1/2 day to switch the main solution over to using it.

## Solution code base changes you will need to make 
1. The connection string will need to be a standard connection and the `providerName` will need to be `System.Data.SqlClient`
2. Any properties you've written in other partial classes for these entities will need to be marked with the `[NotMapped]` attribute

I hope it helps

Paul

/// This ZEN Report class is a wrapper for any XSL-FO files, from which you want to generate a PDF file using the ZEN Report framework and
///  especially the <a href="http://docs.intersystems.com/latest/csp/docbook/DocBook.UI.Page.cls?KEY=GRPT_report_running#GRPT_renderserver">HotJVM Render Server</a> 
///  feature, which is at the moment not available for direct XSL-FO -> PDF genearation out-of-the-box.
/// <p>This adds a few extra lines to the beginning and the end of your XSL-FO file to make it usable with this class: 
/// <div class="SampleCode" style="padding:1em;">
/// <div>&lt;?xml version="1.0" encoding="UTF-8"?&gt;</div>
/// <div style="color:red;font-style:italic;">&lt;xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"&gt;</div>
/// <div style="color:red;font-style:italic;">&lt;xsl:template match="/"&gt;</div>
/// <div>&lt;fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:zr="http://www.intersystems.com/zenreports" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:svg="http://www.w3.org/2000/svg"&gt;</div>
/// <div>&nbsp;&nbsp;&lt;!-- XSL-FO content --&gt;</div>
/// <div>&lt;/fo:root&gt;</div>
/// <div style="color:red;font-style:italic;">&lt;/xsl:template&gt;</div>
/// <div style="color:red;font-style:italic;">&lt;/xsl:stylesheet&gt;</div>
/// </div>
/// <p>The report can be started either via HTTP request (from a browser) or from the background, using the
///  <a href="%25CSP.Documatic.cls?PAGE=CLASS&CLASSNAME=%25ZEN.Report.reportPage#GenerateReport">GenerateReport()</a> 
///  or the <a href="%25CSP.Documatic.cls?PAGE=CLASS&CLASSNAME=%25ZEN.Report.reportPage#AsynchGenerateReport">AsynchGenerateReport()</a> method!</p>
Class ZEN.Report.FOWrapper Extends %ZEN.Report.reportPage
{

/// Specifies the default display mode used for this report if
/// the URL parameter, <var>$MODE</var>, is not present.
Parameter DEFAULTMODE As STRING = "xml";

/// Default value for the <property>CallbackClass</property> property. This can be set in subclasses!
Parameter DEFAULTCALLBACKCLASS;

/// Default value for the <property>CallbackMethod</property> property. This can be set in subclasses!
Parameter DEFAULTCALLBACKMETHOD;

/// This is the full server-side path of the XSL-FO file. If it's not empty, the referenced file must exists 
///  in the server's filesystem, in a location, where the Caché user can open and read it!
/// <p>If the <property>CallbackClass</property> and the <property>CallbackMethod</property> are not empty 
/// and referring a valid class and method name, then this is ignored.</p>
Property FOFilename As %String(MAXLEN = "", ZENURL = "FOFILENAME");

/// If this and the <property>CallbackMethod</property> are not empty and referring a valid class and method name,
///  then the return value of the corresponding classmethod (which should be a character stream) is used as the XSL-FO file.
Property CallbackClass As %String(ZENURL = "CLASS") [ InitialExpression = {..#DEFAULTCALLBACKCLASS} ];

/// If this and the <property>CallbackClass</property> are not empty and referring a valid class and method name,
///  then the return value of the corresponding classmethod (which should be a character stream) is used as the XSL-FO file.
Property CallbackMethod As %String(ZENURL = "METHOD") [ InitialExpression = {..#DEFAULTCALLBACKMETHOD} ];

/// This callback is invoked after this report is instantiated
/// and before it is run.
Method %OnBeforeReport() As %Status [ Internal ]
{
	Set tSC = $$$OK
	
	If (..CallbackClass '= "") && (..CallbackMethod '= "") {
		TRY {
			Set tSC = $CLASSMETHOD(..CallbackClass, ..CallbackMethod, .fostream)
		}
		CATCH ex {
			Set tSC = ex.AsStatus()
		}
	}
	Else {
		Set fostream = ##class(%Stream.FileCharacter).%New()
		Set tSC = fostream.LinkToFile(..FOFilename)
	}
	
	If $$$ISOK(tSC) {
		// TODO: automatically append XSLT frame around the XSL-FO file.
		Set ..toxslfostream = ..TransformFO2XSL(.fostream)
		Do ..toxslfostream.Rewind()
	}
		
	Quit tSC
}

/// This report has a "fake" XML definition. Basically any XML would do, because the XSL-FO file is created outside of the ZEN Report class.
XData ReportDefinition [ XMLNamespace = "http://www.intersystems.com/zen/report/definition" ]
{
<report xmlns="http://www.intersystems.com/zen/report/definition"
 name="FO2PDFReport" call="FakeXML">
<!-- add definition of the report here. -->
</report>
}

/// Method, which generates the "fake" XML content of the report.
/// At the moment this contains a single element (<fofile>), which reflects the parameters of the report.'
ClassMethod FakeXML() [ Internal ]
{
	Write "<fofile" _ 
		$Case(%report.FOFilename, "": "", : " name=""" _ ##class(%File).NormalizeFilename(%report.FOFilename) _ """") _
		$Case(%report.CallbackClass, "": "", : " callbackClass=""" _ %report.CallbackClass _ """") _
		$Case(%report.CallbackMethod, "": "", : " callbackMethod=""" _ %report.CallbackMethod _ """") _
		"></fofile>"
}

/// This method can be used to test background generation of the PDF from an XSL-FO file.
/// <p>
/// <var>pOutputFile</var> is the (server-side) full path of the expected output file (PDF).<br/>
/// <var>pFoFilename</var> is the (server-side) full path of the XSL-FO input file.<br/>
/// <var>pDisplayLog</var> is 0 by default, if it's set to 1, the output file will contain the output of the FOP log instead of the PDF.</br>
/// <var>pRenderServer</var> is empty by default. If a HotJVM Render Server is used to boost the performance of the PDF generation, 
///  then this argument has to contain the port number of the configured render server. For deatailed documentation see the
///  <a href="http://docs.intersystems.com/latest/csp/docbook/DocBook.UI.Page.cls?KEY=GRPT_report_running#GRPT_renderserver">HotJVM Render Server documentation!</a>
/// </p>
ClassMethod TestFO2PDFFromFile(pOutputFile As %String, pFoFilename As %String, pDisplayLog As %Boolean = 0, pRenderServer As %String = "") As %Status
{
	Set tSC = $$$OK

	Set report = ..%New()
	Set report.FOFilename = pFoFilename
	
	Set tSC = report.GenerateReport(pOutputFile, 2, pDisplayLog, pRenderServer)
	Quit tSC
}

/// This method can be used to test background generation of the PDF from a callback method.
/// <p>
/// <var>pOutputFile</var> is the (server-side) full path of the expected output file (PDF).<br/>
/// <var>pFoFilename</var> is the (server-side) full path of the XSL-FO input file.<br/>
/// <var>pDisplayLog</var> is 0 by default, if it's set to 1, the output file will contain the output of the FOP log instead of the PDF.</br>
/// <var>pRenderServer</var> is empty by default. If a HotJVM Render Server is used to boost the performance of the PDF generation, 
///  then this argument has to contain the port number of the configured render server. For deatailed documentation see the
///  <a href="http://docs.intersystems.com/latest/csp/docbook/DocBook.UI.Page.cls?KEY=GRPT_report_running#GRPT_renderserver">HotJVM Render Server documentation!</a>
/// </p>
ClassMethod TestFO2PDFFromMethod(pOutputFile As %String, pDisplayLog As %Boolean = 0, pRenderServer As %String = "") As %Status
{
	Set tSC = $$$OK

	Set report = ..%New()
	Set report.CallbackClass = ..%ClassName(1)
	Set report.CallbackMethod = "FO2PDFCallback"
	
	Set tSC = report.GenerateReport(pOutputFile, 2, pDisplayLog, pRenderServer)
	Quit tSC
}

/// Sample callback method used by the <property>TestFO2PDFFromMethod</property> method.
ClassMethod FO2PDFCallback(ByRef pStream As %Stream.Object) As %Status
{
	Set tSC = $$$OK
	If '$IsObject($Get(pStream)) {
		Set pStream = ##class(%Stream.TmpCharacter).%New()
	} 
	
	Do pStream.Rewind()
	Do pStream.WriteLine("<?xml version=""1.0"" encoding=""utf-8""?>")
	Do pStream.WriteLine("<fo:root xmlns:fo=""http://www.w3.org/1999/XSL/Format"">")
	Do pStream.WriteLine("<fo:layout-master-set>")
	Do pStream.WriteLine("<fo:simple-page-master master-name=""simple"" page-height=""29.7cm"" page-width=""21cm"" margin-top=""1cm"" margin-bottom=""2cm"" margin-left=""2.5cm"" margin-right=""2.5cm"">")
	Do pStream.WriteLine("<fo:region-body margin-top=""3cm""/>")
	Do pStream.WriteLine("<fo:region-before extent=""3cm""/>")
	Do pStream.WriteLine("<fo:region-after extent=""1.5cm""/>")
	Do pStream.WriteLine("</fo:simple-page-master>")
	Do pStream.WriteLine("</fo:layout-master-set>")
	Do pStream.WriteLine("<fo:page-sequence master-reference=""simple"">")
	Do pStream.WriteLine("<fo:flow flow-name=""xsl-region-body"">")
	Do pStream.WriteLine("<fo:block font-size=""18pt"" font-family=""sans-serif"" line-height=""24pt"" space-after.optimum=""15pt"" background-color=""blue"" color=""white"" text-align=""center"" padding-top=""3pt"">Extensible Markup Language (XML) 1.0</fo:block>")
	Do pStream.WriteLine("</fo:flow>")
	Do pStream.WriteLine("</fo:page-sequence>")
	Do pStream.WriteLine("</fo:root>")

	Quit tSC
}

/// Appends the XSLT frame around the original XSL-FO stream, to make it usable with this report class.
ClassMethod TransformFO2XSL(ByRef pFOStream As %Stream.Object) As %Stream.Object [ Internal ]
{
	Set tSC = $$$OK
	
	Set xslStream = ##class(%Stream.TmpCharacter).%New()
	
	Do pFOStream.Rewind()
	Set first100 = pFOStream.Read(100)
	If $Extract(first100, 1, 2) = "<?" {
		Set xmlHeader = $Piece(first100, ">", 1) _ ">"
		Set first100 = $Piece(first100, ">", 2, *)
	}
	Else {
		Set xmlHeader = "" 
	}
	
	Do xslStream.WriteLine($Select(
		xmlHeader '= "": xmlHeader,
		1: "<?xml version=""1.0"" encoding=""utf-8""?>"))
	Do xslStream.WriteLine("<xsl:stylesheet version=""1.0"" xmlns:xsl=""http://www.w3.org/1999/XSL/Transform"">")
	Do xslStream.WriteLine("<xsl:template match=""/"">")
	Do xslStream.Write(first100)
	While 'pFOStream.AtEnd {
		Do xslStream.Write(pFOStream.Read(32000))
	}
	Do xslStream.WriteLine("</xsl:template>")
	Do xslStream.WriteLine("</xsl:stylesheet>")

	Quit xslStream
}

}


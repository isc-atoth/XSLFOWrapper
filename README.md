# XSL-FO Wrapper for ZEN Reports
XSL-FO wrapper for InterSystems Caché/Ensemble's ZEN Reports framework

By using this special ZEN Report class, you can generate PDFs directly from your XSL-FO files (created outside of the [ZEN Reports](http://docs.intersystems.com/latest/csp/docbook/DocBook.UI.Page.cls?KEY=GRPT) framework), while you will still able to use the [HotJVM Render Server](http://docs.intersystems.com/latest/csp/docbook/DocBook.UI.Page.cls?KEY=GRPT_report_running#GRPT_renderserver) feature of InterSystems Caché / Ensemble.  

Questions, bug reports, recommendations are highly welcome to Attila.Toth@InterSystems.com

### Installation
- Download and extract the project to a directory (\<install-dir\>).
- Import and compile all XML files onto one of your Caché / Ensemble namespaces, with the following command:
```
Do $System.OBJ.LoadDir("\<install-dir\>","c",.err,1,.list)
```

### Usage
The wrapper report can either be used via HTTP (i.e.: browser) or programatically on the server.

There are two ways to feed the wrapper with an XSL-FO file:
- If the XSL-FO file is available in the filesystem of your Caché / Ensemble server, then you can parameterize the wrapper with the full path of that file. Make sure to grant read access to the appropriate OS-user!
- The XSL-FO file can also be the return value of a class method in one of your Caché / Ensemble classes. For an example take a look at the \#\#class(ZEN.Report.FOWrapper).FO2PDFCallback() method.

The wrapper supports the FO -\> PDF generation primarily, so it's recommended to use with one of the following modes: 
- pdf (code = 2 - when started with the *GenerateReport()* method)
- xml (0)
- toxslfo (4)
- xslfo (8)

Usage examples from browser:
```
http://localhost:57772/csp/user/ZEN.Report.FOWrapper.cls?$MODE=pdf&FOFILENAME=c:\fop\in\simple.fo
http://localhost:57772/csp/user/ZEN.Report.FOWrapper.cls?$MODE=pdf&CLASS=ZEN.Report.FOWrapper&METHOD=FO2PDFCallback
```

Usage examples from command line / Caché Object Script:
``` 
	Set report = ##class(ZEN.Report.FOWrapper).%New()
	Set report.FOFilename = "c:\fop\in\simple.fo"
	; parameters: output filename, 2=pdf mode, 0 = don't display FOP-log, 59991 = Render Server port
	Do report.GenerateReport("c:\fop\out\simple.pdf", 2, 0, 59991)
```

```
	Set report = \#\#class(ZEN.Report.FOWrapper).\%New()
	Set report.CallbackClass = "ZEN.Report.FOWrapper"
	Set report.CallbackMethod = "FO2PDFCallback"
	Do report.GenerateReport("c:\fop\out\simple.pdf", 2, 0, 59991)
```

For addition information look into the class documentation and implementation of the *ZEN.Report.FOWrapper* class.

### Version history
- 1.0: Initial version
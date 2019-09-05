************************************************************************
*FUNCTION CGITEST
******************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1995
***   Contact: (541) 386-2087  / rstrahl@west-wind.com
***  Modified: 01/24/96
***  Function: Web Connect demonstration program.
***    Assume: called from WCONNECT.HTM form test.
***            Web server is running and calling
***            \cgi-win\wwcgi.dll?Method~OptionalParm1~OptionalParm2
************************************************************************
#INCLUDE FOXPRO.H

*** WCONNECT.H contains a variety of constants that are
*** used throughout the framework. The most important
*** is likely to be DEBUGMODE which sets operational mode.
*** For the shareware version DEBUGMODE is enabled to allow
*** you test, fix and track coding errors. 
#INCLUDE WCONNECT.H   

*** Optional HTML and graphics file path DEFINEs
*** I use these defines to avoid hardcoding paths when 
*** testing and then deploying on the server
#DEFINE HOMEPATH "/WCONNECT/"
#DEFINE HOMEPAGE HOMEPATH+"wconnect.htm"
#DEFINE BACKIMG HOMEPATH+"whitwav.jpg"
#DEFINE PAGEFOOT [<p><HR>]+CR+;
                 [<A HREF="http://www.west-wind.com/wwcgi.htm"><IMG SRC="/wconnect/wcpower.gif" BORDER=0 HSPACE=5 WIDTH=114 HEIGHT=42 ALIGN=LEFT ALT="Powered by Web Connection"></a>]+;
                 [<FONT SIZE=-1>Query created by <A HREF="mailto:rstrahl@west-wind.com">Rick Strahl</A><BR>]+;
                 '[<A HREF=" '+HOMEPATH+ 'wconnect.htm">Web Connection demo page</A>]'

*** Change this to point at your physical DOS HTTP home path where the
*** HTML pages are stored. This is used globally to find HTML pages
*** that contain embedded FoxPro expressions and code to be loaded.
*** In most cases this will point at the Web Servers HTML Doc directory.
*** The line before is modified by the Setup program to match the
*** selected HTML Doc directory.

*** TEMPLATE - DO NOT REMOVE - HTMLPAGEPATH
#DEFINE HTMLPAGEPATH "C:\WWW\DBSINYC\WWWROOT\INCOMING\\"
*** TEMPLATE - DO NOT REMOVE - HTMLPAGEPATH

*** The CGIServer needs to be public so we can globally access 
*** the SMTP capabilities which live as part of the form.
PUBLIC oCGIServer

*** Allow shut down by system
ON SHUTDOWN DO ShutIt IN CGITEST.PRG

#IF NOT SHAREWARE
  SET PROCEDURE TO CGIServ ADDITIVE
  SET PROCEDURE TO CGI ADDITIVE
  SET PROCEDURE TO HTML ADDITIVE
  SET PROCEDURE TO CGIPROC ADDITIVE
  SET PROCEDURE TO wwUTILS ADDITIVE
  SET PROCEDURE TO wwBanner ADDITIVE
#ELSE
  *** Loads the APP file and loads procedure files  for the above
  *** class libs into memory
  *** SHAREWARE VERSION ONLY
  DO WCONNECT
#ENDIF

*** Add data Path for data directory
DO PATH WITH "WWDEMO"

*** Starts up the server and gets it ready to poll
*** for CGI requests.
*** You can optionally pass the program name that
*** is called, in this case Process() (further down in the code),
*** and a number (0,1,2,15) to indicate the tasking priority
*** of the CGI processing operation. Higher numbers mean faster
*** operation, but affect other system processes
oCGIServer=CREATE("wwCGIServer","Process")

IF TYPE("oCGIServer")#"O"
   =MessageBox("Unable to load the CGI Request Server",;
      MB_ICONEXCLAMATION,"Web Connection Error")
   RETURN
ENDIF

*** You can also force the CGI server to process requests
*** on a remote server, thus scaling the load to
*** multiple processors. Run this session on the remote
*** and point it at the CGI temp file directory
*** over the network with this method. 
*** You can use mapped drives or UNCs across the network
*** Example: oCGIServer.SetCGIFilePath("\\server\c-drive\temp\")


*** TEMPLATE - DO NOT REMOVE - SetCGIFilePath
oCGIServer.SetCGIFilePath("c:\temp\")
*** TEMPLATE - DO NOT REMOVE - SetCGIFilePath

oCGIServer.SetLogToFile(.T.)     && Log CGI requests to CGILOG.DBF
* oCGIServer.SetStatusWindow(.F.)  && Don't update window - slightly quicker

*** This actually puts the server into polling mode
*** Displays a modal window - Server is now going!!!
oCGIServer.show(1)

*** Done
ON SHUTDOWN

RETURN


*** Once the server is running incoming CGI requests call the following
*** Process function.

*** This is a sample function that is called by the wwCGIServer class when
*** CGI request is incoming. NOTE: This program or procedure MUST accept
*** a CGI object as a parameter! This program/procedure has the name specified
*** when the server is started!

*** This is the entry point for your custom code. From here on in you can use
*** any method you see fit to create the required HTML output document. In the
*** examples below, I'll use subclasses of the wwCGIProcess class and the wwHTML
*** class to process CGI requests and output HTML text.


************************************************************************
FUNCTION Process
******************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1995
***   Contact: (541) 386-2087  / 76427,2363@compuserve.com
***  Modified: 05/24/96
***  Function: This is the program called by the CGI Server that
***            handles processing of a CGI request.
***
***            This example creates a process class, which
***            simplifies error handling and validation of
***            success. It's essentially a wrapper to create
***            the process class.
***
***      Pass: loCGI	-	Object containing CGI information
***    Return: .T. to erase Temp File .F. to keep it
************************************************************************
LPARAMETERS loCGI
LOCAL loCGIProcess, lcParameter, lcOutFile, lcIniFile

IF TYPE("loCGI")#"O"
   *** This will cause a server error, but we
   *** can't work without the CGI info
   RETURN .F.
ENDIF

*** Demonstrate how to get some CGI vars
lcParameter=UPPER(loCGI.GetCGIParameter()) && Optional CGI parameters following EXE name
*lcOutFile=TRIM(loCGI.GetOutfile())         && The output HTML file that we need to create a document for
*lcIniFile=TRIM(loCGI.GetContentFile())     && The CGI information File containing all vars and server stats

*** Now create a process object. It's not necessary
*** to use an object here, but it makes error handling
*** document and CGI handling much easier!
loCGIProcess=CREATE("WebConnectDemo",loCGI)
IF TYPE("loCGIProcess")#"O"
   *** All we can do is return...
   WAIT WINDOW NOWAIT "Unable to create CGI Processing object..."
   RETURN .F.
ENDIF

*** Call the Process Method that handles the request
loCGIProcess.Process

*** Debug: See what the input and output files look like

 RELEASE loCGIProcess  && Must release or file isn't closed
 COPY FILE (loCGI.GetContentFile()) TO TEMP.INI
 COPY FILE (loCGI.GetOutFile()) TO TEMP.HTM
RETURN


*** The following is a subclassed Process Class that implements
*** a Process method to route CGI requests to other methods of
*** the class to actually handle each incoming CGI request.

*** The parent class (in CGIPROC.PRG) implements an error method, 
*** a simple message display method as well as an INIT method 
*** that automatically initializes the CGI and HTML objects used
*** in output creation.


*************************************************************
DEFINE CLASS webConnectDemo AS wwCGIProcess
*************************************************************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1995
***   Contact: (541) 386-2087  / rstrahl@west-wind.com
***  Modified: 11/20/95
***  Function: This class handles the requests generated by
***            the wconnect.htm form and its results. The
***            class implementation makes error and output 
***            doc handling much cleaner
***
***            Subclassed from a generic wwCGIProcess class
***            handler which provides error handling and 
***            HTML and CGI object setup.
*************************************************************

*** Properties defined by wwCGIProcess Parent Class
*** -----------------------------------------------
*** oCGI=.NULL.   
*** oHTML=.NULL.  

*** Methods defined by wwCGIProcess Parent Class
*** --------------------------------------------
*** Init(oCGI)     && Initializes and checks HTML and CGI objects
*** Process        && Virtual Method that is always overridden used to route requests
*** Error          && Handles errors that occur in the Process code 
*** ErrorMsg(cErrorHeader,cMessage)  && Quick Message Display


*** You'll always create a Process method which is used to route incoming
*** CGI requests to the appropriate processing method within the wwCGIProcess
*** subclass.

*** The following CGI requests are all generated by HTML tags with the following
*** format:
***
***     /cgi-win/wwcgi.dll?Method~Optional+Parameter~Optional+Parm2
***
*** The method is an identifier that is used in the CASE statement to
*** decide which method to call to process the request. The optional parms
*** are any additional parameters that you need to pass along when
*** processing a request. Note that I use the ~ as a parameter separator
*** which is recognized by the wwCGI::GetCGIParameter(ParmNo) method to
*** separate parameters.

************************************************************************
* webConnectDemo :: Process
***************************
***  Modified: 01/24/96
***  Function: This is the callback program file that handles
***            processing a CGI request
***      Pass: THIS.oCGI	-	Object containing CGI information
***    Return: .T. to erase Temp File .F. to keep it
************************************************************************
FUNCTION Process
LOCAL lcParameter, lcOutFile, lcIniFile, lcOldError

lcParameter=UPPER(THIS.oCGI.GetCGIParameter(1)) && Optional CGI parameters following EXE name
lcOutFile=THIS.oCGI.GetOutfile()               && The output HTML file that we need to create a document for
lcIniFile=THIS.oCGI.GetContentFile()           && The CGI information File containing all vars and server stats

DO CASE
   *** Custom, non-generic Process method calls

   *** Display any dynamic file in the default HTML directory
   ***
   *** Example URL:  HREF="wwcgi.dll?DisplayPage~NoCode.wc"
   ***
   CASE lcParameter = "DISPLAYFILE" OR lcParameter="SHOWPAGE"
      =THIS.DisplayFile(THIS.oCGI.GetCGIParameter(2),HTMLPAGEPATH)


   *** Generic! Method names must the 1st parameter for the generic Method call to work.
   ***          If you use different method names or parameters a custom CASE statement
   ***          should be added *ABOVE* this line!
   *** 
   *** NOTE:    Requires Visual FoxPro 3.0b!!! If you have only 3.0 upgrade now!
   ***          3.0 users will have to paste the CASE block defined and commented out
   ***          at the end of this program. Go to the bottom of the doc and paste the
   ***          text from there in place of the PEMSTATUS() line below
   *** 
   *** Call methods that were specified on the command line's 1st parm
   ***  ie:   wwcgi.dll?Project~Method~MoreParameters

   CASE !EMPTY(lcParameter) AND PEMSTATUS(THIS,lcParameter,5)
      =EVALUATE("THIS."+lcParameter+"()")

   OTHERWISE
      *** Display an error message
      *** The error method creates an error document
      *** describing the error and overwriting any existing
      *** HTML output to the output document.
      *** Uses the HTMLError Message to create error doc
      THIS.ErrorMsg("The server was unable to respond "+;
         "to the CGI request.<br>"+;
         "Parameter Passed: '"+PROPER(lcParameter)+"'...",;
         "This error page is automatically called when a "+;
         "Visual FoxPro code error occurs while processing "+;
         "CGI requests.<p>It uses the wwHTML::HTMLError() method to "+;
         "output two error strings and generic server information, "+;
         "as well as overwriting existing HTML output for this request.")
ENDCASE

RETURN .T.


   
************************************************************************
* webConnectDemo :: TestPage
****************************
***  Modified: 12/31/95
***  Function: This is a simple example on how to process a CGI request
***            and output text.    
***
***            This routine creates a new output HTML document that
***            displays the current date and time, the CGI command line
***            and various CGI parameters and form variable commands.
***
***            Note the use of the wwHTML class, which greatly simplifies
***            creation of HTML documents. Here we're only using the
***            basic Send/SendLn methods to output text. The following
***            methods show off some of the other HTML methods available.
***
***            The only requirement is that any Fox routine responding
***            to a CGI request must output to the file name returned
***            by the CGI.GetOutFilename() method.
*************************************************************************
FUNCTION TestPage
LOCAL lcOutFile

*** Easier reference
loCGI=THIS.oCGI

*** The CGIProcess Class handles setting up the output file
*** and making sure that HTML document can be created.
*** At this point the output document is ready to be written to.
loHTML=THIS.oHTML

*** HTML Content Type header and Header Line, Browser Title
*** and Background image. All but the title is optional.
loHTML.HTMLHeader("Hello World Wide Web World!",;
                  "Hello World from Visual FoxPro",;
                  BACKIMG,"Force Reload")
loHTML.SendLn([<H2>Local time is:]+TIME()+[</H2>])
loHTML.SendPar()  && <p>
loHTML.SendLn("This page was dynamically generated by the CGI request that you see in your "+;
              "browser's 'Location' or 'Address' line.")
loHTML.Sendln("Following are a few examples of the custom methods provided by the wwCGI class that "+;
    "return common settings from CGI requests. <p>"+;
    "The usage format for your Visual FoxPro code "+;
    "is <i>loCGI.GetServerAdmin()</i> for example.")
loHTML.SendLn("<PRE>")
loHTML.SendLn("     .GetCommandLine(): "+loCGI.GetCommandLine())
loHTML.SendLn("     .GetServerAdmin(): "+loCGI.GetServerAdmin())
loHTML.SendLn("   .GetRequestMethod(): "+loCGI.GetRequestMethod())
loHTML.SendLn(" .GetRequestProtocol(): "+loCGI.GetRequestProtocol())
loHTML.SendLn("         .GetBrowser(): "+loCGI.GetBrowser())
loHTML.SendLn("         .IsNetscape(): "+IIF(loCGI.IsNetScape(),"True","False")+" (Mozilla Extension Support)")
loHTML.SendLn("         .CGIVersion(): "+loCGI.CGIVersion())
loHTML.SendLn("                        "+loCGI.GetCGIVar("CGI Version") )
loHTML.SendLn("   .GetRemoteAddress(): "+loCGI.GetRemoteAddress())
loHTML.SendLn("     .GetPreviousUrl(): "+loCGI.GetPreviousUrl())
loHTML.SendLn("      .GetOutputFile(): "+loCGI.GetOutFile()+" (output HTML File)")
loHTML.SendLn("     .GetContentFile(): "+loCGI.GetContentFile()+ " (contains CGI settings)")
loHTML.SendLn("    .GetCGIParameter(): "+loCGI.GetCGIParameter())
loHTML.SendLn("   .GetCGIParameter(1): "+loCGI.GetCGIParameter(1))
loHTML.SendLn("   .GetCGIParameter(2): "+loCGI.GetCGIParameter(2))
loHTML.SendLn("</PRE>")

loHTML.SendLn("Additional, less frequently used CGI settings can be retrieved with the <i>wwCGI::GetCGIVar()</i> method:")
loHTML.SendLn("<PRE>")
loHTML.SendLn("          Server Name: "+loCGI.GetCGIVar("Server Name"))
loHTML.SendLn("      Server Software: "+loCGI.GetCGIVar("Server Software"))
loHTML.SendLn(" Time Offset from GMT: "+loCGI.GetCGIVar("GMT Offset","System")+" seconds")
loHTML.SendLn("</PRE>")
loHTML.SendPar()

loHTML.HeaderText("H3","Retrieving Form Variables")
loHTML.SendLn("Retrieving form variables is just as easy. You can simply use "+;
   "the <i>wwCGI::GetFormVar()</i> method to retrieve any form variable as "+;
   "a string. Variables are decoded including long text fields and those "+;
   "containing control characters.")
loHTML.SendPar()
loHTML.SendLn("Here's the relevant example code from the sample form processing code in CGITEST.PRG:")

loHTML.SendLn("<PRE>")
loHTML.SendLn([*** Collect form variable values into local vars])
loHTML.SendLn([lcNotes=loCGI.GetFormVar("FormNotes")])
loHTML.SendLn([lcOrigClient=loCGI.GetFormVar("Client")])
loHTML.SendLn([lcDate1=loCGI.GetFormVar("StartDate")])
loHTML.SendLn([lcDate2=loCGI.GetFormVar("EndDate")])
loHTML.SendLn("</PRE>")

loHTML.SendLn("For more details on how you can generate Web Pages using the Form and CGI "+;
   "variables take a look at the CGITEST.PRG sample program...")

loHTML.HTMLFooter(PAGEFOOT)

RETURN
*EOP TestPage


************************************************************************
* wwConnectDemo :: ShowHours
*****************************
***  Modified: 12/31/95
***  Function: This is a more advanced example that queries a time
***            and billing database for hours spent and displays the
***            data using the ShowCursor method.
***
***            Note that the CGI/HTML code is only a small portion
***            of this code - most of the code deals with processing
***            the form parameters and setting up the query.
************************************************************************
FUNCTION ShowHours
LOCAL lcNotes,lcOrigClient,lcDate1,lcDate2, lcDateFilter, lnGrandTotal,;
      lcClient,lcOutFile

loCGI=THIS.oCGI
loHTML=THIS.oHTML

*** Collect form variable values into local vars
lcNotes=loCGI.GetFormVar("FormNotes")
lcOrigClient=loCGI.GetFormVar("Client")
lcDate1=loCGI.GetFormVar("StartDate")
lcDate2=loCGI.GetFormVar("EndDate")

lcClient=TRIM(UPPER(lcOrigClient))

*** This is the output file name
lcOutFile=loCGI.GetOutFile()

*** Process the parameter into a Filter string
lcDateFilter=""
DO CASE
   CASE !EMPTY(lcDate1) AND !EMPTY(lcDate2)
      lcDateFilter= " AND Datein >= {"+lcDate1+ "} AND Datein <= {"+lcDate2+"}"
   CASE !EMPTY(lcDate1) AND EMPTY(lcDate2)
      lcDatefilter= " AND Datein >= {"+lcDate1+"}"
   CASE EMPTY(lcDate1) AND !EMPTY(lcDate2)
      lcDatefilter= " AND Datein <= {"+lcDate2+"}"
ENDCASE


*** Run Query - Note I'm creating the Hotlink right in the query
***             to be able to use the ShowCursor method to display the
***             cursor with a single command!
SELECT ;
   [<A HREF="/cgi-win/wwcgi.dll?ShowClient~]+CHRTRAN(TRIM(tt_cust.company)," ","+")+[">]+;
       tt_cust.company+[</a>] AS Client,;
   [<A HREF="/cgi-win/wwcgi.dll?ShowSlip~]+CHRTRAN(timebill.ttId," ","+")+;
       [">]+DTOC(timebill.datein)+" - "+timebill.timein+[</a>] AS Date,;
   timebill.totalHours as Hours ;
 FROM TIMEBILL,TT_CUST ;
 WHERE UPPER(tt_cust.company)=lcClient AND ;
       TIMEBILL.custno=tt_cust.custno AND ;
       !expense ;
       &lcDateFilter ;
 INTO CURSOR TQUERY ;
 ORDER BY company,Datein

IF _TALLY<1
   THIS.ErrorMsg("No Matching Records found...",;
                 [<A HREF="]+loCGI.GetPreviousUrl()+[">Return to Test Form...</A>])
   RETURN
ENDIF

*** Create the document header
loHTML.HTMLHeader("Time Trakker Data Example",;
                  "Visual FoxPro Sample Query Result",;
                  BACKIMG)

*** Now do some more formatting for the text to display
IF EMPTY(lcClient)
   lcClient="All Clients"
ENDIF
IF EMPTY(lcDate1)
   lcDate1="No Starting Date"
ENDIF
IF EMPTY(lcDate2)
   lcDate2="No Ending Date"
ENDIF

loHTML.EnclosedText("H3","You've selected a time review for: "+lcClient)
loHTML.EnclosedText("B","From: "+lcDate1)
loHTML.sendln("<br>")
loHTML.EnclosedText("B","To: "+lcDate2)
loHTML.SendPar()

*-**** Tell Web Connection whether it's Ok to create HTML Tables
*-**** based on Browser capability
*-*loHTML.SetAllowHTMLTables(loCGI.IsNetScape())
*-*
*-**** Now show the table with default headers, no title and totals for numbers
*-*loHTML.ShowCursor(,,.T.)
*-*
*-**** Close out Page
*-*loHTML.HTMLFooter(PAGEFOOT+' [<A HREF="/wconnect/ShowHours.txt">Show Code</A>]')
*-*
*-*RETURN   

*** The Previous approach using ShowCursor is the quick and easy way to
*** display a table or cursor from a development Point of View, but there
*** is some overhead associated with this generic routine.
*** To use the code below comment out the last four lines of code.

*** If you want faster performance hand code! Speed is about
*** two to three times faster, but it takes more work <g>...

*** I like to use ShowCursor to create the table layout for me,
*** then take the HTML code from the Browser's View Source and 
*** use WRAPPER to convert it to code for me if the data sets
*** are large and time critical.

*** We have to manually sum the table
lnGrandTotal=0

*** Create Table if we're HTML 2.0 capable (Mozilla Extensions)
IF loCGI.IsNetscape()
   *** Display a Netscape table...
   loHTML.SendLn([<CENTER>])
   loHTML.SendLn([<TABLE COLSPEC="L20 L20 L20" BORDER=1 CELLPADDING=5 WIDTH="80%">])
   loHTML.SendLn([<TR><TH COLSPAN="3"><h2>Hours worked</h2></TH></TR>])
   loHTML.SendLn([<TR BGCOLOR=#FFFFCC><TH>Company</TH><TH>Date</TH><TH>Hours</TH></TR>])

   SELE TQUERY
   SCAN
      *** Note the HREF tags for client and Date are preformatted from the SELECT query
      loHTML.Send([<TR><TD>]+;
         Tquery.Client+;
         [</TD><TD >]+Tquery.Date+;
         [</TD><TD ALIGN="CENTER">]+;
         TRANSFORM(Tquery.hours,"999.99")+;
         [</TD></TR>]+CR)

      lnGrandTotal=lnGrandTotal+tquery.hours
   ENDSCAN

   loHTML.SendLn([<TR BGCOLOR=#FFFFCC><TD COLSPAN="2" ALIGN="CENTER"><h2>Grand Total:</h2></TD><TD ALIGN="CENTER"><h2>]+TRANSFORM(lnGrandTotal,"9,999.99")+[</h2></TD></TR>])
   loHTML.SendLn([</TABLE></CENTER><p><p>])
ELSE
   *** Not Netscape - Don't use a table
   loHTML.SendLn("Try running this form with Netscape - results are displayed in an HTML Table instead.")

   *** Non Netscape version - don't use HTML 3.0 table
   loHTML.SendLn("<CENTER>")
   loHTML.EnclosedText("H2","Hours worked")

   *** Preformatted text
   loHTML.SendLn("<PRE>")
   loHTML.SendLn("<B>"+PADR("Company",34)+PADR("Date",21)+PADR("Hours",6)+"</B>")
   loHTML.SendLn("<HR>")

   SCAN
      loHTML.SendLn(Tquery.Client+"    "+Tquery.Date+"    "+PADR(TRANSFORM(Tquery.hours,"999.99"),6))
      lnGrandTotal=lnGrandTotal+hours
   ENDSCAN

   loHTML.SendLn("<HR>")
   loHTML.SendLn([<h2>Grand Total:]+SPACE(44)+TRANSFORM(lnGrandTotal,"9,999.99")+[</h2>])
   loHTML.SendLn("</PRE>")
   loHTML.SendLn("</CENTER>")
ENDIF

IF !EMPTY(lcNotes)
   loHTML.SendLn([<b>And here are the notes you entered:</b><br>])
   loHTML.SendLn("<PRE>"+lcNotes+"</PRE>")
   *,.T.,65,10)
ENDIF

loHTML.HTMLFooter(PAGEFOOT)

RETURN


************************************************************************
* wwConnectDemo :: ShowHoursMulti
*********************************
***  Modified: 12/31/95
***  Function: This is a more advanced example that queries a time
***            and billing database for hours spent and displays the
***            data using the ShowCursor method.
***
***            Note that the CGI/HTML code is only a small portion
***            of this code - most of the code deals with processing
***            the form parameters and setting up the query.
************************************************************************
FUNCTION ShowHoursMulti
LOCAL lcNotes,lcOrigClient,lcDate1,lcDate2, lcDateFilter, lnGrandTotal,;
      lcClient,lcOutFile

loCGI=THIS.oCGI
loHTML=THIS.oHTML

*** Collect form variable values into local vars
lcOrigClient=loCGI.GetFormVar("Client")
lcClient=TRIM(UPPER(lcOrigClient))

*** Collect Multi items into an array
DIMENSION laNames[1]
lnCount=loCGI.GetFormMultiple(@laNames,"Client")

lcNameFilter=""
FOR x=1 to lnCount
  lcClient=TRIM(UPPER(laNames[x]))
  IF lcClient="ALL CLIENTS"
     lcNameFilter=""
     EXIT
  ENDIF
  
  IF RIGHT(lcClient,1)="*"
     lcClient=SUBSTR(lcClient,1,len(lcClient)-1)
  ENDIF

  lcNameFilter=lcNameFilter+IIF(x=1,""," OR ")+"UPPER(tt_cust.company)='"+lcClient+"'"
ENDFOR && x=1 to loCGI.GetFormMultiple
IF x=2
  lcNameFilter="AND "+lcNameFilter
ENDIF  
IF x>2
  lcNameFilter="AND ("+lcNameFilter+")"
ENDIF

lcClient=TRIM(UPPER(lcOrigClient))
IF lcClient="ALL CLIENTS"
   lcClient=""
ENDIF

*** This is the output file name
lcOutFile=loCGI.GetOutFile()

*** Run Query - Note I'm creating the Hotlink right in the query
***             to be able to use the ShowCursor method to display the
***             cursor with a single command!
SELECT ;
   [<A HREF="/cgi-win/wwcgi.dll?ShowClient~]+CHRTRAN(TRIM(tt_cust.company)," ","+")+[">]+;
       tt_cust.company+[</a>] AS Client,;
   [<A HREF="/cgi-win/wwcgi.dll?ShowSlip~]+CHRTRAN(timebill.ttId," ","+")+;
       [">]+DTOC(timebill.datein)+" - "+timebill.timein+[</a>] AS Date,;
   timebill.totalHours as Hours ;
 FROM TIMEBILL,TT_CUST ;
 WHERE TIMEBILL.custno=tt_cust.custno AND ;
       !expense ;
       &lcNameFilter ;
 INTO CURSOR TQUERY ;
 ORDER BY company,Datein

IF _TALLY<1
   THIS.ErrorMsg("No Matching Records found...",;
                 [<A HREF="]+loCGI.GetPreviousUrl()+[">Return to Test Form...</A>])
   RETURN
ENDIF

*** Create the document header
loHTML.HTMLHeader("Time Trakker Data Example",;
                  "Visual FoxPro Sample Query Result",;
                  BACKIMG)

loHTML.SendLn([<i>This table is displayed with a single line of code, using the ]+;
              [wwHTML::ShowCursor() method following a SQL-SELECT statement that ]+;
              [creates the output data including the HREF links in a cursor.</i><br><p>])


*** Tell Web Connection whether it's Ok to create HTML Tables
*** based on Browser capability
loHTML.SetAllowHTMLTables(loCGI.IsNetScape())

*** Now show the table
loHTML.SendLn([<CENTER>])
loHTML.ShowCursor(,,.T.)
loHTML.SendLn([</CENTER>])

*** Close out form
loHTML.HTMLFooter(PAGEFOOT)

RETURN   

************************************************************************
* wwConnectDemo :: ClientList
*****************************
***  Modified: 11/11/95
***  Function: Shows List of clients and allows selection of
***            Client to back fill query form by running another
***            CGI request to redraw the original form.
*************************************************************************
PROCEDURE ClientList
LOCAL loCGI, loHTML

loCGI=THIS.oCGI
loHTML=THIS.oHTML

lcOutFile = loCGI.GetOutfile()

*** Get all entries that have time entries (expense=.F.)
SELECT tt_cust.Company, MIN(expense) AS HasTimeEntries ;
   FROM TT_CUST, TIMEBILL ;
   WHERE tt_cust.custno=timebill.custno ;
   GROUP BY 1 ;
   INTO CURSOR TQuery

IF _TALLY<1
   =THIS.Error("No Clients available.")
   RETURN
ENDIF

*** Create the document header
loHTML.HTMLHeader("Complete Client Listing",;
                  "Web Connection Client List",;
                  BACKIMG)

loHTML.SendLn([Please select a client name to look up in your query. ]+;
              [To select pick a client from the listbox below and press the ]+;
              ['Fill Client Name' button to fill the value into the query form.<p>])

loHTML.SendLn("<i><b>*</b> --- Client has time entries to review.</i><p>")

loHTML.SendLn([<FORM  ACTION="/cgi-win/wwcgi.dll?FillQueryForm" METHOD="POST">])


*** Create Popup with loHTML.DBFPopup
***
*-* DBFPopup Parms:
*-*            lcFormVarName, lcCharExpression, lcDefault, ;
*-*            lcFirstItem, lnHeight, llNoOutput
loHTML.DBFPopup("Client",[TRIM(TQuery.company)+IIF(!Tquery.HasTimeEntries,'*','')],;
                ,,10)

*-**** The above is the same code as the following:
*-*loHTML.SendLn([<SELECT NAME="Client" SIZE=10>])
*-*loHTML.SendLn([<OPTION SELECTED>None</A>])
*-*SCAN
*-*   loHTML.SendLn([<OPTION>]+TRIM(TQuery.company)+IIF(!HasTimeEntries,"*",""))
*-*ENDSCAN
*-*USE IN TQUery
*-*loHTML.SendLn([</SELECT><p>])

loHTML.SendLn("<BR>")
loHTML.SendLn([<INPUT TYPE="SUBMIT" NAME="SubmitButton"  VALUE="Fill Client Name">])
loHTML.SendLn([</FORM>])

loHTML.HTMLFooter(PAGEFOOT)
RETURN

************************************************************************
PROCEDURE FillQueryForm
***********************
***  Modified: 11/20/95
***  Function: Back fills the Client name from the picklist of
***            Clients in ClientList
*************************************************************************
LOCAL lcName, lnPlusSign

*** Grab CGI Form var
lcName=TRIM(THIS.oCGI.GetFormVar("Client"))

*** Fix up name - remove * and catch NONE entries
IF RIGHT(lcName,1)="*"
   lcName=SUBSTR(lcName,1,len(lcName)-1)
ENDIF
IF UPPER(lcName)="NONE"
   lcName=""
ENDIF   

loHTML=THIS.oHTML

loHTML.HTMLHeader([<IMG SRC="/wconnect.gif">],;
                  [Web Connection Sample Form],;
                  BACKIMG)
              
*** This form code was simply captured from the View Source
*** option of the wconnect.htm form and then converted to code 
*** with DO FORM WRAPPER and pasted here.
              
loHTML.SendLn([<A HREF="/cgi-win/wwcgi.dll?Test_Page">Simple CGI Test</A><P>])
loHTML.SendLn([The following example form allows you to query a time and billing ]+;
              [database by selecting a client name and date range. To see a list ]+;
              [of clients and pick one from the list click on the Client Name ]+;
              [header button.<p>])
loHTML.SendLn([<FORM  ACTION="/cgi-win/wwcgi.dll?ShowHours" METHOD="POST">])
loHTML.SendLn([<A HREF="/cgi-win/wwcgi.dll?ClientList"><B>Client Name:</B></A><br>])

*** This is where we're setting the variable name
loHTML.SendLn([<INPUT NAME="Client" TYPE="TEXT" VALUE="]+lcName+[" ROWS=1 SIZE="40">])

loHTML.SendLn([<p>])
loHTML.SendLn([<PRE>])
loHTML.SendLn([<B>From: </B><INPUT NAME="StartDate" TYPE="TEXT" ROWS=1 SIZE="10">])
loHTML.SendLn([<B>  To: </B><INPUT NAME="EndDate" TYPE="TEXT" ROWS=1 SIZE="10">])
loHTML.SendLn([</PRE>])
loHTML.SendLn([<p>])
loHTML.SendLn([<INPUT TYPE="SUBMIT" NAME="SubmitButton"  VALUE="Show hours worked" SIZE="40">])
loHTML.SendLn([<INPUT TYPE="RESET"  NAME="Reset Form" VALUE="Reset" ALIGN=top>])
loHTML.SendLn([<p>])
loHTML.SendLn([<B>User Notes (to appear on output):</B><BR><TEXTAREA  NAME="FormNotes" ROWS=5 COLS=60></TEXTAREA>])
loHTML.SendLn([</FORM>])
loHTML.SendLn([<p>])
loHTML.SendLn([<A HREF="/cgi-win/wwcgi.dll?Error">Throw CGI Error for unhandled parameter.</A><P>])

loHTML.HTMLFooter(PAGEFOOT)
RETURN


************************************************************************
FUNCTION ShowClient
*******************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1995
***   Contact: (503) 386-2087  / 76427.2363@compuserve.com
***  Modified: 10/31/95
***  Function: Shows the client information as drilled down to by
***            from the ShowHours Form
************************************************************************
LOCAL lcOutfile, lnPlusSign, lnParms

loCGI=THIS.oCGI
loHTML=THIS.oHTML

*** This is the output file name
lcOutFile=loCGI.GetOutFile()

*** Get the second command line parameter (wwcgi.dll?ShowClient~Rick+Strahl)
*** lnParms=loCGI.aCGIParms()  && load parameter array - happens in Process Method
lcName=loCGI.GetCGIParameter(2)
IF EMPTY(lcName)
   =THIS.ErrorMsg("Can't find specified client.")
   RETURN
ENDIF

SELECT company,careof,address,phone,email ;
   FROM TT_CUST ;
   WHERE UPPER(company)=UPPER(lcName) ;
   INTO CURSOR QUERY

IF _TALLY<1
   =THIS.ErrorMsg("Customer not found...")
   RETURN
ENDIF


*** Create the document header
loHTML.HTMLHeader("Client Information for <BR>"+TRIM(query.company),;
            "Visual FoxPro Nested CGI Sample",BACKIMG)

loHTML.Sendln("<PRE>")   && Send Preformatted text
loHTML.SendLn("<b>   Company</b>: "+query.company)
loHTML.SendLn("<b>       c/o:</b> "+query.careof)
loHTML.Send("<b>   Address: </b>"+loHTML.SendMemoLn(TRIM(address),.F.,60,12,.T.) )
IF !EMPTY(Phone)
   loHTML.SendLn("<b>     Phone: </b>"+loHTML.SendMemoLn(phone,.F.,60,12,.T.) )
ENDIF
IF !EMPTY(Email)
   loHTML.SendLn("<b>     Email</b>: "+loHTML.SendMemoLn(email,.F.,50,12,.T.) )
ENDIF

loHTML.Sendln("</PRE>")

loHTML.HTMLFooter(PAGEFOOT)

RETURN
*EOP ShowClient


************************************************************************
PROCEDURE ShowSlip
******************
***  Modified: 10/31/95
***  Function: Displays the drill down time slip information
***            information based on a selecting the hotkey
*************************************************************************
LOCAL lcOutfile, lnPlusSign, lcTTID, lnparms

loCGI=THIS.oCGI
loHTML=THIS.oHTML

*** This is the output file name
lcOutFile=loCGI.GetOutFile()

*** Get Customer Id passed as 2nd parameter (wwcgi.dll?ShowClient~CustId)
lcTTID=loCGI.GetCGIParameter(2)
IF EMPTY(lcTTID)
   =THIS.ErrorMsg("No Such Time Slip.")
   RETURN
ENDIF

SELECT timebill.*, tt_cust.company ;
   FROM TIMEBILL,tt_cust ;
   WHERE TTID=lcTTID AND ;
   timebill.custno=tt_cust.custno ;
   INTO CURSOR QUERY

*** Create the document header
loHTML.HTMLHeader("Time Slip Lookup ","Visual FoxPro nested CGI Sample",BACKIMG)
loHTML.Sendln("<PRE>")   && Send Preformatted text

loHTML.SendLn("<b>   Company</b>: "+query.company)
loHTML.SendLn("    <b>  Date</b>: "+DTOC(query.datein))
loHTML.SendLn("   <b>Time In</b>: "+query.timein)
loHTML.SendLn("  <b>Time Out</b>: "+query.timeout)
loHTML.Sendln("             --------------")
loHTML.SendLn("<b>Total Time</b>: "+STR(query.totalhours,5,2)+" hours")
loHTML.SendPar()
loHTML.SendLn(" <b>Work Done</b>: "+loHTML.SendMemoLn(query.descript,.F.,45,12,.T.) )

loHTML.SendLn([</PRE>])

loHTML.HTMLFooter(PAGEFOOT)
RETURN

************************************************************************
PROCEDURE Redirect
******************
***  Modified: 09/02/95
***  Function: Redirects output using Location: or URI: directive
*************************************************************************

*** Redirect to show local home page
*** This option is handy for displaying stock error messages
THIS.oHTML.HTMLRedirect("/")

RETURN


************************************************************************
* wwDemo :: Mailit
*********************************
***  Function: Sends a standard form letter to the email address
***            specified by the sender.
***    Assume: TTC Mail control is installed on VFP server and
***            VFP server has access to mail server.
************************************************************************
FUNCTION Mailit
LOCAL lcHeader

loCGI=THIS.oCGI
loHTML=THIS.oHTML

IF .NOT. SMTPMAIL_ENABLED
  THIS.ErrorMsg("SMTP Mail unavailable",;
               "The mail capability is not installed. You need to set the SMTPMAIL_ENABLED "+;
               "flag in WCONNECT.H to .T. and install the MAIL.OCX provided with the registered "+;
               "version of Web Connection for this functionality to work.")
  RETURN
ENDIF

lcEmail=loCGI.GetFormVar("Email")
IF !EMPTY(lcEmail)
  *** Note we're accessing the GLOBAL (PUBLIC) oCGIServer here
  oCGIServer.SendMail("205.162.195.2", "Rick Strahl", ;
                      "rstrahl@west-wind.com",;
                      lcEmail,"", ;
                      "Web Connection generated E-Mail Sample",;
"This message has been generated by West Wind Web Connection's"+CR+;
"demo page on "+dtoc(date())+" at "+time()+" Pacific Standard Time."+CR+CR+;
"  http://west-wind.com/wconnect.htm")

   lcHeader="Email message sent..."
   lcMessage="Please note that no error checking was performed on sending the message so the message can be processed in the background, while Web Connection continues data services."
ELSE
   lcHeader="Email message not sent..."
   lcMessage="The email address you specified was left blank. Please make sure you enter "+;
             "an email address and try again..."
ENDIF

*** Generate the page
loHTML.ContentTypeHeader()

loHTML.SendLn([<HTML>])
loHTML.SendLn([<HEAD>])
loHTML.SendLn([<META HTTP-EQUIV="Refresh" CONTENT="10; URL=/wconnect.htm">])
loHTML.SendLn([<TITLE>]+lcHeader+[</TITLE></HEAD>])
loHTML.SendLn([<BODY BACKGROUND="]+BACKIMG+[">])
loHTML.SendLn([<h2>]+lcHeader+[</h2></H1>])
loHTML.SendLn([<HR>])
loHTML.SendLn([<p>])
loHTML.SendLn(lcMessage)
loHTML.SendLn([<p>])
loHTML.HTMLFooter(PAGEFOOT)

ENDFUNC
* Mailit

************************************************************************
* wwDemoProcess :: CookieTest
*********************************
***  Function: Demonstrate how to set and retrieve HTML Cookies
************************************************************************
FUNCTION CookieTest

*** Easier reference
loCGI=THIS.oCGI

*** Try to retrieve the cookie...
lcId=loCGI.GetCookie("wwUserId")

*** Create Standard Header
loHeader=CREATE("wwHTTPHeader")
loHeader.DefaultHeader()

*** If not Found
IF EMPTY(lcId)
   *** Create the cookie
   lcId=SYS(3)
   loHeader.AddCookie("wwUserId",lcId)
ENDIF            

*** The CGIProcess Class handles setting up the output file
*** and making sure that HTML document can be created.
*** At this point the output document is ready to be written to.
loHTML=THIS.oHTML

*** Send Header and make sure to pass the Content Type (loHeader)
loHTML.HTMLHeader("Cookie Test","Cookie Test",BACKIMG,loHeader)

loHTML.SendLn("If you hit this page repeatedly and your browser supports HTTP Cookies, you should see the "+;
   "Cookie value below stay the same. The value is stored on the client side by the browser and "+;
   "can be used to keep state for applications like stores or multiple form transactions.<p> "+;
   "Cookies can be stored permanently, but Web Connection oCGI.SetCookieString() method has a "+;
   "a life time of the Browser Session - if you shut down and restart your browser a new ID will be assigned...<p>"+;
   "Cookie Value (wwUserId):  <b>" +lcId +"</b><p> "+CR+;
   PAGEFOOT  )

RETURN


************************************************************************
* wwDemoProcess :: Authentication
*********************************
***  Function: Demonstrate how to check authorization for users
************************************************************************
FUNCTION Authentication
LOCAL lcUsername, lcPassword, loCGI

*** Easier reference
loCGI=THIS.oCGI

*** Try to retrieve the cookie...
lcUserName=loCGI.GetCGIVar("Authenticated Username")
lcPassword=loCGI.GetCGIVar("Authenticated Password")

IF EMPTY(lcUserName)   && Any validations against password here...
    *** Send Password Dialog
    THIS.oHTML.HTMLAuthenticate(loCGI.GetServername())
   RETURN
ENDIF   

THIS.ErrorMsg("You've been validated for this request...",;
              "You've entered a username of <b> "+lcUserName+ ;
              "</b> and password of <b> "+lcPassword + "</b><p>"+;
              "Subsequent requests for this server realm will not prompt you for "+;
              "a password again until you shut down your browser. Password validations "+;
              "persist accross the session.<p>"+;
              "Please note that password validation depends on the Web server. "+;
              "MS IIS will not pass a password back and forces all users through the NT security mechanism "+;
              "so a username is only returned to you if the user is a valid user as entered in the registry. "+;
              "Commerce Builder and Website allow more flexibility in letting set up priviliges "+;
              "on the individual files/directories, or not setting up any rights at all and letting your CGI request handle validation.<P>"+;
              THIS.oHTML.HREF("/wconnect/Auth.txt","Show Code",.T.))
RETURN


************************************************************************
* wwDemoProcess :: BannerTest
*********************************
***  Function: Shows how to use the wwBanner class - two lines of code
************************************************************************
FUNCTION BannerTest
LOCAL lcImageLink, loBanner, loHTML

loHTML=THIS.oHTML

*** Create banner class
loBanner=CREATE("wwBanner")
loBanner.cScriptRef="wwcgi.dll?"

*** Since we're not tracking users here, let's use
*** random images from the wwbanners table table
lcImageLink=loBanner.GetBanner(-1)   && -1 is random or use banner number

*** Note the image is embedded into the message below

THIS.ErrorMsg("Welcome to the rotating image page...",;
              lcImageLink+;
              "The picture to the left of this text will change each time you "+;
              "refresh this page (well, it's random so it's possible to "+;
              "get the same one twice). Hit the Refresh button to see the image change. " +;
              "When setting up the image you can specify additional image tags to allow " +;
              "sizing and spacing of the image among other things.<p>"+;
              "Check out the maintainence page that's included in the banner class on the "+;
              loHTML.HREF(THIS.oCGI.GetPreviousURL(),"previous link",.t.)+". You may add your "+;
              "imagelinks to this page if you like. Just enter an image that exists "+;
              "somewhere on the net and attach a URL to go to a location...<p>"+ ;
              THIS.oHTML.HREF("/wconnect/Banner.txt","Show Code",.T.))

ENDFUNC
* BannerTest

************************************************************************
* wwDemoProcess :: ShowBanners
*********************************
***  Function: Shows all available banners and an input form to add
***            new entries and delete existing.
************************************************************************
FUNCTION ShowBanners
LOCAL loBanner

loBanner=CREATE("wwBanner")
loBanner.cScriptRef="/cgi-win/wwcgi.dll?"

THIS.oHTML.Send(loBanner.HTMLShow())

ENDFUNC
* ShowBanners


************************************************************************
* SurplusMaintain :: AddBanner
*********************************
***  Function: Adds a banner image/link to the rotating banner database.
************************************************************************
FUNCTION AddBanner

loCGI=THIS.oCGI
loBanner=CREATE("wwBanner")

loBanner.AddBanner(loCGI.GetFormVar("Image"),;
                   loCGI.GetFormVar("Link"),;
                   loCGI.GetFormVar("ImgTags"),;
                   Val(loCGI.GetFormVar("Order")),;
                   VAL(loCGI.GetFormVar("MaxHits")) )

*** Simply redisplay the list
THIS.ShowBanners()

ENDFUNC
* AddBanner

************************************************************************
* SurplusMaintain :: DeleteBanner
*********************************
***  Function: Deletes a banner from rotation
************************************************************************
FUNCTION DeleteBanner

loCGI=THIS.oCGI
loBanner=CREATE("wwBanner")

*** wwcgi.dll?Maintain~DeleteBanner~/image/image.gif
loBanner.DeleteBanner(loCGI.GetCGIParameter(3))

*** Simply redisplay the list
THIS.ShowBanners()

ENDFUNC
* DeleteBanner


************************************************************************
* wwDemoProcess :: ShowGuest
*********************************
***  Function: Guest Book Interactive Browser. Note that all this code
***            is not related to creating HTML at all, but rather
***            consists of setting up the logic for navigation and
***            adding editing entries.
************************************************************************
FUNCTION ShowGuest
LOCAL lcCustId, lcMoveWhere, llError
PRIVATE pcErrorMsg, pcPassword

loHTML=THIS.oHTML
loCGI=THIS.oCGI

*** Retrieve the Operation option (Next, Previous etc.)
lcMoveWhere=UPPER(loCGI.GetCgiParameter(2))

*** Grab the commandline Customer Id
lcCustId=loCGI.GetCGIParameter(3)

pcPassword=""
pcErrorMsg=""
llError=.F.

IF!USED("Guest")
  USE GUEST IN 0
ENDIF
SELE GUEST

  
IF EMPTY(lcCustId)
  lcMoveWhere="BOTTOM"
ELSE
  IF lcCustId#"NEW_ID"
     LOCATE FOR CustId=lcCustId
     IF !FOUND()
        pcErrorMsg="Invalid Record. Going to bottom of file..."
        lcMoveWhere="BOTTOM"
     ENDIF   
  ENDIF
ENDIF   


DO CASE 
  CASE lcMoveWhere="GO"
     *** Do nothing - just display 
  CASE lcMoveWhere="NEXT"
     IF !EOF()
        SKIP  
        IF EOF()
           pcErrorMsg="Last Record in table..."
        ENDIF
     ELSE
        GO BOTTOM
     ENDIF
     
     IF EOF()
        GO BOTTOM
        pcErrorMsg="Last Record in table..."
     ENDIF
  CASE lcMoveWhere="PREVIOUS" AND !llError
     IF !BOF()
        SKIP -1
     ENDIF
     IF BOF()
        pcErrorMsg="Beginning of File..."
     ENDIF

  CASE lcMoveWhere="TOP"
    GO TOP
    DO WHILE EMPTY(guest.name) AND !EOF()
       SKIP
    ENDDO

  CASE lcMoveWhere="BOTTOM"
     GO BOTTOM
     DO WHILE EMPTY(guest.name) AND !BOF() AND !EOF()
        SKIP -1
     ENDDO
  
  CASE lcMoveWhere="ADD"
     *** Don't add record - move to 'ghost rec' to show blank record
     GO BOTTOM
     SKIP
     
     pcErrorMsg="Please fill out the form below and click the Save button..."
  
  CASE lcMoveWhere="SAVE"
     IF EMPTY(loCGI.GetFormVar("txtName")) AND EMPTY(loCGI.GetFormVar("txtCompany")) 
        THIS.ErrorMsg("Incomplete Input","You have to enter at least a name or company.")
        USE IN GUEST
        RETURN
     ENDIF
     IF EMPTY(loCGI.GetFormvar("txtPassword"))
        THIS.ErrorMsg("Incomplete Input","You have to enter a password to save this entry.")
        USE IN GUEST
        RETURN
     ENDIF       

     IF lcCustId="NEW_ID"
         APPEND BLANK
         REPLACE custid with sys(3), ;
                 entered with datetime(), ;
                 password with loCGI.GetFormVar("txtPassWord")
     ELSE
         *** Check password
         pcPassWord=PADR(loCGI.GetFormVar("txtPassWord"),8)
         IF UPPER(guest.password) # UPPER(pcPassword)
            pcErrorMsg="The password you typed does not allow you to change the selected entry..."
            pcCustId=guest.custid
            pcPassword=""
            loHTML.ShowMemoPage(HTMLPAGEPATH+"Guest.wc",.T.,"FORCE RELOAD")           
            RETURN
         ENDIF
     ENDIF

     REPLACE name with loCGI.GetFormVar("txtName"), ;
             company with loCGI.GetFormVar("txtCompany"),;
             location with loCGI.GetFormVar("txtLocation"),;
             Email with loCGI.GetFormVar("txtEmail"),;
             Message with loCGI.GetFormVar("txtMessage")
             
            
      pcErrorMsg="Record saved..."
ENDCASE

*** Prime pcCustId for all links
IF lcMoveWhere#"ADD"
   pcCustId=guest.custid
ELSE
   pcCustId="NEW_ID"   
ENDIF
pcPassword=""

pcHomePath=HOMEPATH

*** Display GUEST.WC - This HTML form contains the fields and 
*** pcErrorMsg variable...
loHTML.ShowMemoPage(HTMLPAGEPATH+"Guest.wc",.T.,IIF(ATC("MSIE",loCGI.GetBrowser())>0,"Force Reload","text/html"))

IF USED("Guest")
   USE IN Guest
ENDIF
   
ENDFUNC
* ShowGuest

************************************************************************
* wwDemoProcess :: BrowseGuests
*******************************
***  Function: Shows a list of Guests in table form for the Guest
***            Sample application.
***            This example manually creates the Browse page.
************************************************************************
FUNCTION BrowseGuests
LOCAL loHTML, loCGI, lcOrder

loHTML=THIS.oHTML
loCGI=THIS.oCGI

*** Retrieve the Order Radio Button Value - Name, Company, Location
lcOrderVal=TRIM(loCGI.GetFormVar("radOrder"))
IF EMPTY(lcOrderVal)
  lcOrderVal="Name"
ENDIF  

*** Build an Order By expression
lcOrder="UPPER("+lcOrderVal+")"   

*** Create Cursor of all Guests - Note the URL link is embedded in the SQL-SELECT
SELECT [<A HREF="wwcgi.dll?ShowGuest~Go~]+custid+[">]+Name+[</a>] as Guest, ;
   company, location,;
   &lcOrder ;
   FROM Guest ;
   ORDER BY 4 ; 
   INTO CURSOR TQuery


*** Set up so we can us HTML tables
loHTML.SetAllowHTMLTables(loCGI.IsNetscape())

loHTML.HTMLHeader("Guest Book Browser",,BACKIMG,IIF(ATC("MSIE",loCGI.GetBrowser())>0,"Force Reload","text/html"))
loHTML.SendLn([ <FORM ACTION="wwcgi.dll?BrowseGuests" METHOD="POST">])
loHTML.SendLn([ Sort by: <input type="radio" value="Name" name="radOrder" ]+IIF(lcOrderVal="Name","checked=true","")+[>Name ])
loHTML.SendLn([ <input type="radio" value="Company" name="radOrder" ]+IIF(lcOrderVal="Company","checked=true","")+[> Company  ])
loHTML.SendLn([ <input type="radio" value="Location" name="radOrder"]+IIF(lcOrderVal="Location","checked=true","")+[> Location<br>])
loHTML.SendLn([ <input type="submit" value="Change Order">])
loHTML.SendLn([ </FORM> <p>])

*** Explicitly set up headers so we only display first 3 cols
DIMENSION laHeaders[3]
laHeaders[1]="Name"
laHeaders[2]="Company"
laHeaders[3]="Location"

*** Display the table
loHTML.ShowCursor(@laHeaders)

loHTML.HTMLFooter(PAGEFOOT)

IF USED("Guest")
   USE IN Guest
ENDIF

ENDFUNC
* BrowseGuests

************************************************************************
PROCEDURE ErrorMsg
******************
***  Modified: 06/03/96
***  Function: Overrides ErrorMsg() in CGIProc for custom
***            error and status display messages
***
**             A simple error handler that demonstrates how to use
***            the HTMLError method to output an error document
***            when a CGI operation fails. All errors should send
***            an error page in order to properly terminate
***            the CGI request operation.
***      Pass: lcMessage  -  Error Message to display (detail)
***            THIS.oCGI      -  Current CGI object
***            loHTML     -  Existing HTML object
***    Return:
*************************************************************************
LPARAMETER lcMessage, lcMessage2

lcMessage=IIF(TYPE("lcMessage")="C",lcMessage,;
   "The server was unable to respond to the CGI request.")
lcMessage2=IIF(type("lcMessage2")="C",lcMessage2,;
   "The server was unable to create the requested document.<BR>"+CHR(13)+;
   "This message was generated by Visual FoxPro...")

THIS.oHTML.RewindFile

*** HTMLError handles
THIS.oHTML.HTMLHeader(lcMessage,,BACKIMG)

THIS.oHTML.SendLn(lcMessage2)

*** Close down the doc and shut off further output
THIS.oHTML.HTMLFooter(PAGEFOOT)
THIS.oHTML.NoOutput(.T.)
THIS.oHTML.Destroy

RETURN
* EOP ErrorMsg



ENDDEFINE
*EOC CGIProcess


************************************************************************
PROCEDURE Shutit
******************
***  Function: System Shutdown Procedure
*************************************************************************
CLEAR ALL
QUIT
RETURN


************************************************************************
*PROCEDURE JayWeb
******************
***   Created: 06/15/96
***  Function: Processing incoming JayWeb requests. Called from
***            CGIMAIN.PRG using JayWeb~Task~Optional+Parms parameter.
***      Pass: loCGI   -   wwCGI object
***    Return: nothing
*************************************************************************
LPARAMETER loCGI

#INCLUDE WCONNECT.H

*** 1 = Local  2 = Online  ( others??? NoteBook, Client etc)
#DEFINE LOCALSITE 1


#IF LOCALSITE=1
    *** TEMPLATE - DO NOT REMOVE - HTMLPAGEPATH
    #DEFINE HTMLPAGEPATH "C:\WWW\DBSINYC\WWWROOT\JAYROBOT\\"
    *** TEMPLATE - DO NOT REMOVE - HTMLPAGEPATH
   #DEFINE DATAPATH "JAYROBOT\DATA\"
#ENDIF
#IF LOCALSITE=2
   #DEFINE HTMLPAGEPATH "\\WEB2\HTTP\WESTWIND\WCONNECT\"
   #DEFINE DATAPATH "wwdemo\"
#ENDIF

*** Optional HTML and graphics file path DEFINEs
*** I use these defines to avoid hardcoding paths when
*** testing and then deploying on the server
#DEFINE HOMEPATH "/JayRobot/"
#DEFINE DEMOPATH "/Demo/"
#DEFINE HOMEPAGE HOMEPATH + "Index.htm"
#DEFINE BACKIMG HOMEPATH + "paper.gif"
#DEFINE PAGEFOOT [<HR>] + CR + [<BR></BR>] + CR + ;
                 [<A HREF="] + HOMEPATH + [Trading.htm">] + CR + ;
                 [<IMG SRC="] + HOMEPATH + [backhome.gif" ALIGN=CENTER BORDER=2 ALT="back-to-home">] + CR + ;
                 [Back to JayRobot's Tape Trading Page] + CR + ;
                 [</A>]
#DEFINE DEMOFOOT [<HR>] + CR + [<BR></BR>] + CR + ;
                 [<A HREF="] + DEMOPATH + [DemoDemo.htm">] + CR + ;
                 [<IMG SRC="] + HOMEPATH + [backhome.gif" ALIGN=CENTER BORDER=2 ALT="back-to-home">] + CR + ;
                 [Back to Demographics Login Page] + CR + ;
                 [</A>]

*** Now create a process object. It's not necessary
*** to use an object here, but it makes error handling
*** document and CGI handling much easier!
loCGIProcess=CREATE("JayWebCGI", loCGI, "~", "+", "wwhtml")
IF TYPE("loCGIProcess")#"O"
   *** All we can do is return...
   WAIT WINDOW NOWAIT "Unable to create CGI Processing object..."
   RETURN .F.
ENDIF

*** Call the Process Method that handles the request
loCGIProcess.Process

RETURN


*************************************************************
DEFINE CLASS JayWebCGI AS wwCGIProcess
*************************************************************
***    Author: Jay Robohn
***  Modified: 10/15/96
***  Function: Jay's web functions
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
*** Process        && Virtual Method that is always overridden
*** Error          && Handles errors that occur in the Process code
*** ErrorMsg(cErrorHeader,cMessage)  && Quick Message Display


************************************************************************
* JayWebCGI :: Process
***************************
***  Function: This is the callback program file that handles
***            processing a CGI request
***      Pass: THIS.oCGI	-	Object containing CGI information
***    Return: .T. to erase Temp File .F. to keep it
************************************************************************
FUNCTION Process
LOCAL lcParameter, lcOutFile, lcIniFile, lcOldError

* Optional CGI parameters following EXE name
lcParameter=UPPER(THIS.oCGI.GetCGIParameter(2))

DO CASE
   CASE lcParameter = "DISPLAYFILE" OR lcParameter="SHOWPAGE"
      =THIS.DisplayFile(THIS.oCGI.GetCGIParameter(3),HTMLPAGEPATH)

   *** NOTE:    GENERIC ROUTING BY PARAMETER NAME
   ***          PEMSTATUS() requires VFP 3.0b or later
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
* wwConnectDemo :: ShowHoursMulti
*********************************
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
   [<A HREF="/cgi-win/wwcgi.dll?wwdemo~ShowClient~]+CHRTRAN(TRIM(tt_cust.company)," ","+")+[">]+;
       tt_cust.company+[</a>] AS Client,;
   [<A HREF="/cgi-win/wwcgi.dll?wwdemo~ShowSlip~]+CHRTRAN(timebill.ttId," ","+")+;
       [">]+DTOC(timebill.datein)+" - "+timebill.timein+[</a>] AS Date,;
   timebill.totalHours as Hours ;
 FROM TIMEBILL,TT_CUST ;
 WHERE TIMEBILL.custno=tt_cust.custno AND ;
       !expense ;
       &lcNameFilter ;
 INTO CURSOR TQUERY ;
 ORDER BY company,Datein


*** Create the document header
loHTML.HTMLHeader("Time Trakker Data Example",;
                  "Visual FoxPro Sample Query Result",;
                  BACKIMG)


IF _TALLY<1
   THIS.ErrorMsg("No Matching Records found...",;
                 [<A HREF="]+loCGI.GetPreviousUrl()+[">Return to Test Form...</A>])
   RETURN
ENDIF

*** Tell Web Connection whether it's Ok to create HTML Tables
*** based on Browser capability
loHTML.SetAllowHTMLTables(loCGI.IsNetScape())

*** Now show the table
loHTML.ShowCursor(,,.T.)

*** Close out form
loHTML.HTMLFooter(PAGEFOOT+' [<A HREF="/wconnect/ShwMulti.txt">Show Code</A>]')

RETURN

************************************************************************
* JayWeb :: Search
*******************************
***  Function: Queries demos and release databases to show a history for
***            any bands matching the passed search string.
************************************************************************
FUNCTION Search
LOCAL loHTML, loCGI

  do Path with "c:\www\dbsinyc\wwwroot\JayRobot\Data", "ADD"

  *** CGIProcess class contains oHTML and oCGI objects
  *** Make it easier to reference these
  loHTML=THIS.oHTML
  loCGI=THIS.oCGI

  lcTheBand = loCGI.GetFormVar("SearchText")

  *** Create a page header - HTML object is already created at this point
  jcHdrText = [<IMG SRC="] + HOMEPATH + [Skulls2.gif" ALIGN="LEFT">] + CR + ;
              [<H2>Complete Listing for ] + ;
              upper(alltrim(lcTheBand)) + [</H2>]

  loHTML.HTMLHeader(jcHdrText, "Search Results", BACKIMG)

  *** Select some records from a database
  * do GrabData with lcTheBand
  jcTheBand = iif(empty(lcTheband), "", upper(alltrim(lcTheBand)))

  select padr(upper(cBand), 32) as lcBand, ;
         padr(cTitle, 50) as cTitle, ;
         dtos(dRealDate) as lcRealDate, ;
         Country.cCtryCode as lcCtryCode, ;
         "DEMO " as lcType ;
    from Demos, Country ;
   where Country.cCountryID == Demos.cCountryID and ;
         upper(cBand) = jcTheBand ;
   union all ;
  select padr(upper(cBand), 32) as lcBand, ;
         padr(cTitle, 50) as cTitle, ;
         dtos(dRealDate) as lcRealDate, ;
         space(5) as lcCtryCode, ;
         "DEMO " as lcType  ;
    from Demos ;
   where empty(Demos.cCountryID) and ;
         upper(cBand) = jcTheBand ;
   union all ;
  select upper(cArtist) as lcBand, ;
         left(cTitle, 50), ;
         dtos(ctod("01/01/" + ;
              alltrim(str(iif(empty(nYearRecd), nYearReld, nYearRecd))))) as lcRealDate, ;
         Country.cCtryCode as lcCtryCode, ;
         upper(cType) as lcType ;
    from Release, Country ;
   where Country.cCountryID == Release.cCountryID and ;
         upper(cArtist) = jcTheBand ;
   union all ;
  select upper(cArtist) as lcBand, ;
         left(cTitle, 50), ;
         dtos(ctod("01/01/" + ;
              alltrim(str(iif(empty(nYearRecd), nYearReld, nYearRecd))))) as lcRealDate, ;
         space(5) as lcCtryCode, ;
         upper(cType) as lcType ;
    from Release ;
   where empty(Release.cCountryID) and ;
         upper(cArtist) = jcTheBand ;
   order by lcBand, lcCtryCode, lcRealDate ;
    into cursor cBandHist

  * replace all lcRealDate  with padc(substr(lcRealDate, 5, 2) + "/" + ;
                              right(lcRealDate, 2) + "/" + ;
                              left(lcRealDate, 4), 12), ;
              lcCtryCode with padc(alltrim(lcCtryCode),12)

  if _tally > 0
    * make an array for our column titles
    declare jaColTitles[5]
    jaColTitles[1] = "Band / Artist"
    jaColTitles[2] = "Title of Release"
    jaColTitles[3] = "Date"
    jaColTitles[4] = "Ctry Code"
    jaColTitles[5] = "Type"

    *** Tell Web Connection whether it's Ok to create HTML Tables
    *** based on Browser capability
    loHTML.SetAllowHTMLTables(loCGI.IsNetScape())

    *** Now display the results in an HTML table
    loHTML.ShowCursor(@jaColTitles)
  else
    loHTML.SendPar()
    loHTML.SendLn("Search string not found in bands<BR>")
  endif

  *** For fun let's put some CGI information on the page as well
  loHTML.SendPar()
  loHTML.SendLn("Browser used: "+loCGI.GetBrowser()+"<BR>")
  loHTML.SendLn("Query String: "+loCGI.GetCGIParameter()+"<BR>")
  loHTML.SendLn("3rd Parameter: "+loCGI.GetCGIParameter(3))
  loHTML.HTMLFooter(PAGEFOOT)

  if !used("JayLog")
    use JayLog
  endif

  select JayLog

  append blank
  replace cBand      with lcTheband, ;
          dAccDate   with date(), ;
          cAccTime   with time(), ;
          cBrowser   with loCGI.GetBrowser(), ;
          cRemoteAdr with loCGI.GetRemoteAddress()

  * append memo mContent from (loCGI.GetContentFile())
  * append memo mOutput from (loCGI.GetOutFile())

  use in JayLog
  use in Demos
  use in Release
  use in Country

  do Path with "c:\www\dbsinyc\wwwroot\JayRobot\Data", "DELETE"

ENDFUNC

************************************************************************
* JayWeb :: DemoDemo
*******************************
***  Function: Marsh & McLennan demographics demo
************************************************************************
FUNCTION DemoDemo
LOCAL loHTML, loCGI

  * add our demo data directoy to FoxPro path and open required files
  do Path with "c:\www\dbsinyc\wwwroot\Demo\Data", "ADD"

  if !used("HMO")
    select 0
    use HMO order PlanCode
  endif

  if !used("RetElect")
    select 0
    use RetElect order cEmpID
  endif
  select RetElect
  set relation to cMCAR into HMO

  if !used("Employ")
    select 0
    use Employ order cSSNo
  endif
  select Employ
  set relation to cEmpID into RetElect

  if !used("Users")
    select 0
    use Users order cSSNo
  endif

  * CGIProcess class contains oHTML and oCGI objects
  * Make it easier to reference these
  loHTML    = THIS.oHTML
  loCGI     = THIS.oCGI

  * grab the form variables passed through CGI
  jcTheUser = loCGI.GetFormVar("UserID")
  jcThePIN  = THIS.SYEncrypt(loCGI.GetFormVar("UserPIN"))

  * Create a page header - HTML object is already created at this point
  jcHdrText1 = loHTML.ContentTypeHeader()
  jcHdrText1 = jcHdrText1 + ;
               "<HTML>"+CR+"<HEAD><TITLE>"+;
               "Demographic Demo</TITLE></HEAD>" + CR + ;
               "<BODY " + [BACKGROUND="] + DEMOPATH + [BackBlue.gif"] + CR + ;
               [BGCOLOR="#000000"] + CR + ;
               [TEXT="#ffffff"   ] + CR + ;
               [LINK="#E5FF00"   ] + CR + ;
               [VLINK="#72ffcb"  ] + CR + ;
               [ALINK="#EE0000"> ] + CR

  jcHdrText2 = [<CENTER><IMG SRC="] + DEMOPATH + ;
               [MMCLogo.jpg" BORDER=4>] + CR + ;
               [<HR SIZE=8 ALIGN=CENTER WIDTH=60%>]

  loHTML.Send(jcHdrText1)
  loHTML.Send(jcHdrText2)
  * loHTML.HTMLHeader(jcHdrText, "Demographic Demo", DEMOPATH + "BackBlue.gif")

  * Verify the user's ID and PIN
  select Users
  jlProceed = .f.
  if !empty(jcTheUser) and !empty(jcThePin) and seek(jcTheUser)
    if cPassword = jcThePIN
      * everything's ok, we can proceed
      jlProceed = .t.
    else
      loHTML.SendPar()
      loHTML.SendLn("<CENTER>" + ;
                    "Sorry, you've entered an incorrect PIN, please try " + ;
                    [<A HREF="] + DEMOPATH + [DemoDemo.htm">again</A><BR>] + ;
                    "</CENTER>")
    endif
  else
    loHTML.SendLn("<CENTER>" + ;
                  "Sorry, we were unable to verify your ID<BR></BR>" + ;
                  "You may either:" + ;
                  "<UL>" + ;
                  [<LI><A HREF="] + DEMOPATH + [DemoDemo.htm">Try again</A>] + ;
                  [<LI>Contact <A HREF="mailto:JayRobot@dbsinyc.com">] + ;
                  "administrator</A>" + ;
                  "</UL></CENTER>")
  endif

  * continue if the user logged on successfully
  if jlProceed
    loHTML.SendPar()
    loHTML.SendLn("You have successfully gotten this far<BR></BR>")
    select Employ
    if seek(jcTheUser)
      loHTML.SendLn("Hello, " + proper(alltrim(Employ.cFName) + ;
                                       iif(empty(Employ.cMidInit), " ", " " + ;
                                           Employ.cMidInit + ". ") + ;
                                       alltrim(Employ.cLName)) + "<BR></BR>")
    else
      loHTML.SendLn("But, we are unable to find your employee record<BR></BR>" + ;
                    [Please contact <A HREF="mailto:JayRobot@dbsinyc.com">] + ;
                    "administrator</A>")
    endif

    loHTML.HTMLFooter(DEMOFOOT)
  endif

  use in Users
  use in Employ
  use in RetElect
  use in HMO

  do Path with "c:\www\dbsinyc\wwwroot\Demo\Data", "DELETE"

ENDFUNC

**************************************************************************
*  Function:  SYEncrypt
*      Type:  Internal
*   Purpose:  Encrypt a string
*   Returns:  Value of variable -- cstr (encrypted string)
*   Created:  6/1/90
*    Author:  DBSI
*
* Parameter   Typ Description
* ---------   --- -----------
* sstr         C  String to encrypt
*
* Variable    Typ Description
* --------    --- -----------
* ch           C  Character value once encrypted
* cstr         C  Accumulator string to hold encrypted value
* n            N  Counter variable for loop
* cval         N  Seed value for encryption
**************************************************************************
function SYEncrypt              && encrypts a string using progressive
parameters sstr                 && key method (cval is seed)
private ch,cstr,n,cval

  sstr = alltrim(sstr)
  cval = 62                    && cval is encryption key
  cstr = ""
  for n = 1 to len(sstr)
    ch = chr(asc(substr(sstr,n,1)) + cval)
    cstr = cstr + ch
    cval = cval +1
  endfor

return(cstr)

ENDDEFINE
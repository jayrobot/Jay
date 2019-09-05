/*
GammaButton.java
Version 1.0.0
Written by Elijah Dean Meeker 1/4/96
This is an preloading interactive button that loads two or three images (based
on whether or not image0 is a parameter) and navagates to the given URL. Here
are two valid applet tags:

Two images:
<APPLET
codebase="classes"
CODE="GammaButton.class" WIDTH=103 HEIGHT=50>              SIZE of button images
<PARAM NAME="image1" VALUE="images/javaup.jpg">  					UP image
<PARAM NAME="image2" VALUE="images/javadn.jpg">  					DOWN image
<PARAM NAME="dest" VALUE="http://www.realtime.net/~elijah/">   URL
</APPLET>

Three images:
<APPLET
codebase="classes"
CODE="GammaButton.class" WIDTH=103 HEIGHT=50>              SIZE of button images
<PARAM NAME="image0" VALUE="images/javarg.jpg">                NORMAL image
<PARAM NAME="image1" VALUE="images/javaup.jpg">                UP image
<PARAM NAME="image2" VALUE="images/javadn.jpg">                DOWN image
<PARAM NAME="dest" VALUE="http://www.realtime.net/~elijah/">   URL
</APPLET>


Please feel free to use and improve this code. It would not be here but for the
freely given help of others. I would love to see your improvements.
Elijah.

elijah@bga.com
http://www.realtime.net/~elijah/
*/
import java.awt.Graphics;
import java.awt.Event;
import java.awt.Image;
import java.awt.MediaTracker;
import java.net.URL;
import java.net.MalformedURLException;
import java.lang.InterruptedException;
import java.applet.Applet;



public class GammaButton extends java.applet.Applet{

	private MediaTracker tracker;
	private	Image img[] = new Image[3];
	private	boolean onButt = false;
	private	boolean pressedButt = false;
	private	boolean three_img = true;
	private	int onIs = 0;
	private	URL clickDest;
	private	String dest;


/****************************STATE CHANGES*************************************/
	public void init(){
		String istr;
		tracker = new MediaTracker(this);

		for (int i = 0; i < 3; i++) {
					 istr = getParameter("image"+i);
					 if (istr == null){
						three_img = false;
					 }else{
						img[i] =  getImage(getCodeBase(),istr);
						tracker.addImage(img[i], 0);
						try {
						tracker.waitForAll();
						} catch (InterruptedException e) {
						System.out.println("Error waiting for image"+i+" to load");
						}//end catch
					 }//end if
	  }//end for
		dest = getParameter("dest");

		try{
			clickDest = new URL(dest);
		}catch(MalformedURLException mal){
		System.out.println("Malformed URL: Check Applet Tag.");
		}

	}//end init


  public void start(){

	repaint();
  }//end start

  public void stop(){
  }//end stop

  public void destroy(){
  }//end destroy
 /****************************END STATE CHANGES********************************/
 /*******************************EVENTS****************************************/

  public boolean mouseDown(Event e, int x, int y){
	pressedButt = true;
	repaint();

	return(true);
  }//end mouseDown

  public boolean mouseUp(Event e, int x, int y){

	if(pressedButt && onButt){
		pressedButt = false;
		repaint();
				getAppletContext().showDocument(clickDest);
	}else{
		pressedButt = false;
		repaint();
	}
	return(true);
  }//end mouseUp

  public boolean mouseEnter(Event e, int x, int y){
	onButt = true;
	showStatus(dest);
	repaint();

	return(true);
  }//end mouseEnter

  public boolean mouseExit(Event e, int x, int y){
	onButt = false;
	showStatus("");
	repaint();

	return(true);
  }//end mouseExit
/*******************************END EVENTS*************************************/
/*******************************METHODS****************************************/

   public void update(Graphics g){

		if(!onButt)
			if(three_img){
				onIs = 0;
			}else{
				onIs = 1;
			}
		else if (onButt && !pressedButt)
			onIs = 1;
		else
			onIs = 2;

			paint(g);
	}//end update

	public void paint(Graphics g){
		g.drawImage(img[onIs], 0,0,this);


	}//end paint

/*****************************END METHODS**************************************/

}//end class GammaButton

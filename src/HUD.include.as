import com.ElTorqiro.AegisHUD.App;


/*
 * global clip variables
 */
var hud;

/**
 * standard MovieClip onLoad event handler
 */
function onLoad() : Void {
	App.debug("HUD: onLoad");
	
}

/**
 * TSW GUI event, called when the game unloads the clip (via SFClipLoader)
 * - this is not the same as the generic AS2 onUnload method
 */
function OnUnload() : Void {
	App.debug("HUD: OnUnload");
	
	hud.dispose();
}

/**
 * TSW GUI event, called after the loading of the clip is complete (via SFClipLoader)
 */
function LoadArgumentsReceived( arguments:Array ) : Void {
	App.debug("HUD: LoadArgumentsReceived");
	
	hud = attachMovie( "hud", "m_HUD", getNextHighestDepth() );	
}

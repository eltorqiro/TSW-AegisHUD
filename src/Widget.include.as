import com.ElTorqiro.AegisHUD.App;

/**
 * standard MovieClip onLoad event handler
 */
function onLoad() : Void {
	App.debug("Widget: onLoad");
	
	attachMovie( "com.ElTorqiro.AegisHUD.IconWidget", "m_Icon", getNextHighestDepth() );
}

/**
 * TSW GUI event, called when the game unloads the clip (via SFClipLoader)
 * - this is not the same as the generic AS2 onUnload method
 */
function OnUnload() : Void {
	App.debug("Widget: OnUnload");
}

/**
 * TSW GUI event, called after the loading of the clip is complete (via SFClipLoader)
 */
function LoadArgumentsReceived( arguments:Array ) : Void {
	App.debug("Widget: LoadArgumentsReceived");
}

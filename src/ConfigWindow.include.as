import flash.geom.Point;
import com.GameInterface.DistributedValue;

import com.ElTorqiro.AegisHUD.Const;
import com.ElTorqiro.AegisHUD.App;
import com.ElTorqiro.AegisHUD.ConfigUI.Window;


/**
 * variables
 */

  
/**
 * standard MovieClip onLoad event handler
 */
function onLoad() : Void {
	App.debug("Config Window: onLoad");
	
	// opening window position
	var position:Point = App.prefs.getVal( "configWindow.position" );
	if ( position == undefined ) {
		position = new Point( 300, 150 );
	}

	var window:Window = Window( attachMovie( "window", "m_Window", getNextHighestDepth(), { openingPosition: position } ) );

	// set window properties
	window.SetTitle(Const.AppName + " v" + Const.AppVersion);
	
	window.SignalClose.Connect( this, function() {
		DistributedValue.SetDValue( Const.ShowConfigWindowDV, false );
	});
	
	window.SetContent("window-content");
	
}

/**
 * TSW GUI event, called when the game unloads the clip (via SFClipLoader)
 * - this is not the same as the generic AS2 onUnload method
 */
function OnUnload() : Void {
	App.debug("Config Window: OnUnload");
	
	// save position of config window
	App.prefs.setVal( "configWindow.position", new Point( m_Window._x, m_Window._y ) );
}

/**
 * TSW GUI event, called after the loading of the clip is complete (via SFClipLoader)
 */
function LoadArgumentsReceived( args:Array ) : Void {
	App.debug("Config Window: LoadArgumentsReceived");
}

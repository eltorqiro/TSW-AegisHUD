import com.Components.WinComp;
import flash.geom.Point;
import com.GameInterface.DistributedValue;

import com.ElTorqiro.AegisHUD.Preferences;
import com.ElTorqiro.AegisHUD.App;


/**
 * variables
 */
var m_Window:WinComp;
 
 
/**
 * standard MovieClip onLoad event handler
 */
function onLoad() : Void {
	App.debug("Config Window: onLoad");
	
	attachMovie( "com.ElTorqiro.AegisHUD.ConfigWindow.Window", "m_Window", getNextHighestDepth() );

	// position window
	var position:Point = Preferences.getValue( "configwindow.position" );
	if ( position == undefined ) {
		position = new Point( 300, 150 );
	}
	
	m_Window._x = position.x;
	m_Window._y = position.y;
	
	// set window properties
	m_Window.SetTitle(App.Name + " v" + App.Version);
	m_Window.ShowStroke(false);
	m_Window.ShowFooter(false);
	m_Window.ShowResizeButton(false);
	
	m_Window.SignalClose.Connect( this, function() {
		DistributedValue.SetDValue( App.ID + "_ShowConfigWindow", false );
	});
	
	m_Window.SetContent("com.ElTorqiro.AegisHUD.Config.Content");
	
}

/**
 * TSW GUI event, called when the game unloads the clip (via SFClipLoader)
 * - this is not the same as the generic AS2 onUnload method
 */
function OnUnload() : Void {
	App.debug("Config Window: OnUnload");
	
	// save position of config window
	Preferences.setValue( "configwindow.position", new Point(m_Window._x, m_Window._y) );
}

/**
 * TSW GUI event, called after the loading of the clip is complete (via SFClipLoader)
 */
function LoadArgumentsReceived( args:Array ) : Void {
	App.debug("Config Window: LoadArgumentsReceived");
}
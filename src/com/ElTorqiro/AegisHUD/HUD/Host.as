import mx.utils.Delegate;
import com.GameInterface.UtilsBase;
import GUIFramework.ClipNode;

import GUIFramework.SFClipLoader;

import com.ElTorqiro.AegisHUD.HUD.Server;
import com.ElTorqiro.AegisHUD.AddonInfo;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.HUD.Host {
	
	private var hudClip:ClipNode;
	
	public function Host( uiParent:MovieClip ) {
		
		server = new Server( this );
		
		server.SignalSelectedAegisChanged.Connect( testSelectedChanged, this );
		server.SignalItemChanged.Connect( testItemChanged, this );
		server.SignalItemXPChanged.Connect( testItemXPChanged, this );
		
		hudClip = SFClipLoader.LoadClip( AddonInfo.ID + "\\HUD23.swf", AddonInfo.ID + "_HUD", false, _global.Enums.ViewLayer.e_ViewLayerMiddle, 0, [] );
		hudClip.SignalLoaded.Connect( hudLoaded, this );
		
		setTimeout( Delegate.create( this, unloadHUD) , 2000 );
	}
	
	private function hudLoaded( clipNode:ClipNode, success:Boolean ) : Void {
		UtilsBase.PrintChatText( "hud loaded: " + success + ", movie: " + clipNode.m_Movie );
	}
	
	private function unloadHUD() : Void {
		//SFClipLoader.UnloadClip( AddonInfo.ID + "_HUD" );
		UtilsBase.PrintChatText("clip:" + hudClip.m_ObjectName);
		
		hudClip.m_Movie.UnloadClip();
		
		hudClip = SFClipLoader.LoadClip( AddonInfo.ID + "\\HUD2.swf", AddonInfo.ID + "_HUD", false, _global.Enums.ViewLayer.e_ViewLayerMiddle, 0, [] );
		
	}
	
	public function testSelectedChanged( group:String, name:String ) : Void {
		UtilsBase.PrintChatText("host: selected changed: " + group + ", " + name);
	}
	
	public function testItemChanged( group:String, name:String ) : Void {
		UtilsBase.PrintChatText("host: item changed: " + group + ", " + name);
	}

	public function testItemXPChanged( group:String, name:String ) : Void {
		
		var slot:Object = server.getSlot( group, name );
		
		UtilsBase.PrintChatText("host: item xp changed: " + slot.group + ", " + slot.name + " = " + slot.xpPercent);
	}
	
	/*
	 * internal variables
	 */
	
	private var server:Server;
}
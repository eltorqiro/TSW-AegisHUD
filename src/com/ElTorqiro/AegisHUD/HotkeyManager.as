import com.GameInterface.DistributedValue;

import com.GameInterface.Input;

import com.ElTorqiro.AegisHUD.Server.AegisServer;
import com.ElTorqiro.AegisHUD.Server.AegisServerSlot;
import com.ElTorqiro.AegisHUD.App;
import com.ElTorqiro.AegisHUD.Const;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.HotkeyManager {
	
	// hotkey constants
	public static var e_Hotkey_PrimaryAegisNext:Number = 	_global.Enums.InputCommand.e_InputCommand_Combat_NextPrimaryAEGIS;
	public static var e_Hotkey_PrimaryAegisPrev:Number = 	_global.Enums.InputCommand.e_InputCommand_Combat_PreviousPrimaryAEGIS;
	public static var e_Hotkey_SecondaryAegisNext:Number = 	_global.Enums.InputCommand.e_InputCommand_Combat_NextSecondaryAEGIS;
	public static var e_Hotkey_SecondaryAegisPrev:Number = 	_global.Enums.InputCommand.e_InputCommand_Combat_PreviousSecondaryAEGIS;
	
	// key state for hotkey interaction
	public static var e_HotkeyDown:Number = _global.Enums.Hotkey.eHotkeyDown;	
	
	// static class
	private function HotkeyManager() { }
	
	/* 
	 * hotkey handlers used by Input.RegisterHotkey( <number>, "com.ElTorqiro.AegisHUD.HUD.HotkeyHijacker.<name>", _global.Enums.Hotkey.eHotkeyDown , 0 );
	 * 
	 * <name> is a static function
	 * <number> is one of the hotkey constants
	 * 
	 * Hotkey names can be got from: AppData\Local\Funcom\TSW\Prefs\<login name>\hotkeys.xml
	 * Hotkey values come from _global.Enums.InputCommand -- careful, some hotkeys may not have Enum entries :(
	*/

	 /**
	  * manage the hijacking of hotkeys
	  * 
	  * @param	hijack
	  */
	public static function Hijack( hijack:Boolean ) : Void {
		
		if ( hijack == hijacked ) return;
		_hijacked = hijack;
		
		App.debug( "HotkeyManager: hijacking: " + hijack );
		
		var hotkeyList:Array = [
			e_Hotkey_PrimaryAegisNext,
			e_Hotkey_PrimaryAegisPrev,
			e_Hotkey_SecondaryAegisNext,
			e_Hotkey_SecondaryAegisPrev
		];
		
		for ( var s:String in hotkeyList ) {
			Input.RegisterHotkey( hotkeyList[s], hijack ? "com.ElTorqiro.AegisHUD.HotkeyManager.HotkeyHandler" : "", e_HotkeyDown, 0 );
		}
		
	}
	
	/**
	 * handle the pressing of an overridden hotkey
	 * 
	 * @param	key
	 */
	public static function HotkeyHandler( key:Number ) : Void {
		
		// disable hotkey action if hud is disabled and lockout pref set
		if ( !App.prefs.getVal( "hud.enabled" ) && App.prefs.getVal( "hotkeys.lockoutWhenHudDisabled" ) ) return;
		
		var groupID:String;
		var direction:String;
		
		switch ( key ) {
			
			case e_Hotkey_PrimaryAegisNext: groupID = "primary"; direction = "next"; break;
			case e_Hotkey_PrimaryAegisPrev: groupID = "primary"; direction = "prev"; break;
			case e_Hotkey_SecondaryAegisNext: groupID = "secondary"; direction = "next"; break;
			case e_Hotkey_SecondaryAegisPrev: groupID = "secondary"; direction = "prev"; break;
			
		}

		// select slot in current group
		var multi:Number = App.prefs.getVal( "hotkeys.multiSelectType." + groupID );
		AegisServer.selectSlot( groupID, direction, multi );
		App.debug( "HotkeyManager: switch to " + groupID + ", " + direction + ", multi=" + multi );
	}
	
	/**
	 * properties
	 */

	private static var _hijacked:Boolean = false;
	public static function get hijacked() : Boolean { return _hijacked; }

}

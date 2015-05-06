import com.GameInterface.DistributedValue;

import com.GameInterface.Input;

import com.ElTorqiro.AegisHUD.AddonInfo;

class com.ElTorqiro.AegisHUD.HUD.HotkeyHijacker {
	
	// hotkey constants
	public static var e_Hotkey_PrimaryAegisNext:Number = 	133;
	public static var e_Hotkey_PrimaryAegisPrev:Number = 	135;
	public static var e_Hotkey_SecondaryAegisNext:Number = 	134;
	public static var e_Hotkey_SecondaryAegisPrev:Number = 	136;
	
	// key state for hotkey interaction
	public static var e_HotkeyDown:Number = _global.Enums.Hotkey.eHotkeyDown;	
	
	// map of hotkey ids to disruptor RPC strings
	private static var _hotkeyMap:Object;
	
	// static class
	private function HotkeyHijacker() { };
	
	/* 
	 * hotkey handlers used by Input.RegisterHotkey( <number>, "com.ElTorqiro.AegisHUD.HUD.HotkeyHijacker.<name>", _global.Enums.Hotkey.eHotkeyDown , 0 );
	 * 
	 * <name> is a static function
	 * <number> is one of the hotkey constants
	 * 
	 * Hotkey names can be got from: AppData\Local\Funcom\TSW\Prefs\<login name>\hotkeys.xml
	 * Hotkey values are supposed to come from _global.Enums.InputCommand -- careful, hotkeys have been added to the game that do not have Enums :(
	*/

	/**
	 * setup the hijack of the hotkeys, so they get redirected to our function
	 */
	public static function Hijack() : Void {
		
		_hotkeyMap = { };
		_hotkeyMap[ e_Hotkey_PrimaryAegisNext ] = "primary.next";
		_hotkeyMap[ e_Hotkey_PrimaryAegisPrev ] = "primary.prev";
		_hotkeyMap[ e_Hotkey_SecondaryAegisNext ] = "secondary.next";
		_hotkeyMap[ e_Hotkey_SecondaryAegisPrev ] = "secondary.prev";
		
		for ( var s:String in _hotkeyMap ) {
			Input.RegisterHotkey( s, "com.ElTorqiro.AegisHUD.HUD.HotkeyHijacker.HotkeyHandler", e_HotkeyDown, 0 );
		}
		
	}
	
	
	/**
	 * release hijacked hotkeys
	 */
	public static function Release() : Void {

		for ( var s:String in _hotkeyMap ) {
			Input.RegisterHotkey( s, "", e_HotkeyDown, 0 );
		}
	}
	
	/**
	 * callback handler for incoming hotkeys
	 * 
	 * @param	keyID	the id of the key that was pressed
	 */
	public static function HotkeyHandler( keyID:Number ) : Void {
		
		var to:String = _hotkeyMap[ keyID ];
		
		if ( to != undefined ) {
			DistributedValue.SetDValue( AddonInfo.ID + "_Swap", to + "." + new Date() );
		}
	}
}

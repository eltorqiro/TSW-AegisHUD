import com.GameInterface.DistributedValue;
import com.ElTorqiro.AegisHUD.AddonInfo;

class com.ElTorqiro.AegisHUD.HUD.HotkeyHijacker {
	
	// hotkey constants
	public static var e_Hotkey_PrimaryAegisNext:Number = 	132;
	public static var e_Hotkey_PrimaryAegisPrev:Number = 	134;
	public static var e_Hotkey_SecondaryAegisNext:Number = 	133;
	public static var e_Hotkey_SecondaryAegisPrev:Number = 	135;
	
	// static class
	private function HotkeyHijacker() { };
	
	/* 
	 * hotkey handlers used by Input.RegisterHotkey( <number>, "com.ElTorqiro.AegisHUD.HUD.HotkeyHijacker.<name>", _global.Enums.Hotkey.eHotkeyDown , 0 );
	 * 
	 * <name> is a static function
	 * <number> is:
	 * 
	 * 	// 132 = primary forward
	 *	// 133 = secondary forward
	 *	// 134 = primary backward
	 *	// 135 = secondary backward
	 * 
	 * Hotkey names can be got from: AppData\Local\Funcom\TSW\Prefs\<login name>\hotkeys.xml
	 * Hotkey values are from _global.Enums.InputCommand -- although the Enum hasn't been updated in a while, there are still new keys
	*/
	public static function HotkeyPrimaryAegisNext():Void { SwapDisruptor("primary.next"); }
	public static function HotkeyPrimaryAegisPrev():Void { SwapDisruptor("primary.prev"); }
	public static function HotkeySecondaryAegisNext():Void { SwapDisruptor("secondary.next"); }
	public static function HotkeySecondaryAegisPrev():Void { SwapDisruptor("secondary.prev"); }
	
	public static function SwapDisruptor(to:String) : Void {
		DistributedValue.SetDValue( AddonInfo.ID + "_Swap", to + "." + new Date() );
	}
}
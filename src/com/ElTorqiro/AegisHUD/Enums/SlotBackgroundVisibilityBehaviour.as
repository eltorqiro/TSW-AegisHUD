class com.ElTorqiro.AegisHUD.Enums.SlotBackgroundVisibilityBehaviour
{
	private function SlotBackgroundVisibilityBehaviour() { }
	
	public static var NEVER:Number				= 0;
	public static var ALWAYS:Number 			= 1;
	public static var ONLY_WHEN_SLOTTED:Number	= 2;
	
	public static function get list():Object
	{
		var values:Object = { };

		values[SlotBackgroundVisibilityBehaviour.NEVER] 			= "Never";
		values[SlotBackgroundVisibilityBehaviour.ALWAYS] 			= "Always";
		values[SlotBackgroundVisibilityBehaviour.ONLY_WHEN_SLOTTED] = "Only when slotted";
		
		return values;
	}
	
}
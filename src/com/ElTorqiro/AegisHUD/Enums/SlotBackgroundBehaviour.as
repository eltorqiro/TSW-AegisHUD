class com.ElTorqiro.AegisHUD.Enums.SlotBackgroundBehaviour
{
	private function SlotBackgroundBehaviour() { }
	
	public static var NEVER:Number				= 0;
	public static var ALWAYS:Number 			= 1;
	public static var WHEN_SLOTTED:Number	= 2;
	
	public static function get list():Object
	{
		var values:Object = { };

		values[SlotBackgroundBehaviour.NEVER] 			= "Never";
		values[SlotBackgroundBehaviour.ALWAYS] 			= "Always";
		values[SlotBackgroundBehaviour.WHEN_SLOTTED] 	= "Only when slotted";
		
		return values;
	}
	
}
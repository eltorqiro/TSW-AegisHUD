class com.ElTorqiro.AegisHUD.Enums.ActiveAegisBackgroundTintBehaviour
{
	private function ActiveAegisBackgroundTintBehaviour() { }
	
	public static var NEVER:Number				= 0;
	public static var STANDARD:Number			= 1;
	public static var AEGIS_TYPE:Number			= 2;
	
	public static function get list():Object
	{
		var values:Object = { };

		values[ActiveAegisBackgroundTintBehaviour.NEVER] 			= "Never";
		values[ActiveAegisBackgroundTintBehaviour.STANDARD] 		= "Standard";
		values[ActiveAegisBackgroundTintBehaviour.AEGIS_TYPE] 		= "AEGIS Type";
		
		return values;
	}
	
}
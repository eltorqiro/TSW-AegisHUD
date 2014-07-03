class com.ElTorqiro.AegisHUD.Enums.AegisBarLayoutStyles
{
	private function AegisBarLayoutStyles()	{ }
	
	public static var VERTICAL:Number = 0;
	public static var HORIZONTAL:Number = 1;
	
	public static function get list():Object
	{
		var values:Object = { };

		values[AegisBarLayoutStyles.VERTICAL] = "Vertical";
		values[AegisBarLayoutStyles.HORIZONTAL] = "Horizontal";
		
		return values;
	}
	
}
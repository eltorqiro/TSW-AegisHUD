class com.ElTorqiro.AegisHUD.Enums.AegisBarLayoutStyles
{
	private function AegisBarLayoutStyles()	{ }
	
	public static var HORIZONTAL:Number = 0;
	public static var VERTICAL:Number = 1;
	
	public static function get list():Object
	{
		var values:Object = { };

		values[AegisBarLayoutStyles.HORIZONTAL] = "Horizontal";
		values[AegisBarLayoutStyles.VERTICAL] = "Vertical";
		
		return values;
	}
	
}
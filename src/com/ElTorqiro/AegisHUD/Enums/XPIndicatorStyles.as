class com.ElTorqiro.AegisHUD.Enums.XPIndicatorStyles {
	private function XPIndicatorStyles()	{ }
	
	public static var ProgressBar:Number = 0;
	public static var Numbers:Number = 1;
	
	public static function get list():Object
	{
		var values:Object = { };

		values[XPIndicatorStyles.ProgressBar] = "Progress Bar";
		values[XPIndicatorStyles.Numbers] = "Numbers";
		
		return values;
	}
	
}
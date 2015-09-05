import com.GameInterface.Game.Character;
import com.GameInterface.Tooltip.TooltipDataProvider;
import com.Utils.Signal;

import com.ElTorqiro.AegisHUD.HUD.Enums;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.HUD.AegisXPMonitor {
	
	public function AegisXPMonitor( player:Character ) {
		
		this.player = player;

		/*
		 * table of raw xp values to QL levels
		 * 
		 * // 1.145x ?
		 * function for defining interval between two adjoining levels is:
		 * 
		 * interval = 42000 * (1.145 ^ n)
		 * 
		 * except between 1.8 and 1.9?
		 */
		levels[ "1.0" ] = { min: 0, max: 42000 };			// 42000
		levels[ "1.1" ] = { min: 42001, max: 90090 };		// 48090
		levels[ "1.2" ] = { min: 90091, max: 145153 };		// 55063
		levels[ "1.3" ] = { min: 145154, max: 208200 };		// 63047
		levels[ "1.4" ] = { min: 208201, max: 280389 };		// 72189
		levels[ "1.5" ] = { min: 280390, max: 363046 };		// 82657
		levels[ "1.6" ] = { min: 363047, max: 457687 };		// 94641
		levels[ "1.7" ] = { min: 457688, max: 566052 };		// 108365
		levels[ "1.8" ] = { min: 566053, max: 690130 };		// 124078
		levels[ "1.9" ] = { min: 690131, max: 829593 };		// 139463
		levels[ "2.0" ] = { min: 829594, max: 10000000 };
		
		// known aegis ids
		aegisIDs = {
			
		};
		
		// setup offensive target change listener
		player.SignalTokenAmountChanged.Connect( updateAegisItemXP, this );

		// create signals
		SignalXPChanged = new Signal();
		
		// initial trigger
	}
	

	/**
	 * updates the xp values for a given aegis item id
	 * 
	 * @param	tokenID
	 * @param	value
	 */
	private function updateAegisItemXP( aegisID:Number, value:Number ) : Void {

		var aegisItem:Object = aegisItems[ aegisID ];

		// only proceed if update is for a known aegis item
		if ( aegisItem == undefined ) return;
		
		
		// TODO: apply a throttle for fetching xp on a per item basis, to avoid tooltip-scraping spam
		

		var xp:Number = 0;
		
		// fetch tooltip for item, if possible
		var slot:Object = slotFromAegisID[ aegisID ];
		var xpString:String = TooltipDataProvider.GetInventoryItemTooltip( slot.inventoryID, slot.position ).m_Descriptions[2];

		// can't let indexOf run against undefined, it halts the game
		if ( xpString != undefined ) {

			// get the first occurence of %
			var endPos:Number = xpString.indexOf('%');
			
			if ( LDBFormat.GetCurrentLanguageCode() == 'de' ) endPos--;	// german client has a space between number and %

			// woork backwards until we hit the end of the html tag that wraps the percent text
			for ( var startPos:Number = endPos; startPos >= 0; startPos-- ) {
				
				var char:String = xpString.charAt(startPos);
				
				// not a number sequence
				if ( char == ' ' || char == '>' ) {
					break;
				}
			}

			xp = Number(xpString.substring(++startPos, endPos));
			//xp = Math.floor( Number(xpString.substring(++startPos, endPos)) );
		}

		aegisItem.xp = value;
		aegisItem.xpPercent = xp;
		
		// signal an update
		SignalItemXPChanged.Emit( slot.group, slot.name );
		
	}

	
	
	/*
	 * internal variables
	 */
	
	private var player:Character;
	private var aegisIDs:Object = { };
	private var levels:Object = { };
	
	
	/*
	 * properties
	 */
	
	public var SignalXPChanged:Signal;
	
}
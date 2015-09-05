import com.GameInterface.Game.Character;

import com.ElTorqiro.AegisHUD.Server.AegisServer;
import com.ElTorqiro.AegisHUD.App;
import com.ElTorqiro.AegisHUD.Const;

import com.GameInterface.UtilsBase;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.AutoSwapper {
	
	public function AutoSwapper() {

		App.debug( "AutoSwapper: constructor" );
		
		character = Character.GetClientCharacter();
		
		// map of shield stats to types (in order of searching)
		shieldTypeMap = [
			{ stat: _global.Enums.Stat.e_CurrentPinkShield, aegisType: _global.Enums.AegisTypes.e_AegisPink },
			{ stat: _global.Enums.Stat.e_CurrentBlueShield, aegisType: _global.Enums.AegisTypes.e_AegisBlue },
			{ stat: _global.Enums.Stat.e_CurrentRedShield,  aegisType: _global.Enums.AegisTypes.e_AegisRed }
		];
		
		// setup target change listeners
		character.SignalOffensiveTargetChanged.Connect( attachCurrentTargets, this );
		character.SignalDefensiveTargetChanged.Connect( attachCurrentTargets, this );

		// initial trigger for current targets
		attachCurrentTargets();
	}

	/**
	 * attaches listeners to current targets
	 */
	private function attachCurrentTargets() : Void {

		var newOffensiveTarget:Character = Character.GetCharacter( character.GetOffensiveTarget() );
		var newDefensiveTarget:Character = Character.GetCharacter( character.GetDefensiveTarget() );
		
		// offensive target has changed
		if ( newOffensiveTarget != offensiveTarget ) {
			
			App.debug( "AutoSwapper: offensive target changed = " + newOffensiveTarget.GetName() );
			
			offensiveTarget.SignalStatChanged.Disconnect( offensiveStatChanged, this );
			offensiveTarget = newOffensiveTarget;
			offensiveTarget.SignalStatChanged.Connect( offensiveStatChanged, this );
			
			offensiveShield = null;
			offensiveDisruptor = null;
			
			updateOffensiveDisruptorType();
			updateOffensiveShieldType();
		}
		
		// defensive target has changed
		if ( newDefensiveTarget != defensiveTarget ) {
			
			App.debug( "AutoSwapper: defensive target changed = " + newDefensiveTarget.GetName() );
			
			defensiveTarget.SignalStatChanged.Disconnect( defensiveStatChanged, this );
			defensiveTarget = newDefensiveTarget;
			defensiveTarget.SignalStatChanged.Connect( defensiveStatChanged, this );
			
			defensiveShield = null;
			
			updateDefensiveShieldType();
		}
		
	}

	/**
	 * handler for offensive target stat changes, for monitoring shield levels and disruptor type
	 * 
	 * @param	statID
	 * @param	value
	 */
	private function offensiveStatChanged( stat:Number, value:Number ) : Void {
		
		switch( stat ) {
			case _global.Enums.Stat.e_CurrentPinkShield:
			case _global.Enums.Stat.e_CurrentBlueShield:
			case _global.Enums.Stat.e_CurrentRedShield:
				updateOffensiveShieldType();
			break;
			
			case _global.Enums.Stat.e_ColorCodedDamageType:
				updateOffensiveDisruptorType();
			break;
		}
		
	}

	/**
	 * checks the current shield type on the target
	 */
	private function updateOffensiveShieldType() : Void {
		
		var targetShieldType:Number;
		
		// determine the target's shield type
		for ( var i:Number = 0; i < shieldTypeMap.length; i++ ) {
			if ( offensiveTarget.GetStat( shieldTypeMap[i].stat, 2 ) > 0 ) {
				targetShieldType = shieldTypeMap[i].aegisType;
				break;
			}
		}

		// if it is different to our last known shield type, update
		if ( targetShieldType != offensiveShield ) {
			offensiveShield = targetShieldType;
			swapDisruptors( targetShieldType, Const.e_AutoSwapOffensiveShield );
		}
		
	}

	/**
	 * checks the current disruptor type on the offensive target
	 */
	private function updateOffensiveDisruptorType() : Void {
		
		// discover the aegis damage type the target deals out
		var targetDisruptorType:Number = offensiveTarget.GetStat(_global.Enums.Stat.e_ColorCodedDamageType, 2);

		// if it is different to our last known disruptor type, update
		if ( targetDisruptorType != offensiveDisruptor ) {
			offensiveDisruptor = targetDisruptorType;
			swapShield( targetDisruptorType, Const.e_AutoSwapOffensiveDisruptor );
		}

	}
	
	/**
	 * handler for defensive target stat changes, for monitoring shield levels
	 * 
	 * @param	statID
	 * @param	value
	 */
	private function defensiveStatChanged( stat:Number, value:Number ) : Void {
		
		switch( stat ) {
			case _global.Enums.Stat.e_PlayerAegisShieldType:
				updateDefensiveShieldType();
			break;
			
			// player disruptor type can be fetched the same way it is done from mobs, this is here as a reminder
			/*
			case _global.Enums.Stat.e_ColorCodedDamageType:
				updateDisruptorType();
			break;
			*/
		}
		
	}
	
	/**
	 * checks the current shield type on the defensive target
	 */
	private function updateDefensiveShieldType() : Void {
		
		// fetch current shield type
		var targetShieldType:Number = defensiveTarget.GetStat( _global.Enums.Stat.e_PlayerAegisShieldType, 2 );

		// if it is different to our last known shield type, update
		if ( targetShieldType != defensiveShield ) {
			defensiveShield = targetShieldType;
			swapDisruptors( targetShieldType, Const.e_AutoSwapDefensiveShield );
		}
		
	}

	/**
	 * swaps disruptors to an aegis type
	 * 
	 * @param	aegisType
	 * @param	source		the target event that triggered the potential swap
	 */
	public function swapDisruptors( aegisType:Number, source:Number ) : Void {

		var groups:Object = AegisServer.groups;
		
		if ( !aegisType ) return;
		
		for ( var s:String in groups ) {
			if ( groups[s].type == "disruptor" && App.prefs.getVal( "autoSwap.type." + s ) == source ) {
				App.debug( "AutoSwapper: swapping disruptor " + s + " to " + aegisType );
				AegisServer.selectAegisType( s, aegisType );
			}
		}
		
	}
		
	/**
	 * swaps shield to an aegis type
	 * 
	 * @param	aegisType
	 * @param	source		the target event that triggered the potential swap
	 */
	public function swapShield( aegisType:Number, source:Number ) : Void {
		
		if ( aegisType && App.prefs.getVal( "autoSwap.type.shield" ) == source) {
			App.debug( "AutoSwapper: swapping shield to " + aegisType );
			AegisServer.selectAegisType( "shield", aegisType );
		}
		
	}

	/*
	 * internal variables
	 */

	private var character:Character;
	private var offensiveTarget:Character;
	private var defensiveTarget:Character;

	private var offensiveShield:Number;
	private var offensiveDisruptor:Number;
	
	private var defensiveShield:Number;

	private var shieldTypeMap:Object;
	
	/*
	 * properties
	 */
	
}
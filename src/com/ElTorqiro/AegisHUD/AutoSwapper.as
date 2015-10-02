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
			{ absolute: _global.Enums.Stat.e_AbsolutePinkShield, healthPercent: _global.Enums.Stat.e_PercentPinkShield, current: _global.Enums.Stat.e_CurrentPinkShield, aegisType: _global.Enums.AegisTypes.e_AegisPink },
			{ absolute: _global.Enums.Stat.e_AbsoluteBlueShield, healthPercent: _global.Enums.Stat.e_PercentBlueShield, current: _global.Enums.Stat.e_CurrentBlueShield, aegisType: _global.Enums.AegisTypes.e_AegisBlue },
			{ absolute: _global.Enums.Stat.e_AbsoluteRedShield, healthPercent: _global.Enums.Stat.e_PercentRedShield, current: _global.Enums.Stat.e_CurrentRedShield,  aegisType: _global.Enums.AegisTypes.e_AegisRed }
		];
		
		// setup pref change listener
		App.prefs.SignalValueChanged.Connect( prefChangedHandler, this );

		// setup target change listeners
		character.SignalOffensiveTargetChanged.Connect( attachOffensiveTarget, this );
		character.SignalDefensiveTargetChanged.Connect( attachDefensiveTarget, this );
		
		// initial trigger for current targets
		attachCurrentTargets();
	}

	/**
	 * attaches listeners to current targets
	 */
	private function attachCurrentTargets() : Void {

		attachOffensiveTarget();
		attachDefensiveTarget();

	}

	/**
	 * attach to offensive target
	 */
	private function attachOffensiveTarget() : Void {
		
		enemy.character.SignalStatChanged.Disconnect( enemyStatChanged, this );
		enemy = { };
		enemy.character = Character.GetCharacter( character.GetOffensiveTarget() );
		
		// handle pvp opponents being classified as enemies
		if ( enemy.character.GetID().IsPlayer() && !App.prefs.getVal( "autoSwap.match.enemy.players" ) ) {
			delete enemy.character;
		}
		
		if ( enemy.character ) {
			enemy.character.SignalStatChanged.Connect( enemyStatChanged, this );
			updateEnemy();
		}
		
	}
	
	/**
	 * attach to defensive target
	 */
	private function attachDefensiveTarget() : Void {
		
		friend.character.SignalStatChanged.Disconnect( friendStatChanged, this );
		friend = { };
		friend.character = Character.GetCharacter( character.GetDefensiveTarget() );
		
		// handle self being classified as friend
		if ( friend.character.IsClientChar() && !App.prefs.getVal( "autoSwap.match.friendly.self" ) ) {
			delete friend.character;
		}
		
		if ( friend.character ) {
			friend.character.SignalStatChanged.Connect( friendStatChanged, this );
			updateFriend();
		}
		
	}
	
	/**
	 * handler for offensive target stat changes, for monitoring shield levels and disruptor type
	 * 
	 * @param	statID
	 * @param	value
	 */
	private function enemyStatChanged( stat:Number, value:Number ) : Void {
		
		switch( stat ) {
			case _global.Enums.Stat.e_CurrentPinkShield:
			case _global.Enums.Stat.e_CurrentBlueShield:
			case _global.Enums.Stat.e_CurrentRedShield:
			case _global.Enums.Stat.e_ColorCodedDamageType:
				updateEnemy();
			break;
		}
		
	}

	/**
	 * updates stats for offensive targets and triggers aegis swap if appropriate
	 */
	private function updateEnemy() : Void {
		
		// disruptor type (works for both players and mobs)
		enemy.disruptorType = enemy.character.GetStat( _global.Enums.Stat.e_ColorCodedDamageType, 2 );
		
		// shield type (initially look for player stats, since mobs won't have them)
		enemy.shieldType = enemy.character.GetStat( _global.Enums.Stat.e_PlayerAegisShieldType, 2 );
		enemy.hasShield = enemy.shieldType != 0;

		// look for mob stats if player stats weren't found
		for ( var i:Number = 0; i < shieldTypeMap.length && !enemy.shieldType; i++ ) {

			// detect current shield type
			if ( enemy.character.GetStat( shieldTypeMap[i].current, 2 ) > 0 ) {
				enemy.shieldType = shieldTypeMap[i].aegisType;
				enemy.hasShield = true;
			}
			
			// detect if enemy mob has shield capability
			if ( !enemy.hasShield && ( enemy.character.GetStat( shieldTypeMap[i].healthPercent, 2 ) > 0 || enemy.character.GetStat( shieldTypeMap[i].absolute, 2 ) > 0 ) ) {
				enemy.hasShield = true;
			}

		}
		
		if ( (enemy.disruptorType && enemy.disruptorType != enemy.lastDisruptorType) || (enemy.shieldType && enemy.shieldType != enemy.lastShieldType) ) {
			swapControllers( enemy );
		}
		
		enemy.lastDisruptorType = enemy.disruptorType;
		enemy.lastShieldType = enemy.shieldType;
		
	}

	/**
	 * handler for defensive target stat changes, for monitoring shield levels
	 * 
	 * @param	statID
	 * @param	value
	 */
	private function friendStatChanged( stat:Number, value:Number ) : Void {
		
		switch( stat ) {
			case _global.Enums.Stat.e_PlayerAegisShieldType:
				// only trigger this if the defensive target is not self
				updateFriend();
			break;
			
			// player disruptor type can be fetched the same way it is done from mobs, this is here as a reminder
			/*
			case _global.Enums.Stat.e_ColorCodedDamageType:
				
			break;
			*/
		}
		
	}

	/**
	 * updates stats for defensive targets and triggers aegis swap if appropriate
	 */
	private function updateFriend() : Void {
		
		// currently present shield type
		friend.shieldType = friend.character.GetStat( _global.Enums.Stat.e_PlayerAegisShieldType, 2 );;
		
		if ( friend.shieldType && friend.shieldType != friend.lastShieldType ) {
			swapControllers( friend );
		}
	
		friend.lastShieldType = friend.shieldType;
	}

	/**
	 * swaps aegis controllers to aegis types, based on match rules
	 * 
	 * @param source	"enemy" or "friend", depending which stat base changed to trigger the swap
	 * 
	 */
	public function swapControllers( source:Object ) : Void {

		var groups:Object = AegisServer.groups;
		
		for ( var s:String in groups ) {
				
			var matchPref:Number = App.prefs.getVal( "autoSwap.type." + s );
			var swapToType:Number;
			
			if ( source == enemy ) {
			
				switch ( matchPref ) {
					
					case Const.e_AutoSwapOffensiveShield:
						swapToType = enemy.shieldType;
					break;
					
					case Const.e_AutoSwapOffensiveShieldXorDisruptor:
						swapToType = enemy.hasShield ? enemy.shieldType : enemy.disruptorType;
					break;
					
					case Const.e_AutoSwapOffensiveDisruptor:
						swapToType = enemy.disruptorType;
					break;

				}
				
			}
			
			else {
				
				switch ( matchPref ) {
					
					case Const.e_AutoSwapDefensiveShield:
						swapToType = friend.shieldType;
					break;
					
				}
				
			}
			
			if ( swapToType ) {
				App.debug( "AutoSwapper: swapping " + s + " to " + swapToType );
				AegisServer.selectAegisType( s, swapToType );
			}

		}
		
	}
		
	/**
	 * ensures new pref focus for autoswap is immediately acted on when pref changes
	 * 
	 * @param	name
	 * @param	newValue
	 * @param	oldValue
	 */
	private function prefChangedHandler( name:String, newValue, oldValue ) : Void {

		if ( name.indexOf( "autoSwap.type." ) == 0 || name.indexOf( "autoSwap.match.") == 0 ) {
			attachCurrentTargets();
		}

	}
	
	/*
	 * internal variables
	 */

	private var character:Character;

	private var enemy:Object;
	private var friend:Object;
	
	private var shieldTypeMap:Object;
	
	/*
	 * properties
	 */
	
}
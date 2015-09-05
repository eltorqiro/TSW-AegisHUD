import com.GameInterface.Game.Character;
import com.Utils.Signal;

import com.GameInterface.UtilsBase;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.AutoSwap.OffensiveTargetWatcher {
	
	public function OffensiveTargetWatcher( focus:Character ) {
		
		this.focus = focus;
		
		//focus = Character.GetClientCharacter();

		// map of shield stats to types (in order of searching)
		shieldTypeMap = [
			{ stat: _global.Enums.Stat.e_CurrentPinkShield, aegisType: _global.Enums.AegisTypes.e_AegisPink },
			{ stat: _global.Enums.Stat.e_CurrentBlueShield, aegisType: _global.Enums.AegisTypes.e_AegisBlue },
			{ stat: _global.Enums.Stat.e_CurrentRedShield,  aegisType: _global.Enums.AegisTypes.e_AegisRed }
		];
		
		// setup offensive target change listener
		focus.SignalOffensiveTargetChanged.Connect( attachCurrentTarget, this );

		// create signals
		SignalDisruptorTypeChanged = new Signal();
		SignalShieldTypeChanged = new Signal();
		
		// initial trigger
		attachCurrentTarget();
	}
	
	/**
	 * attaches listeners to current offensive target
	 */
	private function attachCurrentTarget() : Void {

		detachLastTarget();
		target = Character.GetCharacter( focus.GetOffensiveTarget() );
		
		// setup listener for target shield stat changing
		target.SignalStatChanged.Connect( statChangedHandler, this );
		
		updateShieldType();
		updateDisruptorType();
		
	}
	
	/**
	 * detaches listeners from previous offensive target
	 */
	private function detachLastTarget() : Void {
		target.SignalStatChanged.Disconnect( statChangedHandler, this );
		target = null;
		lastShieldType = null;
		lastDisruptorType = null;
	}

	/**
	 * handler for target stat changes, for monitoring shield levels and disruptor type
	 * 
	 * @param	statID
	 * @param	value
	 */
	private function statChangedHandler( stat:Number, value:Number ) : Void {
		
		switch( stat ) {
			case _global.Enums.Stat.e_CurrentPinkShield:
			case _global.Enums.Stat.e_CurrentBlueShield:
			case _global.Enums.Stat.e_CurrentRedShield:
				updateShieldType();
			break;
			
			case _global.Enums.Stat.e_ColorCodedDamageType:
				updateDisruptorType();
			break;
		}
		
	}
	
	/**
	 * checks the current shield type on the target, and signals if it has changed
	 */
	private function updateShieldType() : Void {
		
		var targetShieldType:Number;
		
		for ( var i:Number = 0; i < shieldTypeMap.length; i++ ) {
			if ( target.GetStat( shieldTypeMap[i].stat, 2 ) > 0 ) {
				targetShieldType = shieldTypeMap[i].aegisType;
				break;
			}
		}

		if ( targetShieldType != lastShieldType ) {
			lastShieldType = targetShieldType;

			if ( targetShieldType ) {
				SignalShieldTypeChanged.Emit( targetShieldType );
			}
		}
		
	}
	
	/**
	 * checks the current disruptor type on the target, and signals if it has changed
	 */
	private function updateDisruptorType() : Void {
		
		// discover the aegis damage type the target deals out
		var targetDisruptorType:Number = target.GetStat(_global.Enums.Stat.e_ColorCodedDamageType, 2);

		if ( targetDisruptorType != lastDisruptorType ) {
			lastDisruptorType = targetDisruptorType;

			if ( targetDisruptorType ) {
				SignalDisruptorTypeChanged.Emit( targetDisruptorType );
			}
		}

	}
	
	/**
	 * cleans up resources and references used by the object
	 */
	public function dispose() : Void {
		focus.SignalOffensiveTargetChanged.Disconnect( attachCurrentTarget, this );
		focus = null;
		
		detachLastTarget();
		
		SignalDisruptorTypeChanged = null;
		SignalShieldTypeChanged = null;
		
	}
	
	/*
	 * internal variables
	 */
	
	private var focus:Character;
	private var target:Character;
	
	private var lastShieldType:Number;
	private var lastDisruptorType:Number;
	
	private var shieldTypeMap:Array;
	
	
	/*
	 * properties
	 */
	
	public var SignalShieldTypeChanged:Signal;
	public var SignalDisruptorTypeChanged:Signal;
	
	public function get shieldType() : Number { return lastShieldType; }
	public function get disruptorType() : Number { return lastDisruptorType; };
	
}
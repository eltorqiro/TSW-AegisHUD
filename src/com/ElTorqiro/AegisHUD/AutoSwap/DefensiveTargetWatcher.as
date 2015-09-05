import com.GameInterface.Game.Character;
import com.Utils.Signal;

import com.GameInterface.UtilsBase;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.AutoSwap.DefensiveTargetWatcher {
	
	public function DefensiveTargetWatcher( focus:Character ) {
		
		this.focus = focus;
		
		// setup target change listener
		focus.SignalDefensiveTargetChanged.Connect( attachCurrentTarget, this );

		// create signals
		SignalDisruptorTypeChanged = new Signal();
		SignalShieldTypeChanged = new Signal();
		
		// initial trigger
		attachCurrentTarget();
	}
	
	/**
	 * attaches listeners to current defensive target
	 */
	private function attachCurrentTarget() : Void {

		detachLastTarget();
		target = Character.GetCharacter( focus.GetDefensiveTarget() );
		
		// setup listener for target shield stat changing
		target.SignalStatChanged.Connect( statChangedHandler, this );
		
		updateShieldType();
		updateDisruptorType();
		
	}
	
	/**
	 * detaches listeners from previous defensive target
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
			case _global.Enums.Stat.e_PlayerAegisShieldType:
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
		
		var targetShieldType:Number = target.GetStat( _global.Enums.Stat.e_PlayerAegisShieldType, 2 );
		
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
		var targetDisruptorType:Number = target.GetStat( _global.Enums.Stat.e_ColorCodedDamageType, 2 );

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
		focus.SignalDefensiveTargetChanged.Disconnect( attachCurrentTarget, this );
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
	
	
	/*
	 * properties
	 */
	
	public var SignalShieldTypeChanged:Signal;
	public var SignalDisruptorTypeChanged:Signal;
	
	public function get shieldType() : Number { return lastShieldType; }
	public function get disruptorType() : Number { return lastDisruptorType; };
	
}
import com.GameInterface.Game.Character;
import com.Utils.Signal;

import com.ElTorqiro.AegisHUD.AutoSwap.OffensiveTargetWatcher;
import com.ElTorqiro.AegisHUD.AutoSwap.DefensiveTargetWatcher;
import com.ElTorqiro.AegisHUD.Server.AegisServer;

import com.GameInterface.UtilsBase;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.AutoSwap.AutoSwapperHealing {
	
	public function AutoSwapperHealing() {
		
		// setup listeners for target aegis types changing
		offensiveWatcher = new OffensiveTargetWatcher( Character.GetClientCharacter() );
		offensiveWatcher.SignalDisruptorTypeChanged.Connect( autoSwapShield );
		targetAegisWatcher.SignalShieldTypeChanged.Connect( autoSwapDisruptors );
		
		autoSwapNow();
	}

	/**
	 * trigger an autoswap event for disruptors and shield now
	 */
	public function autoSwapNow() : Void {
		autoSwapDisruptors( targetAegisWatcher.shieldType );
		autoSwapShield( targetAegisWatcher.disruptorType );
	}
	
	/**
	 * swaps disruptors to an aegis type
	 * 
	 * @param	aegisType
	 */
	public function autoSwapDisruptors( aegisType:Number ) : Void {
		
		if ( Preferences.getValue( "autoSwap.primary.enabled" ) && aegisType ) {
			AegisServer.selectAegisType( "primary", aegisType );
		}
		
		if ( Preferences.getValue( "autoSwap.secondary.enabled" ) && aegisType ) {
			AegisServer.selectAegisType( "secondary", aegisType );
		}
		
	}
	
	
	/**
	 * swaps shield to an aegis type
	 * 
	 * @param	aegisType
	 */
	public function autoSwapShield( aegisType:Number ) : Void {
		
		if ( Preferences.getValue( "autoSwap.shield.enabled" ) && aegisType ) {
			AegisServer.selectAegisType( "shield", aegisType );
		}
		
	}
	
	/**
	 * cleans up resources and references used by the object
	 */
	public function dispose() : Void {
		
		targetAegisWatcher.SignalDisruptorTypeChanged.Disconnect( autoSwapShield );
		targetAegisWatcher.SignalShieldTypeChanged.Disconnect( autoSwapDisruptors );
		targetAegisWatcher.dispose();
		targetAegisWatcher = null;
	}
	
	/*
	 * internal variables
	 */

	private var offensiveWatcher:OffensiveTargetWatcher;
	private var defensiveWatcher:DefensiveTargetWatcher;
	
	/*
	 * properties
	 */
	
}
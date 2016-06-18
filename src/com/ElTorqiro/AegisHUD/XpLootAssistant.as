import com.ElTorqiro.AegisHUD.Server.AegisServer;
import com.ElTorqiro.AegisHUD.Server.AegisServerGroup;
import com.ElTorqiro.AegisHUD.Server.AegisServerSlot;
import com.ElTorqiro.AegisHUD.App;
import com.ElTorqiro.AegisHUD.Const;

import com.GameInterface.Game.Character;
import com.GameInterface.UtilsBase;

import mx.utils.Delegate;


/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.XpLootAssistant {
	
	public function XpLootAssistant() {

		App.debug( "XP Loot Assistant: constructor" );
		
		character = Character.GetClientCharacter();
		
		// attach to combat state signals
		character.SignalToggleCombat.Connect( combatToggleHandler, this );
		character.SignalOffensiveTargetChanged.Connect( offensiveTargetChangedHandler, this );
		
		// clear initial event times
		enteredCombatTime = leftCombatTime = new Date();
		
		// setup pref change listener
		App.prefs.SignalValueChanged.Connect( prefChangedHandler, this );
	}

	/**
	 * handles combat toggle signals to ensure trigger rules are adhered to
	 */
	private function combatToggleHandler() : Void {
		
		// remember when combat started
		// used to later avoid the flip/flop issues caused by e.g. "you are not authorized" robots in Kaidan
		if ( character.IsThreatened() ) {
			enteredCombatTime = new Date();
		}
		
		// leaving combat, ensure this wasn't a flip/flop by checking how long combat lasted
		// -- may cause issues when one-shotting mobs, but that is unlikely to happen with mobs that actually have xp
		else if ( (new Date() - enteredCombatTime) > 500 ) {
			leftCombatTime = new Date();
		}
	}
	
	/**
	 * handles offensive target changes, to capture the death-moments of mobs that occur immediately after combat ends
	 */
	private function offensiveTargetChangedHandler() : Void {

		// assume if the target is now nothing, and combat ended recently
		// that it was because of a victory and there is probably loot nearby
		if ( !character.IsThreatened() && (new Date() - leftCombatTime) < 500 && character.GetOffensiveTarget().IsNull() ) {
			swap();
		}
	}
	
	/**
	 * swaps controllers based on selected profile
	 */
	public function swap() : Void {
		
		// don't perform swap is character is in combat
		if ( character.IsThreatened() ) {
			return;
		}

		var swapTypePref:Number = App.prefs.getVal( "xpLootAssistant.type" );
		
		// act on each group
		var groups:Object = AegisServer.groups;
		
		for ( var groupID:String in groups ) {
			var chosenSlot:AegisServerSlot = undefined;
			var slots:Object = groups[ groupID ].slots;
			
			// iterate slots in grop
			for ( var slotID:String in slots ) {
				var slot:AegisServerSlot = slots[ slotID ];
				
				if ( slot.xpRaw == undefined || slot.xpPercent >= 100 ) continue;

				// apply selection rules
				switch ( swapTypePref ) {
					
					case Const.e_XpLootAssistantHighest:
						if ( chosenSlot == undefined || chosenSlot.xpRaw < slot.xpRaw ) {
							chosenSlot = slot;
						}
						
					break;
					
					case Const.e_XpLootAssistantLowest:
						if ( chosenSlot == undefined || chosenSlot.xpRaw > slot.xpRaw ) {
							chosenSlot = slot;
						}
					break;
					
				}
			}
			
			// swap to the chosen slot
			App.debug( "XP Loot Assistant: swapping " + groupID + " to " + chosenSlot.id );
			AegisServer.selectSlot( chosenSlot.group.id, chosenSlot.id );
		}
		
	}
	
	/**
	 * ensures new rules are applied immediately when pref changes
	 * 
	 * @param	name
	 * @param	newValue
	 * @param	oldValue
	 */
	private function prefChangedHandler( name:String, newValue, oldValue ) : Void {

		switch ( name ) {
			
			case "xpLootAssistant.type":
				swap();
			break;
			
		}
		
	}
	
	/*
	 * internal variables
	 */

	private var character:Character;
	private var enteredCombatTime:Date;
	private var leftCombatTime:Date;
	
	/*
	 * properties
	 */
	
}
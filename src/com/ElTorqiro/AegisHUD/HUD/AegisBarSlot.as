import com.ElTorqiro.AegisHUD.HUD.BarSlot;
import com.ElTorqiro.AegisHUD.Server.AegisServerSlot;
import com.Utils.ID32;
import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;
import gfx.core.UIComponent;
import flash.filters.GlowFilter;

import com.ElTorqiro.AegisHUD.Enums;
import com.ElTorqiro.AegisHUD.Server.AegisServer;
import com.ElTorqiro.AegisHUD.Preferences;

import com.GameInterface.UtilsBase;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.HUD.AegisBarSlot extends BarSlot {

	public function AegisBarSlot() {

		UtilsBase.PrintChatText("aegisbarslot: constructor");
		
		m_XP._visible = false;
		m_Background._visible = false;
		
	}

	private function configUI() : Void {
		super.configUI();
		
		Preferences.addEventListener( "ui.icons.type", this, "refreshItem" );
		Preferences.addEventListener( "ui.xp.enabled", this, "refreshXP" );
	}
	
	public function draw() : Void {
		
		var slot:AegisServerSlot = AegisServer.getSlot( groupID, slotID );
		var tint:Number = Preferences.getValue( "tints.aegis." + slot.aegisTypeName );
		
		// draw selection highlights
		if ( slot.selected ) {
			
			// apply glow of selected aegis
			if ( Preferences.getValue( "ui.aegis.selected.neon" ) ) {
				m_Icon.filters = [ new GlowFilter( tint, 0.8, 6, 6, 2, 3, false, false ) ];
			}
			
			// show background box
			if ( Preferences.getValue( "ui.aegis.selected.background.enabled" ) ) {
				
				// apply glow on background box
				if ( Preferences.getValue( "ui.aegis.selected.background.neon" ) ) {
					m_Background.filters = [ new GlowFilter( tint, 0.8, 6, 6, 2, 3, false, false ) ];
				}
				
				m_Background._visible = true;
			}
		}
		
		else {
			m_Icon.filters = [];
			m_Background._visible = false;
		}
		
	}
	
	public function refreshItem() : Void {
		super.refreshItem();
		refreshXP();
	}
	
	public function dispose() : Void {
		
		Preferences.removeEventListener( "ui.icons.type", this, "refreshItem" );
		Preferences.removeEventListener( "ui.xp.enabled", this, "refreshXP" );
		
		super.dispose();
	}
	
	/**
	 * refreshes aegis item xp from the server
	 */
	public function refreshXP() : Void {

		var slot:AegisServerSlot = AegisServer.getSlot( groupID, slotID );
		var xp:Number = Math.floor( slot.xpPercent );
		
		if ( !Preferences.getValue("ui.xp.enabled") || ( xp >= 100 && Preferences.getValue("ui.xp.hideWhenFull") || slot.item == undefined ) ) {
			m_XP._visible = false;
			return;
		}

		var textFormat:TextFormat = new TextFormat();
		textFormat.color = xp < 100 ? Preferences.getValue("tints.xp.progress") : Preferences.getValue("tints.xp.full");
		
		m_XP.t_XP.setTextFormat( textFormat );
		m_XP.t_XP.setNewTextFormat( textFormat );
		
		m_XP.t_XP.text = xp;
		m_XP._visible = true;
		
	}

	private function onPress( controllerIdx:Number, keyboardOrMouse:Number, button:Number ) : Void {
		dispatchEvent( { type:"click", shift: Key.isDown(Key.SHIFT), ctrl: Key.isDown(Key.CONTROL), button:button } );
	}
	
	/**
	 * internal variables
	 */
	
	public var m_Background:MovieClip;
	public var m_XP:MovieClip;
	
	
	/**
	 * properties
	 */
	
	// whether the slot is selected or not
	private var _selected:Boolean;
	public function get selected() : Boolean { return _selected; }
	public function set selected( value:Boolean ) : Void {
		_selected = value;
		invalidate();
	}
	
}
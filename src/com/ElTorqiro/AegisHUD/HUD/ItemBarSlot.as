import com.Utils.ID32;
import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;
import gfx.core.UIComponent;
import flash.filters.GlowFilter;

import com.ElTorqiro.AegisHUD.Enums;
import com.ElTorqiro.AegisHUD.Server.AegisServer;
import com.ElTorqiro.AegisHUD.Preferences;
import com.ElTorqiro.AegisHUD.HUD.BarSlot;
import com.ElTorqiro.AegisHUD.Server.AegisServerSlot;

import com.GameInterface.UtilsBase;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.HUD.ItemBarSlot extends BarSlot {

	public function ItemBarSlot() {
		UtilsBase.PrintChatText("item bar slot: constructor");
	}
	
	public function draw() : Void {

		var selectedSlot:AegisServerSlot = AegisServer.getSlot( groupID, AegisServer.getSelectedSlotID(groupID) );
		var selectedTint:Number = Preferences.getValue( "tints.aegis." + selectedSlot.aegisTypeName );
		
		// apply glow of selected aegis
		if ( Preferences.getValue( "ui.item.neon" ) ) {
			m_Icon.filters = [ new GlowFilter( selectedTint, 0.8, 6, 6, 2, 3, false, false ) ];
		}
		else m_Icon.filters = [];

	}
	
	public function refreshItem() : Void {
		
		// if a static icon is set, load that
		if ( staticIcon ) {
			attachMovie( staticIcon, "m_Icon", m_Icon.getDepth() );
			m_Icon._width = m_Icon._height = 24;
		}

		else {
			super.refreshItem();
		}
	}

	/**
	 * internal variables
	 */
	

	/**
	 * properties
	 */

	// static icon to use for slot (typically itemless slots)
	private var _staticIcon:String;
	public function get staticIcon() : String { return _staticIcon; }
	public function set staticIcon( value:String ) : Void {
		_staticIcon = value;
		refreshItem();
	}

}
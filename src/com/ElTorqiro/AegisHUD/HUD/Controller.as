import com.Utils.ID32;
import com.GameInterface.Game.Character;
import com.GameInterface.Inventory;
import com.GameInterface.Tooltip.TooltipInterface;
import com.GameInterface.Tooltip.TooltipManager;
import com.GameInterface.Tooltip.TooltipData;
import com.GameInterface.Tooltip.TooltipDataProvider;

import gfx.core.UIComponent;

import com.GameInterface.UtilsBase;

import com.ElTorqiro.AegisHUD.HUD.Bar;
import com.ElTorqiro.AegisHUD.HUD.BarSlot;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.HUD.Controller extends UIComponent {

	public function Controller() {

		UtilsBase.PrintChatText("controller constructor");
		
		player = Character.GetClientCharacter();
		equipment = new Inventory( new ID32(_global.Enums.InvType.e_Type_GC_WeaponContainer, player.GetID().GetInstance()) );
		backpack = new Inventory( new ID32(_global.Enums.InvType.e_Type_GC_BackpackContainer, player.GetID().GetInstance()) );
		
		aegisGroups = {
			primary: { },
			secondary: { },
			shield: { }
		};
	}
	
	private function configUI() : Void {

		UtilsBase.PrintChatText("controller configUI");
		
		mapSlotFromPosition = { };
		mapSlotFromPosition[ 103 ] = m_PrimaryBar.m_AegisSlot1;
		
		addUI();
	}
	
	private function addUI() : Void {

		m_PrimaryBar = Bar(attachMovie( "bar", "m_PrimaryBar", getNextHighestDepth(), { hud: this, bar: "primary" } ));
		m_SecondaryBar = Bar(attachMovie( "bar", "m_SecondaryBar", getNextHighestDepth(), { hud: this, bar: "secondary" } ));
		m_ShieldBar = Bar(attachMovie( "bar", "m_ShieldBar", getNextHighestDepth(), { hud: this, bar: "shield" } ));

		m_SecondaryBar._y += 100;
		m_ShieldBar._y += 200;
		

		
	}
	
	private function startup() : Void {
		/*
		// only start up if all elements are ready
		if ( !m_PrimaryBar.configured || !m_SecondaryBar.configured || !m_ShieldBar.configured ) return;
		
		m_PrimaryBar.m_AegisSlot1.SetInventoryPosition( equipment, 8 );
		m_PrimaryBar.m_AegisSlot1.selected = true;
		*/
	}
	
	private function slotClickHandler( e:Object ) : Void {
		UtilsBase.PrintChatText("slot click event received by controller");
		
		dispatchEvent( { type: "slotSelect", bar: m_PrimaryBar, slot: m_PrimaryBar.m_AegisSlot1 } );
	}
	
	private function slotMouseOverHandler( e:Object ) : Void {
		UtilsBase.PrintChatText("slot mouseOver received by controller");
	}

	private function slotMouseOutHandler( e:Object ) : Void {
		UtilsBase.PrintChatText("slot mouseOut received by controller");
	}
	
	private function openTooltip( slot:BarSlot ) : Void {
		closeTooltip();
		
		var tooltipData:TooltipData = TooltipDataProvider.GetInventoryItemTooltip( slot.inventory.GetInventoryID(), slot.inventoryPosition );

		if ( tooltipData != undefined ) {
			tooltip = TooltipManager.GetInstance().ShowTooltip( slot, TooltipInterface.e_OrientationVertical, -1, tooltipData );
		}
	}
	
	private function closeTooltip() : Void {
		tooltip.Close();
	}

	
	/**
	 * internal variables
	 */

	private var m_PrimaryBar:Bar;
	private var m_SecondaryBar:Bar;
	private var m_ShieldBar:Bar;

	public var aegisGroups:Object;
	private var mapSlotFromPosition:Object;
	
	private var tooltip:TooltipInterface;
	
	private var player:Character;
	
	private var equipment:Inventory;
	private var backpack:Inventory;
	
	
	/**
	 * properties
	 */
	
	
}
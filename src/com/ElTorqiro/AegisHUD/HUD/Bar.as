import gfx.core.UIComponent;
import flash.filters.GlowFilter;

import com.GameInterface.UtilsBase;

import com.ElTorqiro.AegisHUD.Server.AegisServerSlot;
import com.ElTorqiro.AegisHUD.Server.AegisServerGroup;
import com.ElTorqiro.AegisHUD.Server.AegisServer;
import com.ElTorqiro.AegisHUD.HUD.Slot;
import com.ElTorqiro.AegisHUD.App;
import com.ElTorqiro.AegisHUD.Const;


/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.HUD.Bar extends UIComponent {

	public function Bar() {
		
		App.debug( "HUD: HUD: Bar constructor " + group.id );

		slots = {
			item: attachMovie( "slot", "m_Item", getNextHighestDepth(), { group: group, slot: group.slots["item"] } ),
			aegis1: attachMovie( "slot", "m_Aegis1", getNextHighestDepth(), { group: group, slot: group.slots["aegis1"] } ),
			aegis2: attachMovie( "slot", "m_Aegis2", getNextHighestDepth(), { group: group, slot: group.slots["aegis2"] } ),
			aegis3: attachMovie( "slot", "m_Aegis3", getNextHighestDepth(), { group: group, slot: group.slots["aegis3"] } )
		};
		
		layout();
	}
	
	private function configUI() : Void {

		//UtilsBase.PrintChatText("bar configUI");
	}
	
	/**
	 * lays out internal components, such as background and slots
	 */
	public function layout() : Void {

		var showItem:Number = App.prefs.getVal( "hud.bars." + group.id + ".itemSlotPlacement" );
		
		var firstSlot:Slot = showItem == Const.e_BarItemPlaceFirst ? m_Item : m_Aegis1;
		var lastSlot:Slot = showItem == Const.e_BarItemPlaceLast ? m_Item : m_Aegis3;
		
		m_Item.visible = showItem != Const.e_BarItemPlaceNone;

		if ( showItem == Const.e_BarItemPlaceFirst ) {
			m_Item._x = 3;
			m_Aegis1._x = m_Item._x + m_Item._width + 6;
		}
		
		m_Aegis2._x = m_Aegis1._x + m_Aegis1._width;
		m_Aegis3._x = m_Aegis2._x + m_Aegis2._width;
		
		if ( showItem == Const.e_BarItemPlaceLast ) {
			m_Item._x = m_Aegis3._x + 6;
		}
		
		for ( var s:String in slots ) {
			slots[s]._y = 3;
		}
		
		m_Background._width = lastSlot._x + lastSlot._width + 3;

		var showBackground:Number = App.prefs.getVal( "hud.bar.background.type" );
		
		if ( showBackground == Const.e_BarTypeNone ) {
			m_Background._visible = false;
		}
		
		else {
			switch( showBackground ) {
				case Const.e_BarTypeThin:
					m_Background._y = 12;
					m_Background._height = 6;
				break;

				case Const.e_BarTypeFull:
					m_Background._y = 0;
					m_Background._height = 30;
				break;
			}
			
			m_Background._visible = true;
		}
		
	}
	
	private function draw() : Void {

		var backgroundType:Number = App.prefs.getVal( "hud.bar.background.type" );
		var backgroundAlpha:Number = App.prefs.getVal( "hud.bar.background.transparency" );
		
		if ( backgroundType != Const.e_BarTypeNone && backgroundAlpha > 0 ) {
			
			m_Background._alpha = backgroundAlpha;
			
			var tint:Number = App.prefs.getVal( "hud.tints.aegis." + (group.selectedSlot.item ? group.selectedSlot.aegisTypeName : "empty") );
			
			// neon highlight per selected aegis type
			if ( App.prefs.getVal( "hud.bar.background.neon" ) ) {

				m_Background.gotoAndStop( "black" );
				m_Background.filters =	[ backgroundType == Const.e_BarTypeThin
											? new GlowFilter( tint, 0.8, 7, 5, 2, 3, false, false )
											:  new GlowFilter( tint, 0.8, 8, 8, 1, 3, false, false )
										];
			}
			
			else {
				m_Background.filters = [];
			}
			
			m_Background._visible = true;
		}
		
		else {
			m_Background._visible = false;
		}
		
	}
	
	/**
	 * internal variables
	 */

	public var m_Background:MovieClip;
	public var m_Item:Slot;
	public var m_Aegis1:Slot;
	public var m_Aegis2:Slot;
	public var m_Aegis3:Slot;
	
	/**
	 * properties
	 */

	public var group:AegisServerGroup;
	public var slots:Object;
	 
}
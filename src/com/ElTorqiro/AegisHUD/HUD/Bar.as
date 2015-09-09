import gfx.core.UIComponent;
import flash.filters.GlowFilter;

import com.GameInterface.UtilsBase;

import com.ElTorqiro.AegisHUD.Server.AegisServerSlot;
import com.ElTorqiro.AegisHUD.Server.AegisServerGroup;
import com.ElTorqiro.AegisHUD.Server.AegisServer;
import com.ElTorqiro.AegisHUD.HUD.Slot;
import com.ElTorqiro.AegisHUD.App;
import com.ElTorqiro.AegisHUD.Const;

import com.ElTorqiro.AegisHUD.HUD.HUD;


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

		// listen for pref changes
		App.prefs.SignalValueChanged.Connect( prefChangeHandler, this );
	}
	
	/**
	 * lays out internal components, such as background and slots
	 */
	public function layout() : Void {

		var showItem:Number = App.prefs.getVal( "hud.bars." + group.id + ".itemSlotPlacement" );
		var padding:Number = 3;
		
		var firstSlot:Slot;
		var lastSlot:Slot;
		
		switch ( showItem ) {
			
			case Const.e_BarItemPlaceNone:
				
				m_Item.visible = false;
				m_Item._x = padding;
				m_Aegis1._x = padding;
				
				firstSlot = m_Aegis1;
				lastSlot = m_Aegis3;
				
			break;
			
			case Const.e_BarItemPlaceFirst:
			
				m_Item.visible = true;
				m_Item._x = padding;
				m_Aegis1._x = m_Item._x + m_Item._width + padding * 2;
				
				firstSlot = m_Item;
				lastSlot = m_Aegis3;
			
			break;
			
			case Const.e_BarItemPlaceLast:
			
				m_Item.visible = true;
				m_Item._x = padding + (m_Aegis1._width * 3) + padding * 2;
				m_Aegis1._x = padding;
				
				firstSlot = m_Aegis1;
				lastSlot = m_Item;
			
			break;
			
		}
		
		m_Aegis2._x = m_Aegis1._x + m_Aegis1._width;
		m_Aegis3._x = m_Aegis2._x + m_Aegis2._width;

		for ( var s:String in slots ) {
			slots[s]._y = padding;
		}
		
		m_Background._width = lastSlot._x + lastSlot._width + padding;

		var showBackground:Number = App.prefs.getVal( "hud.bar.background.type" );

		var barHeight:Number = 0;
		
		switch( showBackground ) {
			
			case Const.e_BarTypeNone:
				m_Background._y = 0;
				m_Background._height = 0;
				
				m_Background._visible = false;
			break;
			
			case Const.e_BarTypeThin:
				m_Background._y = 12;
				m_Background._height = 6;
				
				m_Background._visible = true;
			break;

			case Const.e_BarTypeFull:
				m_Background._y = 0;
				m_Background._height = 30;
				
				m_Background._visible = true;
			break;
		}

		invalidate();
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
				m_Background.gotoAndStop( "white" );
				m_Background.filters = [];
			}

			// tint effect
			if ( App.prefs.getVal( "hud.bar.background.tint" ) ) {
				HUD.colorize( m_Background, tint );
			}
			
			else if ( App.prefs.getVal( "hud.bar.background.neon" ) ) {
				HUD.colorize( m_Background, Const.e_TintNone );
			}
			
			else {
				HUD.colorize( m_Background, App.prefs.getVal( "hud.tints.bar.background" ) );
			}

			m_Background._visible = true;
		}
		
		else {
			m_Background._visible = false;
		}
		
	}

	/**
	 * handles updates based on pref changes
	 * 
	 * @param	pref
	 * @param	newValue
	 * @param	oldValue
	 */
	private function prefChangeHandler( pref:String, newValue, oldValue ) : Void {
		
		switch ( pref ) {
			
			case "hud.bar.background.transparency":
			case "hud.bar.background.tint":
			case "hud.bar.background.neon":
			case "hud.slots.item.tint":
			case "hud.slots.item.neon":
			case "hud.slots.aegis.tint":
			case "hud.tints.aegis.psychic":
			case "hud.tints.aegis.cybernetic":
			case "hud.tints.aegis.demonic":
			case "hud.tints.aegis.empty":
			case "hud.tints.bar.background":
				invalidate();
			break;
			
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
import com.Utils.ID32;
import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;
import gfx.core.UIComponent;
import com.Utils.Format;

import flash.filters.GlowFilter;

import com.ElTorqiro.AegisHUD.Server.AegisServer;
import com.ElTorqiro.AegisHUD.Server.AegisServerGroup;
import com.ElTorqiro.AegisHUD.Server.AegisServerSlot;
import com.ElTorqiro.AegisHUD.App;
import com.ElTorqiro.AegisHUD.Const;

import com.GameInterface.Tooltip.TooltipInterface;
import com.GameInterface.Tooltip.TooltipManager;
import com.GameInterface.Tooltip.TooltipDataProvider;
import com.GameInterface.Tooltip.TooltipData;
import com.GameInterface.Game.Character;


/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.HUD.Slot extends UIComponent {

	public function Slot() {

		App.debug( "HUD: HUD: Slot constructor " + group.id + " > " + slot.id );
		
		// kludge for item slot needing different handling, without bothering to extend the class
		if ( slot.id == "item" ) {
			this.draw = this.itemSlotDraw;
			this.onPress = undefined;
			
			m_Background._visible = false;
		}
		
		m_Icon.createEmptyMovieClip( "m_Watermark", 1 );
		
		// setup icon loader
		clipLoader = new MovieClipLoader();
		clipLoader.addListener( this );
		
		// initial load of item icon into slot
		loadIcon();
		loadXP();
	}
	
	private function draw() : Void {
		
		// if slot is selected, highlight it
		if ( slot == group.selectedSlot ) {
			
			var tint:Number = App.prefs.getVal( "hud.tints.aegis." + (slot.item ? slot.aegisTypeName : "empty") );

			// background box
			var backgroundTransparency:Number = App.prefs.getVal( "hud.slots.selectedAegis.background.transparency" );
			
			if ( backgroundTransparency > 0 ) {
				m_Background.filters = App.prefs.getVal( "hud.slots.selectedAegis.background.neon" ) ? [ new GlowFilter( tint, 0.8, 6, 6, 2, 3, false, false ) ] : [];
				m_Background._visible = true;
			}
			
			else {
				m_Background._visible = false;
			}
			
			// neon highlight of icon
			m_Icon.filters = App.prefs.getVal( "hud.slots.selectedAegis.neon" ) ? [ new GlowFilter( tint, 0.8, 6, 6, 2, 3, false, false ) ] : [];
		}
		
		// otherwise clear highlight markers
		else {
			m_Background._visible = false;
			m_Icon.filters = [];
			
		}
		
	}

	private function itemSlotDraw() : Void {
		
		// neon glow item based on selected aegis in group
		if ( group.selectedSlot ) {
			
			var tint:Number = App.prefs.getVal( "hud.tints.aegis." + group.selectedSlot.aegisTypeName );
			m_Icon.filters = [ new GlowFilter( tint, 0.8, 6, 6, 2, 3, false, false ) ];
		}
		
		else {
			m_Icon.filters = [];
		}
		
	}
	
	private function configUI() : Void {
		
		// add right click handling
		this["onPressAux"] = onPress;
	}

	private function onPress( controllerIdx:Number, keyboardOrMouse:Number, button:Number ) : Void {
		dispatchEvent( { type:"click", shift: Key.isDown(Key.SHIFT), ctrl: Key.isDown(Key.CONTROL), button:button } );
		
		var multi:Number = Const.e_SelectSingle;
		
		// shift left click
		if ( button == 0 && Key.isDown(Key.SHIFT) ) {
			multi = App.prefs.getVal( "hud.click.multiSelectType.shiftLeftButton" );
		}
		
		// unmodified left click
		else if ( button == 0 ) {
			multi = App.prefs.getVal( "hud.click.multiSelectType.leftButton" );
		}
		
		// right click
		else if ( button == 1 ) {
			multi = App.prefs.getVal( "hud.click.multiSelectType.rightButton" );
		}
		
		AegisServer.selectSlot( group.id, slot.id, multi );
	}
	
	/**
	 * loads item icon into slot
	 */
	public function loadIcon() : Void {
		
		var item:InventoryItem = slot.item;
		
		if ( item == undefined ) {
			m_Icon.m_Item._visible = false;
			m_Icon.m_Watermark._visible = true;
		}
		
		else {
			m_Icon.m_Watermark._visible = false;
			
			// load icons from icon set according to preference
			if ( item.m_AegisItemType && App.prefs.getVal( "hud.icons.type" ) == Const.e_IconTypeAegisHUD ) {
				m_Icon.attachMovie( slot.group.type + "-" + slot.aegisTypeName, "m_Item", 2 );
				m_Icon.m_Item._width = m_Icon.m_Item._height = 24;
				
				m_Icon.m_Item._visible = true;
			}
			
			else {
				var iconRef:ID32 = item.m_Icon;
				clipLoader.loadClip( Format.Printf( "rdb:%.0f:%.0f", iconRef.GetType(), iconRef.GetInstance() ), m_Icon.createEmptyMovieClip( "m_Item", 2 ) );
			}
			
		}
		
		invalidate();
	}

	/**
	 * sets the xp text from the server slot
	 */
	public function loadXP() : Void {

		if ( slot.xpRaw == undefined ) {
			t_XP._visible = false;
		}
		
		else {
			
			var textFormat:TextFormat = new TextFormat();
			textFormat.color = slot.xpPercent < 100 ? App.prefs.getVal( "hud.tints.xp.notFull" ) : App.prefs.getVal( "hud.tints.xp.full" );
			
			t_XP.setTextFormat( textFormat );
			t_XP.setNewTextFormat( textFormat );
			
			t_XP.text = String( Math.floor(slot.xpPercent) );

			t_XP._visible = true;
		}
		
	}
	
	private function onLoadStart() : Void {
		//UtilsBase.PrintChatText("onloadstart");
	}
	
	private function onLoadInit( target:MovieClip ) : Void {
		// set proper scale of target element
		target._width = target._height = 24;
		target._visible = true;
	}

	private function onLoadError( target:MovieClip, errorCode:String ) : Void {
		//UtilsBase.PrintChatText("onloaderror");
	}
		
	private function onRollOver( mouseIdx:Number ) : Void {
		dispatchEvent( { type:"mouseOver" } );
		
		showTooltip();
	}

	private function onRollOut( mouseIdx:Number ) : Void {
		dispatchEvent( { type:"mouseOut" } );
		
		closeTooltip();
	}

	/**
	 * opens aegis item tooltip
	 * 
	 * @param	slot
	 */
    private function showTooltip() : Void {
		
		closeTooltip();
		
		// don't show anything if no item in slot or tooltip setting is disabled
		if ( !slot.item || !App.prefs.getVal( "hud.tooltips.enabled" ) || ( App.prefs.getVal( "hud.tooltips.suppressInCombat" ) && Character.GetClientCharacter().IsInCombat() ) ) return;

		var tooltipData:TooltipData = TooltipDataProvider.GetInventoryItemTooltip( slot.inventoryID, slot.position );
		
		// add raw xp value
		if ( slot.item.m_AegisItemType ) {
			tooltipData.AddDescription( 'Research Data: <font color="#ffff00">' + slot.xpRaw + '</font>' );
		}
		
		tooltip = TooltipManager.GetInstance().ShowTooltip( this, TooltipInterface.e_OrientationVertical, -1, tooltipData );
		
    }

	/**
	 * close and destroy any open tooltip
	 */
    private function closeTooltip():Void {

		tooltip.Close();
		tooltip = null;
    }

	
	/**
	 * internal variables
	 */
	 
	public var m_Icon:MovieClip;
	public var m_Watermark:MovieClip;
	public var t_XP:TextField;
	public var m_Background:MovieClip;
	
	private var clipLoader:MovieClipLoader;
	
	private var tooltip:TooltipInterface;
	
	/**
	 * properties
	 */

	public var group:AegisServerGroup;
	public var slot:AegisServerSlot;
	 
	// the watermark symbol name for the slot
	private var _watermark:String;
	public function get watermark() : String { return _watermark; }
	public function set watermark( value:String ) : Void {
		_watermark = value;
		
		// apply watermark to slot if present
		if ( value ) {
			m_Icon.m_Watermark.attachMovie( value, "m_Watermark", 1 );
		}
	}
	
}
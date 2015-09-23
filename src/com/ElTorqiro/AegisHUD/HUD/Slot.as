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
import com.ElTorqiro.AegisHUD.AddonUtils.CommonUtils;


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
		
		__width = m_Background._width;
		__height = m_Background._height;
		
		m_Icon.createEmptyMovieClip( "m_Watermark", 1 );
		
		// setup icon loader
		clipLoader = new MovieClipLoader();
		clipLoader.addListener( this );
		
		// initial load of item icon into slot
		loadIcon();
		loadXP();

	}
	
	public function onUnload() : Void {
		closeTooltip();
	}
	
	private function configUI() : Void {
		
		// add right click handling
		this["onPressAux"] = onPress;
		this["onReleaseOutsideAux"] = onReleaseOutside;
		
		// listen for pref changes
		App.prefs.SignalValueChanged.Connect( prefChangeHandler, this );
		
	}

	
	private function draw() : Void {

		var tint:Number = App.prefs.getVal( "hud.tints.aegis." + (slot.item ? slot.aegisTypeName : "empty") );
		
		// if slot is selected, highlight it
		if ( selected ) {
			
			// background box
			var backgroundTransparency:Number = App.prefs.getVal( "hud.slots.selectedAegis.background.transparency" );
			
			if ( backgroundTransparency > 0 ) {

				m_Background.filters = [];
				
				// glow effect
				if ( App.prefs.getVal( "hud.slots.selectedAegis.background.neon" ) ) {
					m_Background.gotoAndStop( "black" );
					m_Background.filters =  [ new GlowFilter( tint, 0.8, 8, 8, 3, 3, false, false ) ]; // [ new GlowFilter( tint, 0.8, 6, 6, 2, 3, false, false ) ];
				}
				
				else {
					m_Background.gotoAndStop( "white" );
				}
				
				// tint effect
				if ( App.prefs.getVal( "hud.slots.selectedAegis.background.tint" ) ) {
					CommonUtils.colorize( m_Background, tint );
				}
				
				else if ( App.prefs.getVal( "hud.slots.selectedAegis.background.neon" ) ) {
					CommonUtils.colorize( m_Background, Const.e_TintNone );
				}
				
				else {
					CommonUtils.colorize( m_Background, App.prefs.getVal( "hud.tints.selectedAegis.background" ) );
				}
				
				// alpha setting
				m_Background._alpha = backgroundTransparency;
			}
			
			m_Background._visible = backgroundTransparency > 0;
			
			// neon highlight of icon
			m_Icon.filters = App.prefs.getVal( "hud.slots.selectedAegis.neon" ) ? [ new GlowFilter( tint, 0.8, 6, 6, 2, 3, false, false ) ] : [];
		}
		
		// otherwise clear highlight markers
		else {
			m_Background._visible = false;
			m_Icon.filters = [];
			
		}
		
		// common visual features
		CommonUtils.colorize( m_Icon.m_Item, App.prefs.getVal( "hud.slots.aegis.tint" ) ? tint : Const.e_TintNone );
		
	}

	private function itemSlotDraw() : Void {
		
		// neon glow item based on selected aegis in group
		if ( group.selectedSlot && group.selectedSlot.item ) {
			
			var tint:Number = App.prefs.getVal( "hud.tints.aegis." + group.selectedSlot.aegisTypeName );
			m_Icon.filters = App.prefs.getVal( "hud.slots.item.neon" ) ? [ new GlowFilter( tint, 0.8, 6, 6, 2, 3, false, false ) ] : [];
			
			CommonUtils.colorize( m_Icon.m_Item, App.prefs.getVal( "hud.slots.item.tint" ) ? tint : Const.e_TintNone );
		}
		
		// otherwise clear highlight markers
		else {
			m_Icon.filters = [];
			CommonUtils.colorize( m_Icon.m_Item, Const.e_TintNone );
		}
		
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
	
	private function onReleaseOutside() : Void {
		closeTooltip();
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

		if ( slot.xpRaw == undefined || !App.prefs.getVal( "hud.slots.aegis.xp.enabled" )
				|| ( slot.xpPercent >= 100 && App.prefs.getVal( "hud.slots.aegis.xp.hideWhenFull" ) )
			) {
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
	 * handles updating slot visuals based on pref changes
	 * 
	 * @param	pref
	 * @param	newValue
	 * @param	oldValue
	 */
	private function prefChangeHandler( pref:String, newValue, oldValue ) : Void {
		
		switch ( pref ) {
			
			case "hud.icons.type":
				loadIcon();
			break;
			
			case "hud.slots.item.tint":
			case "hud.slots.item.neon":
			case "hud.slots.aegis.tint":
			case "hud.tints.aegis.psychic":
			case "hud.tints.aegis.cybernetic":
			case "hud.tints.aegis.demonic":
			case "hud.tints.aegis.empty":
			case "hud.tints.selectedAegis.background":
				invalidate();
			break;
			
			case "hud.slots.selectedAegis.neon":
			case "hud.slots.selectedAegis.background.transparency":
			case "hud.slots.selectedAegis.background.tint":
			case "hud.slots.selectedAegis.background.neon":
				if ( selected ) {
					invalidate();
				}
			break;
				
			case "hud.slots.aegis.xp.enabled":
			case "hud.slots.aegis.xp.hideWhenFull":
			case "hud.tints.xp.notFull":
			case "hud.tints.xp.full":
				loadXP();
			break;
			
		}
		
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
	
	public function get selected() : Boolean { return slot == group.selectedSlot; }
	
}
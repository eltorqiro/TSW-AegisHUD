import com.Utils.Signal;
import flash.geom.Point;
import gfx.core.UIComponent;
import flash.filters.GlowFilter;

import com.Utils.GlobalSignal;

import com.GameInterface.UtilsBase;

import mx.transitions.easing.Strong;
import mx.transitions.easing.Regular;
import mx.transitions.easing.Bounce;

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
		
		//attachMovie( "bar-overlay", "m_Overlay", getNextHighestDepth() );
		m_Overlay._x = m_Overlay._y = -5;
		
		scale = App.prefs.getVal( "hud.scale" );
		
		//layout();
		
		SignalSizeChanged = new Signal();
		
	}
	
	private function configUI() : Void {

		App.debug( "HUD: HUD: Bar configUI start, " + group.id );
		
		layoutIsInvalid = true;
		
		// listen for pref changes
		App.prefs.SignalValueChanged.Connect( prefChangeHandler, this );
		
		GlobalSignal.SignalSetGUIEditMode.Connect( manageOverlay, this );
		
		manageOverlay();

		App.debug( "HUD: HUD: Bar configUI end, " + group.id );
		
	}
	
	/**
	 * lays out internal components, such as background and slots
	 */
	public function layout() : Void {

		var showItem:Number = App.prefs.getVal( "hud.bars." + group.id + ".itemSlotPlacement" );
		var showBackground:Number = App.prefs.getVal( "hud.bar.background.type" );
		
		var padding:Number = 3;
		var itemSlotMargin:Number = 6;
		
		var firstSlot:Slot;
		var lastSlot:Slot;
		
		switch ( showItem ) {
			
			case Const.e_BarItemPlaceNone:
				
				m_Item.visible = false;
				m_Item._x = 0;
				m_Aegis1._x = 0;
				
				firstSlot = m_Aegis1;
				lastSlot = m_Aegis3;
				
			break;
			
			case Const.e_BarItemPlaceFirst:
			
				m_Item.visible = true;
				m_Item._x = 0;
				m_Aegis1._x = m_Item._x + m_Item.width + itemSlotMargin;
				
				firstSlot = m_Item;
				lastSlot = m_Aegis3;
			
			break;
			
			case Const.e_BarItemPlaceLast:
			
				m_Item.visible = true;
				m_Item._x = (m_Aegis1.width * 3) + itemSlotMargin;
				m_Aegis1._x = 0;
				
				firstSlot = m_Aegis1;
				lastSlot = m_Item;
			
			break;
			
		}
		
		m_Aegis2._x = m_Aegis1._x + m_Aegis1.width;
		m_Aegis3._x = m_Aegis2._x + m_Aegis2.width;

		var slotTop:Number = 0;
		var slotLeft:Number = 0;
		
		switch( showBackground ) {
			
			case Const.e_BarTypeNone:
				__width = lastSlot._x + lastSlot.width;
				__height = lastSlot.height;
				
			break;
			
			case Const.e_BarTypeThin:
				slotLeft = padding;
			
				m_Background._height = 6;
				m_Background._y = (m_Aegis1.height - m_Background._height) / 2;
				m_Background._width = lastSlot._x + lastSlot.width + padding * 2;

				__width = m_Background._width;
				__height = lastSlot.height;
				
			break;

			case Const.e_BarTypeFull:
				slotTop = padding;
				slotLeft = padding;
			
				m_Background._y = 0;
				m_Background._height = m_Aegis1.height + padding * 2;
				m_Background._width = lastSlot._x + lastSlot.width + padding * 2;
				
				__width = m_Background._width;
				__height = m_Background._height;

			break;
		}

		for ( var s:String in slots ) {
			slots[s]._y = slotTop;
			slots[s]._x += slotLeft;
		}
		
		m_Overlay._width = __width + 10;
		m_Overlay._height = __height + 10;
		
		m_Background._visible = showBackground != Const.e_BarTypeNone;

		SignalSizeChanged.Emit();
		
		dispatchEvent( { type: "layout" } );
	}
	
	private function draw() : Void {

		if ( layoutIsInvalid ) {
			layout();
		}
		
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

	public function validateNow() : Void {
		super.validateNow();
		
		layoutIsInvalid = false;
	}
	
	/**
	 * moves the bar to a new position, optionally with animation
	 * 
	 * @param	coords
	 */
	public function move( coords:Point, tweenTime:Number ) : Void {

			var overlayCoords:Point = new Point( coords.x - 5, coords.y - 5 );
		
			if ( tweenTime > 0 ) {
				this["tweenTo"]( tweenTime, {
						_x: coords.x,
						_y: coords.y
					},
					Regular.easeOut
				);
				
				overlay.tweenTo( tweenTime, {
						_x: overlayCoords.x,
						_y: overlayCoords.y
					},
					Regular.easeOut
				);
				
			}
			
			else {
				_x = coords.x;
				_y = coords.y;
				
				overlay._x = overlayCoords.x;
				overlay._y = overlayCoords.y;
			}
		
	}
	
	/**
	 * manages the GUI Edit Mode overlay for positioning the bar and scaling the entire hud
	 * 
	 * @param	edit
	 */
	public function manageOverlay( edit:Boolean ) : Void {
	
		if ( ( edit || (edit == undefined && App.guiEditMode) ) && !overlay ) {
		
			overlay = _parent.attachMovie( "GEM-overlay", "overlay-" + _name, _parent.getNextHighestDepth() );

			overlay.bar = this;
			
			overlay.updateSize = function() {
				this._x = this.bar._x - 5;
				this._y = this.bar._y - 5;
				
				this._width = this.bar.width + 10;
				this._height = this.bar.height + 10;
			}

			overlay.bar.SignalSizeChanged.Connect( overlay.updateSize, overlay );
			
			overlay.updateSize();
			
			overlay.onPress = function() {
				
				App.prefs.setVal( "hud.abilityBarIntegration.enable", false );
				
				this.startDrag();
				
				this.onMouseMove = function() {
					this.bar._x = this._x + 5;
					this.bar._y = this._y + 5;
				}
			}
			
			overlay.onRelease = function() {
				this.onMouseMove = undefined;
				this.stopDrag();
			}
			
			overlay.onMouseWheel = function( delta:Number ) {
				App.prefs.setVal( "hud.scale", App.prefs.getVal( "hud.scale" ) + delta * 5 );
			}
			
		}
		
		else {
			overlay.removeMovieClip();
			overlay = null;
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
			
			case "hud.bars.primary.itemSlotPlacement":
			case "hud.bars.secondary.itemSlotPlacement":
			case "hud.bars.shield.itemSlotPlacement":
			case "hud.bar.background.type":
			case "hud.scale":
				
				layoutIsInvalid = true;
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
	
	private var overlay:MovieClip;
	
	public var m_Overlay:MovieClip;
	
	private var layoutIsInvalid:Boolean;
	
	/**
	 * properties
	 */

	public var group:AegisServerGroup;
	public var slots:Object;
	
	public var SignalSizeChanged:Signal;
	
	private var _scale:Number = 100;
	public function get scale() : Number { return _scale; }
	public function set scale( value:Number ) {
		
		if ( _scale == value || Number(value) == Number.NaN ) return;
		
		value = Math.max( value, Const.MinBarScale );
		value = Math.min( value, Const.MaxBarScale );
		
		_xscale = _yscale = _scale = value;
		
		SignalSizeChanged.Emit();
	}
	
	public function get width() : Number { return __width * _xscale / 100; }
	public function get height() : Number { return __height * _yscale / 100; }
	
}
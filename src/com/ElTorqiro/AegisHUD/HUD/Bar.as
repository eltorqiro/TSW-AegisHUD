import com.Utils.Signal;
import flash.geom.Point;
import gfx.core.UIComponent;
import flash.filters.GlowFilter;

import com.Utils.GlobalSignal;

import com.GameInterface.UtilsBase;

import mx.transitions.easing.*;

import com.GameInterface.DistributedValue;

import com.ElTorqiro.AegisHUD.Server.AegisServerSlot;
import com.ElTorqiro.AegisHUD.Server.AegisServerGroup;
import com.ElTorqiro.AegisHUD.Server.AegisServer;
import com.ElTorqiro.AegisHUD.HUD.Slot;
import com.ElTorqiro.AegisHUD.App;
import com.ElTorqiro.AegisHUD.Const;
import com.ElTorqiro.AegisHUD.AddonUtils.CommonUtils;
import com.ElTorqiro.AegisHUD.AddonUtils.MovieClipHelper;


/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.HUD.Bar extends UIComponent {

	public function Bar() {
		
		App.debug( "HUD: HUD: Bar constructor " + group.id );

		slots = {
			item: MovieClipHelper.attachMovieWithClass( "slot", Slot, "m_Item", this, getNextHighestDepth(), { group: group, slot: group.slots["item"] } ),
			aegis1: MovieClipHelper.attachMovieWithClass( "slot", Slot, "m_Aegis1", this, getNextHighestDepth(), { group: group, slot: group.slots["aegis1"] } ),
			aegis2: MovieClipHelper.attachMovieWithClass( "slot", Slot, "m_Aegis2", this, getNextHighestDepth(), { group: group, slot: group.slots["aegis2"] } ),
			aegis3: MovieClipHelper.attachMovieWithClass( "slot", Slot, "m_Aegis3", this, getNextHighestDepth(), { group: group, slot: group.slots["aegis3"] } )
		};
		
		SignalGeometryChanged = new Signal();
		SignalSizeChanged = new Signal();
		
	}
	
	private function configUI() : Void {

		layoutIsInvalid = true;
		
		// listen for resolution changes
		guiResolutionScale = DistributedValue.Create("GUIResolutionScale");
		guiResolutionScale.SignalChanged.Connect( loadScale, this );
		loadScale();
		
		// listen for pref changes
		App.prefs.SignalValueChanged.Connect( prefChangeHandler, this );
		
	}

	/**
	 * loads scale
	 */
	private function loadScale() : Void {
		scale = App.prefs.getVal( "hud.scale" );
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
		
		m_Background._visible = showBackground != Const.e_BarTypeNone;

		SignalGeometryChanged.Emit();
		SignalSizeChanged.Emit();
		
		App.debug( "HUD: " + _name + " bar layout finished" );
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
				CommonUtils.colorize( m_Background, tint );
			}
			
			else if ( App.prefs.getVal( "hud.bar.background.neon" ) ) {
				CommonUtils.colorize( m_Background, Const.e_TintNone );
			}
			
			else {
				CommonUtils.colorize( m_Background, App.prefs.getVal( "hud.tints.bar.background" ) );
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
	 * @param	tweenTime
	 */
	public function move( coords:Point, tweenTime:Number ) : Void {

		if ( tweenTime > 0 ) {
			this["tweenTo"]( tweenTime, {
					_x: coords.x,
					_y: coords.y
				},
				Regular.easeOut
			);
		}
		
		else {
			position = coords;
		}
		
	}
	
	private function onTweenComplete() : Void {
		SignalGeometryChanged.Emit();
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
				
				layoutIsInvalid = true;
				invalidate();

			break;
			
			case "hud.scale":
				loadScale();
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
	
	private var layoutIsInvalid:Boolean;
	
    private var guiResolutionScale:DistributedValue;

	/**
	 * properties
	 */

	public var group:AegisServerGroup;
	public var slots:Object;
	
	public var SignalGeometryChanged:Signal;
	public var SignalSizeChanged:Signal;
	 
	// the position of the hud
	public function get position() : Point { return new Point( this._x, this._y ); }
	public function set position( value:Point ) : Void {
		this._x = value.x;
		this._y = value.y;
		
		SignalGeometryChanged.Emit();
	}

	// the scale of the hud
	public function get scale() : Number { return App.prefs.getVal( "hud.scale" ); }
	public function set scale( value:Number ) : Void {
				
		// the default game GUI scale, based on screen resolution
		var resolutionScale:Number = guiResolutionScale.GetValue();
		if ( resolutionScale == undefined ) resolutionScale = 1;
		
		this._xscale = this._yscale = value; // resolutionScale * value;

		SignalGeometryChanged.Emit();
		SignalSizeChanged.Emit();
	}
	
	public function get width() : Number { return __width * _xscale / 100; }
	public function get height() : Number { return __height * _yscale / 100; }
}
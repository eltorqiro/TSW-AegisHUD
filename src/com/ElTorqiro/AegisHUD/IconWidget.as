import com.Utils.Signal;
import flash.filters.DropShadowFilter;
import flash.geom.Point;

import com.GameInterface.Tooltip.TooltipData;
import com.GameInterface.Tooltip.TooltipManager;
import com.GameInterface.Tooltip.TooltipInterface;

import com.GameInterface.DistributedValue;

import com.Utils.GlobalSignal;

import com.ElTorqiro.AegisHUD.Const;
import com.ElTorqiro.AegisHUD.App;
import com.ElTorqiro.AegisHUD.Server.AegisServer;
import com.ElTorqiro.AegisHUD.Preferences;

import com.GameInterface.UtilsBase;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.IconWidget extends MovieClip {
	
	public function IconWidget() {
		
		App.debug( "IconWidget: " + _name + ": constructor" );

		isVtioIcon = _name == "Icon";
		
		// no point keeping the old icon around if vtio has created a fresh one
		if ( isVtioIcon ) {
			_parent.m_Icon.removeMovieClip();
		}
		
		AegisServer.SignalAegisSystemUnlocked.Connect( refreshState, this );
		refreshState();
		
		// if this is not the duplicate created by VTIO, handle regular setup of icon
		if ( !isVtioIcon ) {
			
			SignalSizeChanged = new Signal();
			
			this.filters = [ new DropShadowFilter( 50, 1, 0, 0.8, 8, 8, 1, 3, false, false, false ) ];
			
			scale = App.prefs.getVal( "widget.scale" );
			loadPosition();

			GlobalSignal.SignalSetGUIEditMode.Connect( manageOverlay, this );
			manageOverlay();
			
		}
		
		// listen for pref changes
		App.prefs.SignalValueChanged.Connect( prefChangeHandler, this );
		
	}
	
	/**
	 * moves icon to loaded position
	 */
	private function loadPosition() : Void {
		
		var pos:Point = App.prefs.getVal( "widget.position" );
		if ( pos == undefined ) {
			pos = new Point( Math.floor((Stage.visibleRect.width - this._width) / 2), Math.floor((Stage.visibleRect.height + this._height) / 4) );
		}
		
		position = pos;
	}
	
	/**
	 * refreshes the current internal state, and changes the icon accordingly
	 */
	public function refreshState() : Void {
		
		App.debug("IconWidget: " + _name + ": refreshState");
		
		var hudEnabled:Boolean = App.prefs.getVal("hud.enabled");
		var autoSwapEnabled:Boolean = App.prefs.getVal("autoSwap.enabled");
		
		if ( hudEnabled && !AegisServer.aegisSystemUnlocked ) {
			state = "locked";
		}
		
		else if ( hudEnabled && autoSwapEnabled ) {
			state = "autoswap";
		}
		
		else if ( hudEnabled ) {
			state = "enabled";
		}
		
		else {
			state = "disabled";
		}
		
		gotoAndStop( state );
	}
	
	public function onMousePress( button:Number ) : Void {
		
		var hudEnabled:Boolean = App.prefs.getVal("hud.enabled");
		var autoSwapEnabled:Boolean = App.prefs.getVal("autoSwap.enabled");
		
		// left button toggles config window
		if ( button == 1 ) {
			
			DistributedValue.SetDValue( Const.ShowConfigWindowDV, !DistributedValue.GetDValue( Const.ShowConfigWindowDV ) );
			closeTooltip();
		}
		
		// shift right-click toggles autoswap
		else if ( button == 2 && Key.isDown(Key.SHIFT) ) {
			
			// if app is enabled and autoswap is enabled, disable just the autoswap
			if ( hudEnabled && autoSwapEnabled ) {
				App.prefs.setVal( "autoSwap.enabled", false );
			}
			
			// if app is enabled, without autoswap
			else if ( hudEnabled ) {
				App.prefs.setVal( "autoSwap.enabled", true );
			}
			
			// if app is disabled, enable it and force autoswap on
			else {
				
				App.prefs.setVal( "autoSwap.enabled", true );
				App.prefs.setVal( "hud.enabled", true );
			}
			
			openTooltip();
		}
		
		// right click toggles enabled/disabled
		else if ( button == 2 ) {
			App.prefs.setVal( "hud.enabled", !App.prefs.getVal( "hud.enabled" ) );
			
			openTooltip();
		}
		
	}
	
	public function onRollOver() : Void {
		openTooltip();
	}
	
	public function onRollOut() : Void {
		closeTooltip();
	}
	
	private function closeTooltip() : Void {
		tooltip.Close();
		tooltip = null;
	}
	
	/**
	 * opens a tooltip on the icon, showing the current status of AegisHUD and some instructions
	 */
	private function openTooltip() : Void {
		
		closeTooltip();
		
		var td:TooltipData = new TooltipData();
		td.AddAttribute( "", "<font face=\'_StandardFont\' size=\'14\' color=\'#00ccff\'><b>" + Const.AppName + " v" + Const.AppVersion + "</b></font>" );
		td.AddAttributeSplitter();
		td.AddAttribute( "", "" );
		
		var stateStr:String = "";
		
		if ( state == "locked" ) {
			stateStr += "<font face=\'_StandardFont\' size=\'11\' color=\'#c8c8c8\'><b>AEGIS System Locked</b></font>";
		}
		
		else {
			stateStr += "<font face=\'_StandardFont\' size=\'11\' color=\'#c8c8c8\'><b>HUD: </b></font>";

			stateStr += App.hudEnabled
				? "<font face=\'_StandardFont\' size=\'11\' color=\'#00ff00\'><b>Enabled</b></font>"
				: "<font face=\'_StandardFont\' size=\'11\' color=\'#ff3333\'><b>Disabled</b></font>"
			;
			
			stateStr += "<font face=\'_StandardFont\' size=\'11\' color=\'#c8c8c8\'><b>&nbsp;&nbsp;&nbsp;&nbsp;AutoSwap: </b></font>";			
			
			stateStr += App.autoSwapEnabled
				? "<font face=\'_StandardFont\' size=\'11\' color=\'#ffff00\'><b>Enabled</b></font>"
				: "<font face=\'_StandardFont\' size=\'11\' color=\'#ff3333\'><b>Disabled</b></font>"
			;
		}
		
		td.AddAttribute( "", stateStr );
		td.AddAttributeSplitter();
		td.AddAttribute( "", "" );
		
		td.AddAttribute("", "<font face=\'_StandardFont\' size=\'11\' color=\'#BFBFBF\'><b>Left Click</b> Open/Close configuration window.\n<b>Right Click</b> Enable/Disable HUD.\n<b>Shift + Right Click</b> Enable/Disable AutoSwap.</font>");
		
		td.m_Padding = 8;
		td.m_MaxWidth = 256;
		
		
		// create tooltip instance
		tooltip = TooltipManager.GetInstance().ShowTooltip( undefined, TooltipInterface.e_OrientationVertical, 0, td );
		
	}

	/**
	 * manages the GUI Edit Mode overlay for positioning the bar and scaling the entire hud
	 * 
	 * @param	edit
	 */
	public function manageOverlay( edit:Boolean ) : Void {
	
		if ( _visible && ( edit || (edit == undefined && App.guiEditMode) ) && !overlay ) {
		
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
				
				this.startDrag();
				
				this.onMouseMove = function() {
					this.bar._x = this._x + 5;
					this.bar._y = this._y + 5;
				}
			}
			
			overlay.onRelease = function() {
				this.onMouseMove = undefined;
				this.stopDrag();
				
				// save position of non-vtio icon
				App.prefs.setVal( "widget.position", new Point( this.bar._x, this.bar._y ) );

			}
			
			overlay.onMouseWheel = function( delta:Number ) {
				App.prefs.setVal( "widget.scale", App.prefs.getVal( "widget.scale" ) + delta * 5 );
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
			
			case "hud.enabled":
			case "autoSwap.enabled":
				refreshState();
			break;

	
			case "widget.scale":
				scale = newValue;
			break;
			
			case "widget.position":
				loadPosition();
			break;
			
		}
		
	}
	
	/*
	 * internal variables
	 */

	private var overlay:MovieClip;
	
	private var tooltip:TooltipInterface;
	private var state:String;

	private var isVtioIcon:Boolean;
	
	/*
	 * properties
	 */

	public var SignalSizeChanged:Signal;
	 
	// the position of the moveable icon
	public function get position() : Point { return new Point( this._x, this._y ); }
	public function set position( value:Point ) : Void {
		
		if ( !isVtioIcon ) {
			this._x = value.x;
			this._y = value.y;
		}
	}

	// the scale of the moveable icon
	public function get scale() : Number { return this._xscale; }
	public function set scale( value:Number ) : Void {
		if ( value != undefined && !isVtioIcon ) {
			this._xscale = this._yscale = value;
			
			SignalSizeChanged.Emit();
		}
	}
	
	public function get height() : Number { return _height; }
	public function get width() : Number { return _width; }
}